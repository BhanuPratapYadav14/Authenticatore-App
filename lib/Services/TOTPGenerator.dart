// totp_generator.dart
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TOTPGenerator {
  static const int _defaultPeriod = 30;
  static const int _defaultDigits = 6;

  /// Generates a TOTP code based on RFC 6238.
  ///
  /// [secretKeyBase32] is the Base32 encoded shared secret.
  /// [currentTimeMs] is the current time in milliseconds since epoch.
  /// [period] is the time step in seconds (default 30).
  /// [digits] is the length of the OTP code (default 6).
  static String generateCode({
    required String secretKeyBase32,
    required int currentTimeMs,
    int period = _defaultPeriod,
    int digits = _defaultDigits,
  }) {
    // 1. Decode the Base32 Secret Key
    // Base32 decoding converts the ASCII string to raw byte array (K)
    final keyBytes = _base32Decode(secretKeyBase32);

    // 2. Calculate Time Counter (C)
    // C = floor((CurrentTime - T0) / Ts)
    final timeStep = (currentTimeMs ~/ 1000) ~/ period;
    final timeBytes = _intToBytes(timeStep);

    // 3. Compute HMAC-SHA1
    final hmacSha1 = Hmac(sha1, keyBytes);
    final hmacResult = hmacSha1.convert(timeBytes).bytes;

    // 4. Dynamic Truncation (HOTP Truncate function)
    final offset =
        hmacResult.last & 0xF; // Last 4 bits define the offset (0-15)

    // Read 4 bytes starting from the offset
    final p = hmacResult.sublist(offset, offset + 4);

    // Convert 4 bytes to a 31-bit integer, masking out the MSB (0x7FFFFFFF)
    final truncatedHash =
        (p[0] & 0x7F) << 24 |
        (p[1] & 0xFF) << 16 |
        (p[2] & 0xFF) << 8 |
        (p[3] & 0xFF);

    // 5. Compute the final code
    final powerOf10 = [1000000, 100000000][digits == 8 ? 1 : 0]; // 10^6 or 10^8
    final code = truncatedHash % powerOf10;

    // 6. Format and zero-pad
    return code.toString().padLeft(digits, '0');
  }

  // --- Utility Functions ---

  /// Converts a standard Base32 encoded string to a byte array.
  static Uint8List _base32Decode(String base32String) {
    // Use the Base32 codec from the `convert` package
    return Uint8List.fromList(_base32Decode(base32String.toUpperCase()));
  }

  /// Converts an integer to an 8-byte (64-bit) big-endian byte array.
  static Uint8List _intToBytes(int value) {
    final buffer = ByteData(8);
    // Write 64-bit integer in Big Endian format
    buffer.setUint64(0, value, Endian.big);
    return buffer.buffer.asUint8List();
  }
}
