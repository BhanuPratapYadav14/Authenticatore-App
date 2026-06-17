// lib/controllers/home_controller.dart
import 'dart:async';
import 'package:circular_menu/circular_menu.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For Colors.primaries
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:zenauth/Controllers/SettingsController.dart';
import 'package:zenauth/Screens/AddAuthAccounts/AddAccountPage.dart';
import 'package:zenauth/Screens/SettingsPage/SettingsPage.dart';
import 'package:zenauth/Services/BiometricService.dart';
import 'package:zenauth/Services/TOTPGenerator.dart';
import '../Models/AuthenticatorAccountModel.dart';
import '../Screens/Homepage/Homepage.dart';
import '../Services/SecureStorageService.dart';
// Assuming you have these services and utilities
// From previous code

class HomeController extends GetxController with WidgetsBindingObserver {
  final BiometricService _biometricService = Get.find<BiometricService>();
  final SettingsController _settingsController = Get.find<SettingsController>();
  final SecureStorageService _storageService = SecureStorageService();
  final GlobalKey<CircularMenuState> menuKey = GlobalKey<CircularMenuState>();
  final Uuid _uuid = const Uuid(); // To generate unique IDs for accounts

  // Observable list of authenticator accounts
  RxList<AuthenticatorAccount> accounts = <AuthenticatorAccount>[].obs;

  // Search controller for the search bar
  final TextEditingController searchController = TextEditingController();
  // Filtered accounts based on search query
  RxList<AuthenticatorAccount> filteredAccounts = <AuthenticatorAccount>[].obs;

  Timer? _timer;

  // --- NEW: Authentication State ---
  final isContentUnlocked = false.obs;
  bool _isAuthenticating = false;
  bool _hasInitialCheckRun = false;
  // ---------------------------------

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkSecurityRequirement().then((_) {
      _hasInitialCheckRun = true;
      // Only start data loading/timers AFTER authentication is resolved.
      if (isContentUnlocked.isTrue) {
        _loadAndStartServices();
      }
    });
    searchController.addListener(_filterAccounts);
  }

  void _loadAndStartServices() {
    _loadAccounts();
    _startOtpGenerationTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  // -----------------------------------------------------------------
  // --- Biometric Authentication & Lifecycle (NEW) ---
  // -----------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final bool required =
        _settingsController.settings.value.isBiometricsEnabled;

    // 1. Lock the screen immediately when the app goes into a background state.
    if (required &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      if (isContentUnlocked.isTrue) {
        isContentUnlocked.value = false; // Force lock the content
        // Cancel timers/stop sensitive services when locking
        _timer?.cancel();
      }
      return;
    }

    // 2. Check for Resume only if the state is 'resumed'
    if (state == AppLifecycleState.resumed) {
      // Ignore 'resumed' events until the initial check is complete.
      if (!_hasInitialCheckRun) {
        return;
      }

      // Trigger re-authentication if biometrics is required AND content is locked.
      if (required && !_isAuthenticating && isContentUnlocked.isFalse) {
        _checkSecurityRequirement(isResume: true);
      }
    }
  }

  Future<void> _checkSecurityRequirement({bool isResume = false}) async {
    if (_isAuthenticating) return;

    final bool required =
        _settingsController.settings.value.isBiometricsEnabled;

    // The content is unlocked, and this is not a resume check, so exit.
    if (isContentUnlocked.isTrue && !isResume) return;

    if (required) {
      _isAuthenticating = true;
      isContentUnlocked.value = false; // Ensure screen is locked before prompt

      final success = await _biometricService.authenticate(
        isResume
            ? 'Confirm your identity to continue using ZenAuth.'
            : 'Confirm your identity to unlock ZenAuth.',
      );

      _isAuthenticating = false;

      if (success) {
        isContentUnlocked.value = true;
        // CRITICAL: Restart services and load data if unlocked on resume/initial check
        if (!_hasInitialCheckRun || isResume) {
          _loadAndStartServices();
        }
      } else {
        // Handle Failure (e.g., stay locked)
        Get.snackbar(
          'Security',
          'Authentication failed. Access denied.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      // Biometrics is not required, automatically unlock.
      isContentUnlocked.value = true;
    }
  }

  // --- Account Management ---

  /// Public hook to reload accounts from secure storage (e.g. after a backup
  /// restore) and refresh the displayed list.
  Future<void> reloadAccounts() async {
    await _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final storedAccounts = await _storageService.getAllAccounts();
    accounts.value = storedAccounts.map((storageAccount) {
      // Re-map from storage model to display model, generate a default color
      final randomColor =
          Colors.primaries[_uuid
                  .v5(Uuid.NAMESPACE_URL, storageAccount.issuer)
                  .hashCode %
              Colors.primaries.length];
      return AuthenticatorAccount(
        id: storageAccount.id,
        issuer: storageAccount.issuer,
        username: storageAccount
            .username, // Using 'label' from stored as username for display
        secret: storageAccount.secret,
        digits: storageAccount.digits,
        period: storageAccount.period,
        color: randomColor,
      );
    }).toList();
    _generateAllOtps(); // Generate initial OTPs after loading
    _filterAccounts(); // Initialize filtered list
  }

  Future<void> addAccount(AuthenticatorAccount newAccount) async {
    // Generate a unique ID if not already present (e.g., from QR),
    // ensuring we don't accidentally use a null ID.
    final id = newAccount.id.isEmpty ? _uuid.v4() : newAccount.id;
    print("The UUID of the :${id}");
    final generatedColor = _generateColor(newAccount.issuer);

    // Use the corrected copyWith to create the immutable account to save.
    // We use the 'id' variable to ensure the account has a proper ID.
    final accountToSave = newAccount.copyWith(Id: id, color: generatedColor);

    // Save the new account to secure storage
    await _storageService.saveAccount(accountToSave);

    // Generate initial OTP and seconds remaining BEFORE adding to the reactive list.
    final initialOtp = TOTPGenerator.generateCode(
      secretKeyBase32: accountToSave.secret,
      currentTimeMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      period: accountToSave.period,
      digits: accountToSave.digits,
    );
    final secondsRemaining = _getSecondsRemaining(accountToSave.period);

    // Create the final version of the account to be added to the UI list.
    final accountForUI = accountToSave.copyWith(
      currentOtp: initialOtp,
      secondsRemaining: secondsRemaining,
    );

    // ⚠️ CRITICAL CHANGE: Add the fully prepared, final copy to the list.
    accounts.add(accountForUI);
    _filterAccounts(); // Update filtered list
    Get.snackbar('Success', 'Account added successfully!');
  }

  void deleteAccount(String accountId) async {
    await _storageService.deleteAccount(accountId);
    accounts.removeWhere((account) => account.id == accountId);
    _filterAccounts(); // Update filtered list
    Get.snackbar('Success', 'Account deleted.');
  }

  // --- OTP Generation & Timer ---

  void _startOtpGenerationTimer() {
    // Ensure the timer is cancelled if it was somehow already running
    _timer?.cancel();

    // 1. Run the update immediately to generate initial codes and set the timer state
    _updateAllAccountsState();

    // 2. Start a timer that runs every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateAllAccountsState();
    });
  }

  // ⚠️ NEW/FIXED: Central function to update all accounts' OTP and timer state
  void _updateAllAccountsState() {
    // List to hold the updated account copies
    final List<AuthenticatorAccount> updatedList = [];
    bool shouldRefresh = false;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (var account in accounts) {
      final secondsRemaining = _getSecondsRemaining(account.period);

      // Create a copy of the account to safely modify
      AuthenticatorAccount tempAccount = account;

      // A. Check for new period: If secondsRemaining == period, a new time window has started.
      // This check is the most reliable way to know when to generate a NEW code.
      if (secondsRemaining == account.period) {
        // 1. Generate the new code
        final newCode = TOTPGenerator.generateCode(
          secretKeyBase32: account.secret,
          currentTimeMs: now,
          period: account.period,
          digits: account.digits,
        );

        // 2. Update the copy with the new code and the reset timer value (e.g., 30s)
        tempAccount = tempAccount.copyWith(
          currentOtp: newCode,
          secondsRemaining: secondsRemaining,
        );
        shouldRefresh = true;
      }
      // B. Only update the seconds remaining for the current time slot
      else {
        // Update the copy only with the new timer value
        tempAccount = tempAccount.copyWith(secondsRemaining: secondsRemaining);
        // The UI needs to rebuild every second for the timer progress
        shouldRefresh = true;
      }

      updatedList.add(tempAccount);
    }

    // 3. CRITICAL FIX: Update the reactive list using assignAll.
    // This explicitly tells GetX/Flutter to replace the list and rebuild the Obx widgets.
    if (shouldRefresh) {
      accounts.assignAll(updatedList);
      // 4. Update the filtered list as well to ensure the displayed list updates.
      _filterAccounts();
    }
  }

  int _getSecondsRemaining(int period) {
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    // This calculates (period - time_in_current_slot). E.g., 30 - (34s % 30) = 26s.
    // When the slot resets, (60s % 30) = 0, so 30 - 0 = 30 (the new countdown start).
    return period - (nowSeconds % period);
  }

  // Keep this: use it to set the initial code and timer when loading
  void _generateAllOtps() {
    _updateAllAccountsState();
  }

  // --- Search Filtering ---
  void _filterAccounts() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredAccounts.value = List.from(accounts); // Show all if no query
    } else {
      filteredAccounts.value = accounts.where((account) {
        return account.issuer.toLowerCase().contains(query) ||
            account.username.toLowerCase().contains(query) ||
            account.currentOtp
                .replaceAll(' ', '')
                .contains(query.replaceAll(' ', '')); // Allow searching OTP
      }).toList();
    }
  }

  // --- UI Helpers ---
  void copyOtpToClipboard(String otp) {
    // Implement clipboard copy logic here
    Get.snackbar('Copied!', 'OTP copied to clipboard.');
    // Future.delayed(const Duration(seconds: 5), () => Clipboard.setData(const ClipboardData(text: ''))); // Clear after some time (might need native code for full reliability)
  }

  void navigateToSettings() {
    Get.to(() => SettingsPage()); // Assuming you have named routes
  }

  void navigateToAddAccount() {
    Get.to(() => AddAccountPage()); // Assuming you have named routes
  }

  void onMenuItemSelected(MenuItem item) {
    // setState(() {
    //   _selectedItem = item.toString().split('.').last.toUpperCase();
    // });
    // The CircularMenu automatically closes after an item is tapped.
    // If it didn't, you would call _menuKey.currentState?.forwardAnimation();
    // or similar to close it.

    // _menuKey.currentState?.forwardAnimation();

    menuKey.currentState!.reverseAnimation();

    switch (item) {
      case MenuItem.home:
        // Already on the home screen, maybe scroll to top?
        Get.snackbar('Menu Action', 'Home selected!');
        break;
      case MenuItem.addAccount:
        // Assuming you have a route defined for adding an account
        navigateToAddAccount();
        break;
      case MenuItem.settings:
        navigateToSettings();
        break;
    }

    // Perform navigation or action based on the selected item
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Selected: $_selectedItem')),
    // );
  }

  Color _generateColor(String uniqueString) {
    // Use the issuer/uniqueString to generate a consistent hash/color index
    return Colors.primaries[_uuid
            .v5(Uuid.NAMESPACE_URL, uniqueString)
            .hashCode
            .abs() %
        Colors.primaries.length];
  }
}
