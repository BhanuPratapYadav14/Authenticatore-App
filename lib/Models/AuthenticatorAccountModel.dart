// lib/models/authenticator_account.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For Color, though often omitted in pure models

class AuthenticatorAccount {
  final String id; // Unique ID for storage
  final String issuer;
  final String username;
  final String secret; // Base32 encoded secret key
  final int digits; // e.g., 6
  final int period; // e.g., 30 seconds
  final Color? color; // Optional: for avatar background color

  // A temporary property to hold the generated OTP code for display
  String currentOtp;
  // A temporary property to hold the remaining time for the current OTP
  int secondsRemaining;

  AuthenticatorAccount({
    required this.id,
    required this.issuer,
    required this.username,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.color, // Default color can be generated based on issuer/username hash
    this.currentOtp = '------', // Initial placeholder
    this.secondsRemaining = 0, // Initial placeholder
  });

  // Factory constructor for creating from JSON (e.g., from secure storage)
  factory AuthenticatorAccount.fromJson(Map<String, dynamic> json) {
    return AuthenticatorAccount(
      id: json['id'] as String,
      issuer: json['issuer'] as String,
      username: json['username'] as String,
      secret: json['secret'] as String,
      digits: json['digits'] as int? ?? 6,
      period: json['period'] as int? ?? 30,
      // Handle color if stored, otherwise generate or default
      color: json['color'] != null ? Color(json['color'] as int) : null,
      currentOtp: json['currentOtp'] as String? ?? '------',
      secondsRemaining: json['secondsRemaining'] as int? ?? 0,
    );
  }

  // Method to convert to JSON (e.g., for secure storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issuer': issuer,
      'username': username,
      'secret': secret,
      'digits': digits,
      'period': period,
      'color': color?.value, // Store color as an int
    };
  }

  // Helper to get the initial for the avatar
  String get initial => issuer.isNotEmpty ? issuer[0].toUpperCase() : 'A';

  // For GetX's RxList updates, we often need to be able to copy/update
  AuthenticatorAccount copyWith({
    String? Id,
    String? currentOtp,
    int? secondsRemaining,
  }) {
    return AuthenticatorAccount(
      id: Id ?? "",
      issuer: issuer,
      username: username,
      secret: secret,
      digits: digits,
      period: period,
      color: color,
      currentOtp: currentOtp ?? this.currentOtp,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}

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
