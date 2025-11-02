// lib/controllers/login_controller.dart

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

import '../Models/login_model.dart';
import '../Services/api_service.dart';

class LoginController extends GetxController {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // You can check for biometric availability on startup
    checkBiometrics();
  }

  // Check if the device has biometrics available
  var canCheckBiometrics = false.obs;
  Future<void> checkBiometrics() async {
    try {
      canCheckBiometrics.value = await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      canCheckBiometrics.value = false;
    }
  }

  // Traditional email/password login
  Future<void> loginWithEmail() async {
    isLoading.value = true;
    try {
      final loginData = LoginModel(
        email: emailController.text,
        password: passwordController.text,
      );
      final user = await _apiService.loginWithCredentials(loginData);
      // Handle successful login (e.g., save token, navigate to home)
      Get.snackbar('Success', 'Welcome, ${user.name}!');
      // Get.offAll(() => const HomeScreen()); // Navigate to home screen
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Login with Google
  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) {
        // The user canceled the sign-in
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final socialToken = googleAuth.idToken; // Or use googleAuth.idToken

      // Send the token to your backend for verification and user creation/login
      final loginData = LoginModel(socialToken: socialToken);
      final user = await _apiService.loginWithCredentials(loginData);

      Get.snackbar('Success', 'Welcome, ${user.name}!');
      // Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google Sign-In failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Login with Face ID or Touch ID
  Future<void> loginWithBiometrics({required String biometricType}) async {
    bool authenticated = false;
    bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();
    bool canAuthenticate = canAuthenticateWithBiometrics || isDeviceSupported;

    print("######### Can we authentic : ${canAuthenticate}");
    if (canAuthenticate) {
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to log in',
          options: const AuthenticationOptions(
            stickyAuth: true,
            // biometricOnly: true,
          ),
        );

        if (authenticated) {
          // If authentication is successful, log the user in.
          // You would typically use a saved token or user ID to authenticate
          // with your backend here, without needing a password.
          // For example:
          // final user = await _apiService.loginWithBiometricToken('savedToken');
          Get.snackbar('Success', 'Authenticated successfully!');
          // Get.offAll(() => const HomeScreen());
        } else {
          Get.snackbar('Authentication Failed', 'Please try again.');
        }
      } catch (e) {
        print('Biometric authentication failed: $e');
        Get.snackbar('Error', 'Biometric authentication failed: $e');
      }
    } else {}
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
