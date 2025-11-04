// lib/controllers/login_controller.dart

import 'package:get/get.dart';
import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../Models/login_model.dart';
import '../Services/api_service.dart';

class LoginController extends GetxController {
  // final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  String? device_id;

  @override
  void onInit() async {
    super.onInit();
    // You can check for biometric availability on startup
    checkBiometrics();
    device_id = await getPlatformDeviceId();
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
        device_id: device_id,
      );
      final user = await loginWithCredentials(loginData);
      // Handle successful login (e.g., save token, navigate to home)
      Get.snackbar('Success', 'Welcome, ${user.username}!');
      // Get.offAll(() => const HomeScreen()); // Navigate to home screen
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> getPlatformDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor!; // iOS-specific ID
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android-specific ID
    }
    return 'Unknown Device ID';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
