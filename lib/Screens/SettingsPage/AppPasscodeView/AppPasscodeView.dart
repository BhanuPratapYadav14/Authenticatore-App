// lib/views/AppPasscodeView.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Controllers/AppPasscodeController.dart';

class AppPasscodeView extends StatelessWidget {
  AppPasscodeView({super.key});

  // Use Get.put if this is the first time, Get.find if verifying (optional)
  final AppPasscodeController controller = Get.put(AppPasscodeController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // In verify (app-unlock) mode the lock must not be dismissable with the
      // system back button. In every other mode normal back navigation is fine.
      final bool isVerifyMode = controller.mode.value == PasscodeMode.verify;
      return PopScope(canPop: !isVerifyMode, child: _buildScaffold(isVerifyMode));
    });
  }

  Widget _buildScaffold(bool isVerifyMode) {
    return Scaffold(
      appBar: AppBar(
        // Only show back button if not in verification mode
        automaticallyImplyLeading: !isVerifyMode,
        title: Obx(() => Text(controller.title.value)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 60,
              color: Get.theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 30),

            // Passcode Display
            _buildPasscodeDisplay(),
            const SizedBox(height: 20),

            // Error Message
            Obx(
              () => Text(
                controller.errorMessage.value,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            const SizedBox(height: 30),

            // Keypad
            _buildKeypad(),

            // Option to use biometrics if available and configured
            if (controller.mode.value == PasscodeMode.verify)
              TextButton(
                onPressed: () {
                  // Trigger biometric re-authentication check
                  // Get.find<HomeController>()._checkSecurityRequirement(
                  //   isResume: true,
                  // );
                },
                child: const Text('Use Biometrics'),
              ),
          ],
        ),
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildPasscodeDisplay() {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(controller.maxLength, (index) {
          bool filled = index < controller.enteredPasscode.value.length;
          final scheme = Get.theme.colorScheme;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: filled ? scheme.onSurface : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outline, width: 1.0),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        _buildKeypadRow(['4', '5', '6']),
        _buildKeypadRow(['7', '8', '9']),
        _buildKeypadRow(['', '0', 'delete']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) => _buildKeypadButton(key)).toList(),
      ),
    );
  }

  Widget _buildKeypadButton(String key) {
    Widget buttonContent;
    VoidCallback? onPressed;

    if (key == 'delete') {
      buttonContent = const Icon(Icons.backspace_outlined);
      onPressed = controller.onDeletePressed;
    } else if (key == '') {
      buttonContent = const SizedBox.shrink();
      onPressed = null;
    } else {
      buttonContent = Text(key, style: const TextStyle(fontSize: 24));
      onPressed = () => controller.onDigitPressed(key);
    }

    return Obx(
      () => IgnorePointer(
        ignoring: controller.isLoading.value,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: key == ''
                ? Colors.transparent
                : Get.theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.onSurface,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
