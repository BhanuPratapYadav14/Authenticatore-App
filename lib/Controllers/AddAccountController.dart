import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenauth/Controllers/HomeController.dart';
import 'package:zenauth/Screens/AddAuthAccounts/ManualSecretEntryPage/ManualSecretEntryPage.dart';
import 'package:zenauth/Screens/AddAuthAccounts/QRCodeScannerPage/QrScannerPage.dart';

import '../Models/AuthenticatorAccountModel.dart';
import '../Models/OtpAccountModel.dart';
import '../Models/PopularServiceModel.dart';

class AddAccountController extends GetxController {
  final HomeController _homeController = Get.find<HomeController>();
  // Static list of popular services (can be fetched from an API in a real app)
  final popularServices = <PopularServiceModel>[
    PopularServiceModel(
      id: '1',
      name: 'Google',
      iconText: 'G',
      route: '/setup/google', // This could be a static instruction page
      color: Colors.red.shade700,
      setupUrl: 'https://support.google.com/accounts/answer/185839',
    ),
    PopularServiceModel(
      id: '2',
      name: 'Microsoft',
      iconText: 'M',
      route: '/setup/microsoft',
      color: Colors.orange.shade700,
      setupUrl:
          'https://support.microsoft.com/en-us/account-billing/how-to-use-microsoft-authenticator-app-9783c865-0308-42fa-a6f4-bf7493c7110e',
    ),
    PopularServiceModel(
      id: '3',
      name: 'AWS',
      iconText: 'A',
      route: '/setup/aws',
      color: Colors.black,
      setupUrl:
          'https://aws.amazon.com/premiumsupport/knowledge-center/mfa-on-root-account/',
    ),
    PopularServiceModel(
      id: '4',
      name: 'Facebook',
      iconText: 'F',
      route: '/setup/facebook',
      color: Colors.blue.shade800,
      setupUrl: 'https://www.facebook.com/help/148233301901353',
    ),
    PopularServiceModel(
      id: '5',
      name: 'GitHub',
      iconText: 'GH',
      route: '/setup/github',
      color: Colors.grey.shade800,
      setupUrl:
          'https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication',
    ),
    PopularServiceModel(
      id: '6',
      name: 'More...',
      iconText: '+',
      route: '/setup/more', // Generic route for more services
      color: Colors.blueGrey,
      setupUrl: '', // No external URL needed for 'More' button
    ),
  ].obs; // .obs makes the list observable

  // --- Methods/Actions ---

  void navigateBack() {
    Get.back(); // GetX navigation to go back
  }

  void scanQrCode() async {
    // Navigate to the scanner page and AWAIT the result
    final result = await Get.to(() => QrScannerPage());

    // Check if a result (the OtpAccountModel) was returned
    if (result != null && result is OtpAccountModel) {
      // 1. Convert the scanned OtpAccountModel to the final AuthenticatorAccount
      final newAccount = AuthenticatorAccount.fromOtpAccountModel(result);

      // 2. Add the final account to the central list and save it
      _homeController.addAccount(newAccount);

      // 3. Close the AddAccount screen (optional, but good UX)
      Get.back();

      // Feedback is already given in QrScannerController, but you can add more here
    } else {
      // If result is null, the scanner was closed without scanning
      Get.snackbar(
        'Action',
        'QR Scanner closed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void enterSetupKey() {
    // Logic to navigate to the manual key entry screen
    Get.to(() => ManualSecretEntryPage()); // Example navigation
    // Get.snackbar('Action', 'Navigating to Manual Setup...');
  }

  void learnAbout2fa() async {
    const helpUrl =
        'https://en.wikipedia.org/wiki/Multi-factor_authentication'; // Placeholder link
    final url = Uri.parse(helpUrl);
    if (await canLaunchUrl(Uri.parse(helpUrl))) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Could not open the help link.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectPopularService(PopularServiceModel service) {
    if (service.setupUrl.isNotEmpty) {
      // Open the setup guide URL externally
      launchUrl(
        Uri.parse(service.setupUrl),
        mode: LaunchMode.externalApplication,
      );
      // Get.snackbar(
      //   'Service Selected',
      //   'Opening ${service.name} setup guide in browser...',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      // NOTE: If you have a specific in-app setup guide, use:
      // Get.toNamed(service.route);
    } else {
      // Fallback for 'More' or if no URL is available
      Get.snackbar(
        'Action',
        'Navigating to ${service.name} setup...',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(service.route);
    }
  }
}
