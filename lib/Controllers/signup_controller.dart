// lib/controllers/signup_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Screens/Loginpage/Loginpage.dart';

// Navigate to login after signup

class SignupController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googlesignin = GoogleSignIn.instance;

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  // Validator to check if the confirm password matches the password
  String? passwordMatchValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    // First, check the original password criteria
    String? passwordCriteriaCheck = validatePassword(value);
    if (passwordCriteriaCheck != null) {
      return passwordCriteriaCheck;
    }

    // Then, check for a match
    if (value != passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> signup() async {
    isLoading.value = true;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Set the display name from the full name field.
      await userCredential.user?.updateDisplayName(
        fullNameController.text.trim(),
      );

      Get.snackbar(
        'Success',
        'Account created successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to the login screen.
      Get.offAll(() => const LoginView());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Sign Up Failed',
        e.message ?? 'Unable to create account.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Unexpected error during sign up: $e");
      Get.snackbar(
        'An unexpected error occurred',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<User?> signInOrSignUpWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googlesignin.authenticate(
        scopeHint: ['email'],
      );

      // 2. Step 3: Get authentication details (now synchronous)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in/Sign up with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on GoogleSignInException catch (e) {
      // Handle cancellation or errors
      if (e.code.name == 'canceled') {
        print('Google Sign-In cancelled by user.');
        return null;
      }
      print('Google Sign-In Error: ${e.code.name} - ${e.description}');
      return null;
    }
    // ... (other error handling) ...
    on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (e.g., account-exists-with-different-credential)
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Handle other errors (e.g., platform-specific errors)
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  @override
  void onInit() async {
    super.onInit();

    await _googlesignin.initialize(
      serverClientId:
          "145173021267-6np4j8e6ossvh8udicauh6761tstmvre.apps.googleusercontent.com",
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
