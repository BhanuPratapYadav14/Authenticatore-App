// lib/Controllers/SettingsController.dart (FINAL FIXES FOR PERSISTENCE)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenauth/Screens/SettingsPage/AppPasscodeView/PasscodeOptionsView.dart';
import 'package:zenauth/Screens/SettingsPage/BackupRestore/BackupRestoreView.dart';
import 'package:zenauth/Screens/SettingsPage/ThemeSelection/ThemeSelectionView.dart';
import 'package:zenauth/util/AppTheme.dart';
import '../Models/SettingsModel.dart';
import '../Services/BiometricService.dart';

class SettingsController extends GetxController {
  // Use Rx<SettingsModel> to make the entire settings object reactive
  final Rx<SettingsModel> settings = SettingsModel().obs;
  static const String _settingsKey = 'user_settings_data';

  // Use late final for dependency injection and find it in onInit
  late final BiometricService _biometricService;

  // NOTE: These mocked fields are now REDUNDANT as this data is in SettingsModel.
  // final RxString userName = 'John Doe'.obs;
  // final RxInt accountsSecured = 5.obs;

  static Future<SettingsController> init() async {
    final controller = SettingsController();

    // CRITICAL: Await the loading of settings before returning the controller
    await controller._loadSettingsFromStorageAsync();

    // Initialize BiometricService safely using the conditional find/put
    if (Get.isRegistered<BiometricService>()) {
      controller._biometricService = Get.find<BiometricService>();
    } else {
      controller._biometricService = Get.put(
        BiometricService(),
        permanent: true,
      );
    }

    return controller;
  }

  Future<void> _loadSettingsFromStorageAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final settingsJson = jsonDecode(jsonString) as Map<String, dynamic>;
        settings.value = SettingsModel.fromJson(settingsJson);
      } else {
        // Initialize with default values if no data is found (First launch)
        settings.value = SettingsModel();
      }
      debugPrint(
        'Settings loaded. Biometrics Enabled: ${settings.value.isBiometricsEnabled}',
      );
    } catch (e) {
      debugPrint('Error loading settings from storage: $e');
      settings.value = SettingsModel();
    }
  }

  @override
  void onInit() {
    // Load settings from storage when the controller initializes
    _loadSettingsFromStorage();
    super.onInit();
  }

  // --- FIX 2: Complete Implementation for Loading Data ---
  void _loadSettingsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final settingsJson = jsonDecode(jsonString) as Map<String, dynamic>;

        // Use the fromJson factory to load the data
        settings.value = SettingsModel.fromJson(settingsJson);
      } else {
        // Initialize with default values if no data is found (FIRST LAUNCH)
        settings.value = SettingsModel();
      }

      debugPrint(
        'Settings loaded. Biometrics Enabled: ${settings.value.isBiometricsEnabled}',
      );
    } catch (e) {
      debugPrint('Error loading settings from storage: $e');
      // Fallback to default settings and notify the user if necessary
      settings.value = SettingsModel();
    }
  }

  // --- Saving Data (Already Correct) ---
  void _saveSettingsToStorage() async {
    // ... (Your correct save implementation remains here) ...
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = settings.value.toJson();
      final jsonString = jsonEncode(settingsJson);
      await prefs.setString(_settingsKey, jsonString);
      debugPrint('Settings saved successfully: $jsonString');
    } catch (e) {
      debugPrint('Error saving settings to storage: $e');
      Get.snackbar(
        'Error',
        'Failed to save settings.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- Action Methods ---

  void toggleBiometrics(bool newValue) async {
    // ... (Your correct biometrics logic remains here) ...
    if (settings.value.isBiometricsEnabled == newValue) return;

    if (newValue) {
      final canAuth = await _biometricService.canAuthenticate();
      if (!canAuth) {
        Get.snackbar(
          'Error',
          'Biometrics unavailable or not set up on this device.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final authenticated = await _biometricService.authenticate(
        'Confirm your identity to enable biometric security.',
      );
      if (!authenticated) {
        Get.snackbar(
          'Security',
          'Authentication failed. Biometrics remains disabled.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    // 2. Update the reactive state and save settings
    settings.update((val) {
      val!.isBiometricsEnabled = newValue;
    });
    // ⚠️ CRITICAL: Call save after state update
    _saveSettingsToStorage();

    Get.snackbar(
      'Security',
      newValue ? 'Biometrics enabled.' : 'Biometrics disabled.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Updates the application's internal state regarding whether a passcode is set
  /// and triggers a save to persistent storage.
  void updatePasscodeSet(bool isSet) {
    // 1. Check if the value is changing to avoid unnecessary updates
    if (settings.value.isPasscodeSet == isSet) return;

    // 2. Update the reactive state
    settings.update((val) {
      val!.isPasscodeSet = isSet;
    });

    // 3. Persist the change
    _saveSettingsToStorage();

    // Optional: Provide UI feedback
    if (isSet) {
      Get.snackbar(
        'Success',
        'Passcode is now active.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Security',
        'Passcode has been disabled.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Replaces the current settings with [model] (e.g. from a restored backup)
  /// and persists them.
  void importSettings(SettingsModel model) {
    settings.value = model;
    _saveSettingsToStorage();
  }

  /// The current theme mode derived from the persisted setting. Used to seed
  /// GetMaterialApp at startup.
  ThemeMode get themeMode => AppThemeOption.fromLabel(
        settings.value.currentTheme,
      ).mode;

  /// Updates the app theme, persists it, and applies it immediately.
  void updateTheme(AppThemeOption option) {
    if (settings.value.currentTheme == option.label) return;

    settings.update((val) {
      val!.currentTheme = option.label;
    });
    _saveSettingsToStorage();

    // Apply the theme live across the whole app.
    Get.changeThemeMode(option.mode);
  }

  void navigateToPasscodeLock() {
    Get.to(() => PasscodeOptionsView());

    // ⚠️ IMPORTANT: After the passcode screen successfully sets/changes the PIN,
    // you must call settings.value.isPasscodeSet = true; and _saveSettingsToStorage()
    // from the Passcode setup controller to update this state.
  }

  // ... (all other navigation methods are unchanged) ...
  void navigateToBackupRestore() => Get.to(() => BackupRestoreView());
  void navigateToTheme() => Get.to(() => ThemeSelectionView());
  void navigateToAbout() => Get.toNamed('/about');
  void navigateToFAQ() => Get.toNamed('/faq');
  void navigateToContactSupport() => Get.toNamed('/contact');
  void navigateBack() => Get.back();
}
