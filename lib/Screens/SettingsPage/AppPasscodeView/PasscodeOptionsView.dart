// lib/views/PasscodeOptionsView.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zenauth/Controllers/AppPasscodeController.dart';
import 'package:zenauth/Controllers/SettingsController.dart'; // Corrected service name
import '../../../Services/SecureStorageService.dart';
import 'AppPasscodeView.dart'; // Import the PIN entry screen

class PasscodeOptionsView extends StatelessWidget {
  PasscodeOptionsView({super.key});

  // Services and Controllers needed
  final SettingsController settingsController = Get.find<SettingsController>();
  final SecureStoragePassCodeService storageService =
      Get.find<SecureStoragePassCodeService>();

  // Key used to store the app passcode
  final String _storageKey = 'app_passcode';

  // --- Logic Methods ---

  // Navigates to the PIN entry screen to set the new PIN
  void _setPasscode() {
    // Navigate to the AppPasscodeView in 'set' mode
    Get.to(() => AppPasscodeView(), arguments: PasscodeMode.set);
  }

  // Navigates to the PIN entry screen to verify the old PIN first
  void _changePasscode() {
    // Navigate to AppPasscodeView in 'verifyForChange' mode
    Get.to(() => AppPasscodeView(), arguments: PasscodeMode.verifyForChange);
  }

  // ⚠️ NEW LOGIC: Handles the toggle button state
  void _handlePasscodeToggle(bool newValue) async {
    // If the user is trying to ENABLE the passcode, navigate to the set screen.
    if (newValue) {
      _setPasscode();
      return; // Handled by setPasscode flow
    }

    // If the user is trying to DISABLE the passcode (newValue is false)
    if (!settingsController.settings.value.isPasscodeSet)
      return; // Should not happen if tile is shown

    // 1. Verify the current PIN before disabling
    final bool? verified = await Get.to<bool?>(
      () => AppPasscodeView(),
      arguments: PasscodeMode.verifyForDisable,
    );

    if (verified == true) {
      // 2. Delete the PIN from secure storage
      await storageService.delete(key: _storageKey);

      // 3. Update the settings state
      settingsController.updatePasscodeSet(false);

      Get.snackbar('Success', 'App Passcode disabled.');
    } else if (verified == false) {
      Get.snackbar(
        'Error',
        'Verification failed. Passcode not disabled.',
        backgroundColor: Colors.red.shade400,
      );
      // NOTE: We don't need to manually update the switch state here.
      // The SwitchListTile rebuilds via Obx, and since settings.isPasscodeSet
      // wasn't changed, the switch will snap back to 'true' (enabled).
    }
    // If verified is null, user canceled, so do nothing.
  }

  // --- UI Builder ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passcode Lock Options')),
      body: Obx(() {
        final isPasscodeSet = settingsController.settings.value.isPasscodeSet;

        return Column(
          children: <Widget>[
            // 1. Passcode Toggle Button
            _buildPasscodeToggle(isPasscodeSet),

            // 2. CHANGE PASSCODE (Only shown if SET)
            if (isPasscodeSet)
              _buildOptionTile(
                icon: Icons.vpn_key_outlined,
                title: 'Change App Passcode',
                subtitle: 'Update your existing application PIN.',
                onTap: _changePasscode,
              ),
          ],
        );
      }),
    );
  }

  // ⚠️ NEW WIDGET: SwitchListTile for Passcode Enable/Disable
  Widget _buildPasscodeToggle(bool isPasscodeSet) {
    return SwitchListTile(
      value: isPasscodeSet,
      onChanged: _handlePasscodeToggle,
      title: const Text('App Passcode Lock'),
      subtitle: Text(
        isPasscodeSet
            ? 'Protected with a 6-digit PIN.'
            : 'Unprotected. Tap to set a PIN.',
      ),
      secondary: Icon(
        isPasscodeSet ? Icons.lock : Icons.lock_open,
        color: Get.theme.primaryColor,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Get.theme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
