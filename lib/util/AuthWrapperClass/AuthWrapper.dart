// lib/widgets/auth_wrapper.dart (FINAL & CORRECTED for Resume Auth)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controllers/SettingsController.dart';
import '../../Services/BiometricService.dart';

class AuthWrapper extends StatefulWidget {
  final Widget Screens;
  const AuthWrapper({super.key, required this.Screens});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final BiometricService _biometricService = Get.find<BiometricService>();
  final SettingsController _settingsController = Get.find<SettingsController>();

  Future<void>? _initialAuthFuture;
  bool _isContentUnlocked = false;
  bool _isAuthenticating = false;
  bool _hasInitialCheckRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // CRITICAL: Call the check and update the run flag upon completion.
    _initialAuthFuture = _checkSecurityRequirement().then((_) {
      if (mounted) {
        setState(() {
          _hasInitialCheckRun = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // -----------------------------------------------------------------
  // --- Lifecycle Method to detect background/foreground changes ---
  // -----------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final bool required =
        _settingsController.settings.value.isBiometricsEnabled;

    // FIX: Lock the screen immediately when the app goes into a background state.
    // This handles both system interruptions (inactive) and user backgrounding (paused).
    if (required &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      if (_isContentUnlocked) {
        _isContentUnlocked = false; // Force lock the content
        // No setState needed here, as the change will be picked up on resume.
        print("Application enter in inactive state , and the background state");
      }
      return;
    }
    if (state == AppLifecycleState.inactive) {
      print("Application enter in inactive state , and the background state");
    }

    // Check for Resume only if the app is coming back to the foreground
    if (state == AppLifecycleState.resumed) {
      // 1. Ignore 'resumed' events until the initial check is complete.
      if (!_hasInitialCheckRun) {
        return;
      }

      // 2. Trigger re-authentication if biometrics is required AND content is locked.
      if (required && !_isAuthenticating && !_isContentUnlocked) {
        _checkSecurityRequirement(isResume: true);
      }
    }
  }

  // -----------------------------------------------------------------
  // --- Core Authentication Logic ---
  // -----------------------------------------------------------------
  Future<void> _checkSecurityRequirement({bool isResume = false}) async {
    if (_isAuthenticating) return;

    final bool required =
        _settingsController.settings.value.isBiometricsEnabled;

    // Exit early if already unlocked AND this is NOT a forced resume check.
    if (_isContentUnlocked && !isResume) return;

    if (required) {
      _isAuthenticating = true;

      if (mounted) {
        // Must show the locked screen state before prompting biometrics
        setState(() {
          _isContentUnlocked = false;
        });
      }

      final success = await _biometricService.authenticate(
        isResume
            ? 'Confirm your identity to continue using ZenAuth.'
            : 'Confirm your identity to unlock ZenAuth.',
      );

      _isAuthenticating = false;

      // Update state and ensure mounted check is done after the await
      if (mounted) {
        if (success) {
          setState(() {
            _isContentUnlocked = true;
          });
        } else {
          // Failure Handling (Access denied, user dismissed)
          Get.snackbar(
            'Security',
            'Authentication failed. Access denied.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } else {
      // Biometrics is not required, automatically unlock.
      if (mounted) {
        setState(() {
          _isContentUnlocked = true;
        });
      }
    }
  }

  // -----------------------------------------------------------------
  // --- Build Method ---
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialAuthFuture,
      builder: (context, snapshot) {
        // 1. Show loading screen while the initial check is running
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLockedScreen(isLoading: true);
        }

        // 2. Show the locked screen if authentication failed or is pending/required
        if (!_isContentUnlocked) {
          // If the app is locked, the spinner is off because the prompt is either visible/failed/dismissed.
          return _buildLockedScreen(isLoading: false);
        }

        // 3. Once unlocked, show the main application content
        return widget.Screens;
      },
    );
  }

  // Helper to build the locked screen widget
  Widget _buildLockedScreen({required bool isLoading}) {
    // ... (Your existing _buildLockedScreen implementation) ...
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Locked by Biometrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator.adaptive()
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
