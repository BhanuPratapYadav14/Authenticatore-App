// lib/Controllers/AppLockController.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zenauth/Controllers/SettingsController.dart';
import 'package:zenauth/Screens/SettingsPage/AppPasscodeView/AppPasscodeView.dart';
import 'package:zenauth/Services/SecureStorageService.dart';

/// Global controller responsible for showing the in-app passcode lock screen.
///
/// It listens to the application lifecycle and shows [AppPasscodeView] in
/// verify mode whenever:
///   * the app is launched for the first time (see [lockOnStartup]), and
///   * the app returns from the background.
///
/// The lock is only shown when the passcode feature is enabled
/// (`SettingsController.settings.isPasscodeSet == true`).
class AppLockController extends GetxController with WidgetsBindingObserver {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final SecureStoragePassCodeService _storageService =
      Get.find<SecureStoragePassCodeService>();

  /// Key under which the passcode is stored in secure storage.
  /// Must match the key used by [AppPasscodeController].
  static const String _passcodeKey = 'app_passcode';

  /// Whether the lock screen is currently on top of the navigation stack.
  /// Prevents pushing multiple lock screens.
  final RxBool isLocked = false.obs;

  bool get _passcodeEnabled =>
      _settingsController.settings.value.isPasscodeSet;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Lock as soon as the app goes to the background. This way the sensitive
    // content is hidden in the OS app switcher and the lock screen is already
    // in place by the time the user brings the app back to the foreground.
    if (state == AppLifecycleState.paused) {
      lock();
    }
  }

  /// Shows the passcode lock screen for the initial app launch.
  void lockOnStartup() => lock();

  /// Shows the passcode lock screen if the feature is enabled and it is not
  /// already visible. Safe to call multiple times.
  Future<void> lock() async {
    if (!_passcodeEnabled) return;
    if (isLocked.value) return;

    // Guard against an inconsistent state where the settings flag says a
    // passcode is enabled but none is actually stored (e.g. secure storage was
    // cleared on reinstall, or setup was interrupted). Without this the lock
    // screen would appear with no PIN that can ever match, permanently locking
    // the user out. Reconcile the flag and skip locking instead.
    final bool hasStoredPasscode =
        await _storageService.containsKey(key: _passcodeKey);
    if (!hasStoredPasscode) {
      _settingsController.updatePasscodeSet(false);
      return;
    }

    // Re-check in case the lock was opened during the await above.
    if (isLocked.value) return;

    isLocked.value = true;
    Get.to(
      () => AppPasscodeView(),
      arguments: 'verify',
      fullscreenDialog: true,
      preventDuplicates: false,
    )?.then((_) {
      // Re-enable future locks once the verify screen is dismissed.
      isLocked.value = false;
    });
  }
}
