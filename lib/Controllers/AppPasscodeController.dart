// lib/controllers/AppPasscodeController.dart

import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:zenauth/Controllers/HomeController.dart';
import 'package:zenauth/Controllers/SettingsController.dart';
import 'package:zenauth/Screens/Homepage/Homepage.dart';
import '../Services/SecureStorageService.dart'; // Using the correct service name

// Add a mode for verification outside of the app-resume flow
enum PasscodeMode {
  set,
  confirm,
  verify,
  change, // Retained for backward compatibility/old nav, but verifyForChange is the new flow starter
  verifyForChange,
  verifyForDisable,
}

class AppPasscodeController extends GetxController {
  final SecureStoragePassCodeService _storageService =
      Get.find<SecureStoragePassCodeService>();
  final HomeController _homeController = Get.find<HomeController>();
  final SettingsController _settingsController = Get.find<SettingsController>();

  // State variables
  final RxString enteredPasscode = ''.obs;
  final RxString title = 'Set a Passcode'.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final Rx<PasscodeMode> mode = PasscodeMode.set.obs;

  // Internal state for PIN setting process
  String _firstPasscode = '';
  final int maxLength = 6;
  final String _storageKey = 'app_passcode'; // Key for secure storage

  @override
  void onInit() {
    super.onInit();
    _checkInitialMode();
  }

  // ⚠️ UPDATED: Handle PasscodeMode enum arguments correctly
  void _checkInitialMode() async {
    final arg = Get.arguments;
    final bool isPasscodeSet = await _isPasscodeSet();

    // Handle explicit navigation via enum (from PasscodeOptionsView)
    if (arg is PasscodeMode) {
      mode.value = arg;
      switch (arg) {
        case PasscodeMode.set:
          title.value = 'Set a Passcode';
          break;
        case PasscodeMode.verifyForChange:
          title.value = 'Enter Current Passcode';
          break;
        case PasscodeMode.verifyForDisable:
          title.value = 'Verify to Disable';
          break;
        default:
          // If navigated to verify or confirm directly (unlikely/error)
          title.value = 'Enter Passcode';
          break;
      }
    }
    // Handle app resume verification (legacy argument 'verify')
    else if (arg == 'verify') {
      mode.value = PasscodeMode.verify;
      title.value = 'Enter Passcode';
    }
    // Fallback for general navigation if a PIN is set (should typically not happen)
    else if (isPasscodeSet) {
      mode.value = PasscodeMode.verify;
      title.value = 'Enter Passcode';
    }
    // Default to initial setup
    else {
      mode.value = PasscodeMode.set;
      title.value = 'Set a Passcode';
    }
  }

  // ⚠️ OPTIMIZED: Use containsKey for efficiency
  Future<bool> _isPasscodeSet() async {
    // We use containsKey instead of reading the whole value
    return await _storageService.containsKey(key: _storageKey);
  }

  // --- Input Handlers (Unchanged) ---
  void onDigitPressed(String digit) {
    if (enteredPasscode.value.length < maxLength) {
      errorMessage.value = '';
      enteredPasscode.value += digit;

      if (enteredPasscode.value.length == maxLength) {
        _handlePasscodeCompletion();
      }
    }
  }

  void onDeletePressed() {
    if (enteredPasscode.value.isNotEmpty) {
      enteredPasscode.value = enteredPasscode.value.substring(
        0,
        enteredPasscode.value.length - 1,
      );
    }
  }

  void _resetInput({String newTitle = ''}) {
    enteredPasscode.value = '';
    if (newTitle.isNotEmpty) {
      title.value = newTitle;
    }
    isLoading.value = false;
  }

  // 🔑 FULLY IMPLEMENTED CORE LOGIC
  void _handlePasscodeCompletion() async {
    isLoading.value = true;

    switch (mode.value) {
      case PasscodeMode.set:
        _firstPasscode = enteredPasscode.value;
        mode.value = PasscodeMode.confirm;
        _resetInput(newTitle: 'Confirm Passcode');
        break;

      case PasscodeMode.confirm:
        if (enteredPasscode.value == _firstPasscode) {
          await _savePasscode(enteredPasscode.value);
          _homeController.isContentUnlocked.value = true;

          Get.snackbar('Success', 'Passcode successfully set!');
          // Update persistent setting state
          _settingsController.updatePasscodeSet(true);
          Future.delayed(Duration(milliseconds: 300), () {
            Get.offAll(() => HomeView());
          });
        } else {
          errorMessage.value = 'Passcodes do not match. Try again.';
          _firstPasscode = '';
          mode.value = PasscodeMode.set;
          _resetInput(newTitle: 'Set a Passcode');
          HapticFeedback.vibrate();
        }
        break;

      case PasscodeMode.verify:
        // Verification on App Resume
        await _verifyPasscode(enteredPasscode.value, unlockApp: true);
        break;

      case PasscodeMode.verifyForChange:
        // 🔑 Flow: Verify old PIN to proceed to set new PIN
        final success = await _verifyPasscode(
          enteredPasscode.value,
          unlockApp: false,
        );
        if (success) {
          // Transition to the 'Set' flow for the new PIN
          mode.value = PasscodeMode.set;
          _firstPasscode = ''; // Clear cache for new PIN entry
          _resetInput(newTitle: 'Enter New Passcode');
        } else {
          errorMessage.value = 'Incorrect Current Passcode. Try again.';
          _resetInput();
          HapticFeedback.vibrate();
        }
        break;

      case PasscodeMode.verifyForDisable:
        // ❌ Flow: Verify PIN to disable it
        final success = await _verifyPasscode(
          enteredPasscode.value,
          unlockApp: false,
        );
        // Return result (true/false) back to PasscodeOptionsView
        Get.back(result: success);
        break;

      case PasscodeMode.change:
        // Handle the legacy/default 'change' mode if passed
        final success = await _verifyPasscode(
          enteredPasscode.value,
          unlockApp: false,
        );
        if (success) {
          mode.value = PasscodeMode.set;
          _firstPasscode = '';
          _resetInput(newTitle: 'Enter New Passcode');
        } else {
          errorMessage.value = 'Incorrect Current Passcode. Try again.';
          _resetInput();
          HapticFeedback.vibrate();
        }
        break;
    }
    isLoading.value = false;
  }

  // ⚠️ IMPLEMENTED: Save PIN securely using SecureStorage
  Future<void> _savePasscode(String passcode) async {
    await _storageService.write(key: _storageKey, value: passcode);
  }

  // ⚠️ UPDATED: Fetch and verify stored PIN, now returns a bool
  Future<bool> _verifyPasscode(
    String enteredPin, {
    required bool unlockApp,
  }) async {
    isLoading.value = true;

    // Fetch stored PIN from secure storage
    final String? storedPin = await _storageService.read(key: _storageKey);
    print("Stored PIN :$storedPin and Entered PIN or PassCode:$enteredPin");
    final passcodeIsSetORNOT = await _isPasscodeSet();
    print(passcodeIsSetORNOT);
    bool success = enteredPin == storedPin && storedPin != null;

    if (success) {
      if (unlockApp) {
        _homeController.isContentUnlocked.value = true;
        // The lock screen is shown as an overlay on top of the current screen,
        // so simply pop it to reveal the content the user was on. This keeps
        // the navigation stack intact on resume-from-background.
        //
        // We pop via the root navigator instead of Get.back(): Get.back()
        // eagerly closes the current snackbar, which can throw a
        // LateInitializationError inside GetX's SnackbarController. We also
        // skip a success snackbar here to keep this path snackbar-free.
        Get.key.currentState?.pop();
      }
    } else if (unlockApp) {
      // Only show error and vibrate if this is the main app unlock screen
      errorMessage.value = 'Invalid Passcode. Try again.';
      _resetInput();
      HapticFeedback.vibrate();
    }

    isLoading.value = false;
    return success;
  }
}
