// lib/services/biometric_service.dart

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';

class BiometricService extends GetxService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Check if the device supports biometrics and if any are enrolled
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  // Perform the actual authentication
  Future<bool> authenticate(String reason) async {
    final bool canAuth = await canAuthenticate();
    if (!canAuth) {
      Get.snackbar(
        'Security',
        'Biometrics not available or configured on this device.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Allow authentication with device passcode/pin as a fallback
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('Authentication error: $e');
      // Handle specific error codes if necessary (e.g., permanent lockout)
      return false;
    }
  }
}
