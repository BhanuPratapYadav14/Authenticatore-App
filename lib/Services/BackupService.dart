// lib/Services/BackupService.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenauth/Controllers/SettingsController.dart';

import '../Models/AuthenticatorAccountModel.dart';
import '../Models/SettingsModel.dart';
import 'SecureStorageService.dart';

/// Thrown when a backup file cannot be restored (wrong password, corrupted or
/// unrecognised file).
class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

/// Handles creating and restoring password-protected backups of the
/// authenticator accounts.
///
/// Backup file format (UTF-8 JSON envelope):
/// ```json
/// {
///   "app": "zenauth",
///   "format": 1,
///   "kdf": "pbkdf2-hmac-sha256",
///   "iterations": 120000,
///   "salt": "<base64>",
///   "iv": "<base64>",
///   "cipher": "aes-256-cbc",
///   "data": "<base64 ciphertext>"
/// }
/// ```
/// The ciphertext decrypts to `{"accounts": [ <account.toJson()>, ... ]}`.
class BackupService {
  final SecureStorageService _storageService = SecureStorageService();
  final SecureStoragePassCodeService _passcodeStorage =
      Get.find<SecureStoragePassCodeService>();

  /// Must match the key used by AppPasscodeController / AppLockController.
  static const String _passcodeKey = 'app_passcode';

  static const String _appTag = 'zenauth';
  static const int _formatVersion = 1;
  static const int _pbkdf2Iterations = 120000;
  static const int _saltLength = 16; // bytes
  static const int _keyLength = 32; // bytes -> AES-256

  /// Creates an encrypted backup of all accounts and writes it to a temporary
  /// file. Returns the [File] so the caller can share it. Throws
  /// [BackupException] if there are no accounts to back up.
  Future<File> createBackupFile(String password) async {
    final List<AuthenticatorAccount> accounts =
        await _storageService.getAllAccounts();

    if (accounts.isEmpty) {
      throw BackupException('There are no accounts to back up.');
    }

    // Include the app passcode and settings so a restore brings back the
    // user's full security configuration, not just the accounts.
    final String? passcode = await _passcodeStorage.read(key: _passcodeKey);
    final Map<String, dynamic>? settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>().settings.value.toJson()
        : null;

    final plaintext = jsonEncode({
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'passcode': passcode,
      'settings': settings,
    });

    final envelope = _encrypt(plaintext, password);

    final dir = await getTemporaryDirectory();
    final fileName = 'zenauth_backup_${accounts.length}_accounts.zenauth';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonEncode(envelope), flush: true);
    return file;
  }

  /// Restores accounts from an encrypted backup file's [bytes]. Existing
  /// accounts with the same id are overwritten; others are kept. Returns the
  /// number of accounts imported. Throws [BackupException] on any failure.
  Future<int> restoreFromBytes(Uint8List bytes, String password) async {
    late final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('This is not a valid ZenAuth backup file.');
    }

    if (envelope['app'] != _appTag) {
      throw BackupException('This is not a valid ZenAuth backup file.');
    }

    final String plaintext = _decrypt(envelope, password);

    late final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (_) {
      // Decryption produced garbage -> almost always a wrong password.
      throw BackupException('Incorrect password or corrupted backup.');
    }

    final accountsJson = (payload['accounts'] as List?) ?? const [];
    int imported = 0;
    for (final item in accountsJson) {
      try {
        final account =
            AuthenticatorAccount.fromJson(item as Map<String, dynamic>);
        await _storageService.saveAccount(account);
        imported++;
      } catch (_) {
        // Skip individual malformed entries rather than failing the whole
        // restore.
      }
    }

    if (accountsJson.isNotEmpty && imported == 0) {
      throw BackupException('No accounts could be restored from this backup.');
    }

    // Restore the app passcode, if the backup contains one.
    final passcode = payload['passcode'] as String?;
    if (passcode != null && passcode.isNotEmpty) {
      await _passcodeStorage.write(key: _passcodeKey, value: passcode);
    }

    // Restore settings (biometrics flag, passcode flag, theme, etc.).
    final settingsJson = payload['settings'] as Map<String, dynamic>?;
    if (settingsJson != null && Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>()
          .importSettings(SettingsModel.fromJson(settingsJson));
    }

    return imported;
  }

  // --- Encryption helpers ---

  Map<String, dynamic> _encrypt(String plaintext, String password) {
    final salt = _randomBytes(_saltLength);
    final key = _deriveKey(password, salt);
    final iv = enc.IV(_randomBytes(16));
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'app': _appTag,
      'format': _formatVersion,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': _pbkdf2Iterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv.bytes),
      'cipher': 'aes-256-cbc',
      'data': encrypted.base64,
    };
  }

  String _decrypt(Map<String, dynamic> envelope, String password) {
    try {
      final salt = base64Decode(envelope['salt'] as String);
      final iv = enc.IV(base64Decode(envelope['iv'] as String));
      final iterations = (envelope['iterations'] as num?)?.toInt() ?? _pbkdf2Iterations;
      final key = _deriveKey(password, salt, iterations: iterations);
      final encrypter =
          enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
      return encrypter.decrypt64(envelope['data'] as String, iv: iv);
    } catch (_) {
      // A wrong password typically fails PKCS7 unpadding here.
      throw BackupException('Incorrect password or corrupted backup.');
    }
  }

  /// PBKDF2-HMAC-SHA256 key derivation (the `crypto` package does not ship a
  /// PBKDF2 implementation, so it is implemented here on top of [Hmac]).
  Uint8List _deriveKey(
    String password,
    List<int> salt, {
    int iterations = _pbkdf2Iterations,
  }) {
    final hmac = Hmac(sha256, utf8.encode(password));
    const hLen = 32; // SHA-256 output length
    final numBlocks = (_keyLength / hLen).ceil();
    final derived = <int>[];

    for (int block = 1; block <= numBlocks; block++) {
      // INT_32_BE(block)
      final blockIndex = <int>[
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = List<int>.from(u);
      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      derived.addAll(t);
    }

    return Uint8List.fromList(derived.sublist(0, _keyLength));
  }

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}
