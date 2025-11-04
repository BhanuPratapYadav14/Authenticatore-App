// lib/controllers/home_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For Colors.primaries
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:zenauth/Services/TOTPGenerator.dart';
import '../Models/AuthenticatorAccountModel.dart';
// Assuming you have these services and utilities
// From previous code

class HomeController extends GetxController {
  final SecureStorageService _storageService = SecureStorageService();
  final Uuid _uuid = const Uuid(); // To generate unique IDs for accounts

  // Observable list of authenticator accounts
  RxList<AuthenticatorAccount> accounts = <AuthenticatorAccount>[].obs;

  // Search controller for the search bar
  final TextEditingController searchController = TextEditingController();
  // Filtered accounts based on search query
  RxList<AuthenticatorAccount> filteredAccounts = <AuthenticatorAccount>[].obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _loadAccounts();
    searchController.addListener(_filterAccounts);
    _startOtpGenerationTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  // --- Account Management ---

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
    // Generate a unique ID if not already present (e.g., from QR)
    final id = newAccount.id.isEmpty ? _uuid.v4() : newAccount.id;
    final accountToSave = newAccount.copyWith(Id: id);

    // Save the new account to secure storage
    await _storageService.saveAccount(accountToSave);

    // Add to the observable list and generate its initial OTP
    accountToSave.currentOtp = TOTPGenerator.generateCode(
      secretKeyBase32: accountToSave.secret,
      currentTimeMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      period: accountToSave.period,
      digits: accountToSave.digits,
    );
    accountToSave.secondsRemaining = _getSecondsRemaining(accountToSave.period);
    accounts.add(accountToSave);
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final currentSecond =
          (now ~/ 1000) % 30; // Assuming 30s period for simplicity

      for (var i = 0; i < accounts.length; i++) {
        final account = accounts[i];
        final secondsRemaining = _getSecondsRemaining(account.period);

        // Update seconds remaining for all accounts
        accounts[i] = account.copyWith(secondsRemaining: secondsRemaining);

        // If it's the start of a new period (or close to it, within 1 second grace)
        if (secondsRemaining == account.period || secondsRemaining == 0) {
          _generateOtpForAccount(account);
        }
      }
      accounts.refresh(); // Force GetX to re-render the list if needed
    });
  }

  void _generateAllOtps() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    accounts.value = accounts.map((account) {
      final code = TOTPGenerator.generateCode(
        secretKeyBase32: account.secret,
        currentTimeMs: now,
        period: account.period,
        digits: account.digits,
      );
      final seconds = _getSecondsRemaining(account.period);
      return account.copyWith(currentOtp: code, secondsRemaining: seconds);
    }).toList();
    accounts.refresh();
  }

  void _generateOtpForAccount(AuthenticatorAccount account) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final newCode = TOTPGenerator.generateCode(
      secretKeyBase32: account.secret,
      currentTimeMs: now,
      period: account.period,
      digits: account.digits,
    );
    final seconds = _getSecondsRemaining(account.period);

    final index = accounts.indexWhere((element) => element.id == account.id);
    if (index != -1) {
      accounts[index] = account.copyWith(
        currentOtp: newCode,
        secondsRemaining: seconds,
      );
    }
  }

  int _getSecondsRemaining(int period) {
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return period - (nowSeconds % period);
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
    Get.toNamed('/settings'); // Assuming you have named routes
  }

  void navigateToAddAccount() {
    Get.toNamed('/add_account'); // Assuming you have named routes
  }
}
