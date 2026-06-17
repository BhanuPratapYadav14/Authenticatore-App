// lib/controllers/login_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:zenauth/Screens/Homepage/Homepage.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  // Traditional email/password login (Firebase)
  Future<void> loginWithEmail() async {
    isLoading.value = true;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      Get.snackbar(
        'Success',
        'Welcome, ${userCredential.user?.email ?? ''}!',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => HomeView()); // Navigate to home screen
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message ?? 'Failed to log in.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
