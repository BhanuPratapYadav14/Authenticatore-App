// lib/controllers/signup_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:zenauth/services/api_service.dart';

import '../Models/signup_model.dart';
import '../Screens/Loginpage/Loginpage.dart';

// Navigate to login after signup

class SignupController extends GetxController {
  final ApiService _apiService = Get.put(ApiService());

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

  Future<void> signup() async {
    isLoading.value = true;
    try {
      final request = SignupRequestModel(
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
      );
      final response = await _apiService.signupWithEmail(request);
      Get.snackbar('Success', response.message);
      // Navigate to the login screen after successful signup.
      Get.offAll(() => const LoginView());
    } catch (e) {
      Get.snackbar('Error', e.toString());
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

  Future<User?> signUpWithEmailAndPassword({
    required String Email,
    required String Password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: Email, password: Password);
      return userCredential.user;
    } on FirebaseException catch (e) {
      return null;
    } catch (e) {
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
    super.onClose();
  }
}
