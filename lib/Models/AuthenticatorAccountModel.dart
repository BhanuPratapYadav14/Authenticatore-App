// lib/models/authenticator_account.dart
import 'package:flutter/material.dart';
import 'package:zenauth/Models/OtpAccountModel.dart'; // For Color, though often omitted in pure models

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

  factory AuthenticatorAccount.fromOtpAccountModel(OtpAccountModel otpModel) {
    return AuthenticatorAccount(
      id: otpModel.id,
      // Issuer and Account Name might need sanitation/decoding which is often done in the OtpAccountModel
      issuer: otpModel.issuer,
      username: otpModel
          .accountName, // Map OtpAccountModel's accountName to AuthenticatorAccount's username
      secret: otpModel.secret,
      digits: otpModel.digits,
      period: otpModel.period,
      // You can implement a simple color hash based on the issuer or username here
      color: Color(otpModel.issuer.hashCode % 0xFFFFFF).withOpacity(1.0),
      currentOtp: '------',
      secondsRemaining: 0,
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
    String? Id, // Parameter is capitalized 'Id'
    String? currentOtp,
    int? secondsRemaining,
    Color?
    color, // ⚠️ FIX: Added Color? color to allow updating/passing existing color
  }) {
    return AuthenticatorAccount(
      // ⚠️ CRITICAL FIX: Use the existing ID (this.id) if the new Id is null.
      id: Id ?? this.id,
      issuer: issuer,
      username: username,
      secret: secret,
      digits: digits,
      period: period,
      // ⚠️ FIX: Ensure color is preserved or updated
      color: color ?? this.color,
      currentOtp: currentOtp ?? this.currentOtp,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}
