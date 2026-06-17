import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';

import '../Models/AuthenticatorAccountModel.dart';

class SecureStorageService {
  // Use a singleton instance of FlutterSecureStorage
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage key prefix to organize TOTP entries
  static const String _keyPrefix = 'totp_account_';

  /// Saves a new TOTP account securely.
  Future<void> saveAccount(AuthenticatorAccount account) async {
    final key = '$_keyPrefix${account.id}';
    // Store the JSON string. The secret is securely managed by the platform.
    await _storage.write(key: key, value: jsonEncode(account.toJson()));
  }

  /// Retrieves all TOTP accounts from secure storage.
  Future<List<AuthenticatorAccount>> getAllAccounts() async {
    final allEntries = await _storage.readAll();
    final List<AuthenticatorAccount> accounts = [];

    allEntries.forEach((key, value) {
      if (key.startsWith(_keyPrefix)) {
        try {
          // The key holds the ID, but we rely on the ID inside the JSON for model creation.
          // final id = key.substring(_keyPrefix.length); // Not strictly needed here
          final json = jsonDecode(value) as Map<String, dynamic>;
          accounts.add(AuthenticatorAccount.fromJson(json));
        } catch (e) {
          // Log error for corrupted or unparseable entry
          print('Error loading account for key $key: $e');
        }
      }
    });

    return accounts;
  }

  // --- NEW FUNCTIONALITY ADDED HERE ---
  /// Deletes a specific TOTP account from secure storage using its ID.
  Future<void> deleteAccount(String accountId) async {
    final key = '$_keyPrefix$accountId';
    // Use the delete method from flutter_secure_storage
    await _storage.delete(key: key);
  }

  // ------------------------------------
}

class SecureStoragePassCodeService extends GetxService {
  // Use EncryptedSharedPreferences on Android. The default keystore-backed
  // implementation silently fails to persist values on a number of devices
  // (notably Samsung/OneUI), which causes reads to return null right after a
  // successful-looking write. Requires minSdkVersion >= 23.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- Passcode Specific Methods ---

  // Writes a string value securely. Used for setting/changing the passcode.
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('Secure Storage Write Error for $key: $e');
      // In a production app, you might want to log this error or notify the user
    }
  }

  // Reads a string value securely. Used for verifying the passcode.
  Future<String?> read({required String key}) async {
    try {
      final storeCode = await _storage.read(key: key);
      print(storeCode);
      return storeCode;
    } catch (e) {
      print('Secure Storage Read Error for $key: $e');
      return null;
    }
  }

  // Deletes a specific key-value pair. Used for removing the passcode.
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('Secure Storage Delete Error for $key: $e');
    }
  }

  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      print('Secure Storage containsKey Error for $key: $e');
      return false;
    }
  }

  // Deletes all entries. Useful for full account reset/logout.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('Secure Storage Delete All Error: $e');
    }
  }
}
