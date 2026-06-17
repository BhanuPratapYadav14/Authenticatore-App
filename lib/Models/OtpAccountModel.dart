// lib/models/otp_account_model.dart
import 'package:flutter/foundation.dart';

class OtpAccountModel {
  final String id;
  final String secret; // The TOTP secret key
  final String issuer; // Service name (e.g., Google, GitHub)
  final String accountName; // Username/email
  final int digits; // 6 or 8
  final int period; // 30 seconds

  OtpAccountModel({
    required this.id,
    required this.secret,
    required this.issuer,
    required this.accountName,
    this.digits = 6,
    this.period = 30,
  });

  // Example: otpauth://totp/Example:user@domain.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&digits=6&period=30
  factory OtpAccountModel.fromUri(String uri) {
    if (!uri.startsWith('otpauth://')) {
      throw const FormatException('Invalid OTP URI format');
    }

    final Uri otpUri = Uri.parse(uri);

    // --- 1. Get raw components ---
    String rawPath = otpUri.pathSegments.last;

    // Default values if parameters are missing
    String finalIssuer =
        otpUri.queryParameters['issuer'] ??
        'Generic Service'; // <-- Better default
    String finalAccountName;

    // --- 2. Handle Path (Label) ---
    String decodedPath = Uri.decodeComponent(rawPath).trim();

    if (decodedPath.contains(':')) {
      // Standard format: Issuer:AccountName (e.g., Google:user@email.com)
      final parts = decodedPath.split(':');
      finalIssuer = parts.first.trim();
      finalAccountName = parts.last.trim();
    } else {
      // Non-standard format (like your test site): just AccountName
      finalAccountName = decodedPath;

      // If we have an Issuer in the query, we keep it.
      // If not, we use the 'Generic Service' default above.
    }

    // Final check for a usable name
    if (finalAccountName.isEmpty) {
      finalAccountName = 'Unknown User';
    }

    // --- 3. Construct the model ---
    return OtpAccountModel(
      id: UniqueKey().toString(),
      secret: otpUri.queryParameters['secret'] ?? '',
      issuer: finalIssuer,
      accountName: finalAccountName,
      digits: int.tryParse(otpUri.queryParameters['digits'] ?? '6') ?? 6,
      period: int.tryParse(otpUri.queryParameters['period'] ?? '30') ?? 30,
    );
  }

  // Debugging output
  @override
  String toString() {
    return 'Issuer: $issuer, Account: $accountName, Secret: $secret, Digits: $digits';
  }
}
