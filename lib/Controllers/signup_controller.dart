// lib/controllers/signup_controller.dart

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Models/signup_model.dart';
import '../Screens/Loginpage/Loginpage.dart';
import '../Services/api_service.dart';
import '../util/helperClasses/HiveHelper.dart';

// Navigate to login after signup

class SignupController extends GetxController {
  // final ApiService _apiService = Get.put(ApiService());

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googlesignin = GoogleSignIn.instance;
  late final HiveHelper _hiveHelper;
  String? device_id;

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
    // The Signup Controller logic (assuming this is within your SignupController)

    try {
      // 1. Send the Request
      final request = SignupRequestModel(
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
        device_ID: device_id ?? "",
      );

      // Await the HTTP response
      final response = await signupWithEmail(request);

      print("Response Received by server (Status: ${response.statusCode})");

      // 2. Check for a successful HTTP status code (e.g., 200, 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Attempt to decode the JSON body safely
        final decodedBody = jsonDecode(response.body.toString());

        print("Decoded JSON Body: $decodedBody");

        // 3. Parse the JSON into the Model
        final jsonResponse = SignUpResponseModel.fromJson(decodedBody);

        // 4. Check the application-level status from the model
        if (jsonResponse.message.toLowerCase().contains("success")) {
          // Use message/status from the model

          Get.snackbar(
            'Success',
            jsonResponse.message,
            snackPosition: SnackPosition.BOTTOM,
          );

          // Save the access token
          _hiveHelper.saveString("AccessToken", jsonResponse.accessToken);

          // Navigate to the next screen (e.g., Home or Login)
          Get.offAll(() => const LoginView());
        } else {
          // Handle server-side validation errors (e.g., email already taken)
          Get.snackbar(
            "Sign Up Failed",
            jsonResponse.message,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        // Handle non-200 HTTP status codes (e.g., 400 Bad Request, 500 Server Error)
        // Try to decode the body to show a specific error if the server sends one
        try {
          final errorBody = jsonDecode(response.body.toString());
          Get.snackbar(
            "Server Error (${response.statusCode})",
            errorBody['message'] ?? 'Unknown error occurred.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (_) {
          // If the body isn't JSON (e.g., raw 500 error page)
          Get.snackbar(
            "Server Error",
            "Failed with status code ${response.statusCode}. Please try again later.",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } on SocketException {
      Get.snackbar(
        "Internet Connection",
        "Failed to connect with server. Please check your internet connection.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Catch any remaining errors, primarily JSON decoding/model parsing errors
      print("CRITICAL ERROR DURING DECODING OR MODEL PARSING: $e");
      Get.snackbar(
        'An unexpected Error occurred',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      print("Executing Finally block");
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
    } on FirebaseException {
      return null;
    } catch (e) {
      return null;
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
  void onInit() async {
    super.onInit();
    _hiveHelper = await HiveHelper.init();
    device_id = await getPlatformDeviceId();

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
