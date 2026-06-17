// lib/views/add_account_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/AddAccountController.dart';
import '../../Models/PopularServiceModel.dart';

class AddAccountPage extends GetView<AddAccountController> {
  const AddAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller if it hasn't been put yet
    Get.put(AddAccountController());

    return Scaffold(
      appBar: AppBar(
        // The back arrow is automatically handled by Flutter if this screen
        // is pushed onto the navigation stack. We define the title here.
        title: const Text('Add Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.navigateBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Scan QR Code Card ---
            _buildSetupCard(
              icon: Icons.qr_code_2_rounded,
              title: 'Scan QR Code',
              subtitle:
                  'Use your camera to scan a QR code from your service provider',
              onTap: controller.scanQrCode,
            ),
            const SizedBox(height: 16),

            // --- 2. Enter Setup Key Card ---
            _buildSetupCard(
              icon: Icons.keyboard,
              title: 'Enter Setup Key',
              subtitle:
                  'Manually enter the secret key provided by your service',
              onTap: controller.enterSetupKey,
            ),
            const SizedBox(height: 24),

            // --- 3. Need Help Section ---
            _buildHelpSection(context),
            const SizedBox(height: 32),

            // --- 4. Popular Services Grid ---
            const Text(
              'Popular Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPopularServicesGrid(),
          ],
        ),
      ),
    );
  }

  // Helper Widget for the main setup cards
  Widget _buildSetupCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 28, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for the help section
  Widget _buildHelpSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(Icons.help_outline, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need Help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Most services provide a QR code when setting up two-factor authentication. Look for "Authenticator app" or "TOTP" options in your account security settings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: controller.learnAbout2fa,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: const Text(
                  'Learn more about 2FA setup',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widget for the popular services grid
  Widget _buildPopularServicesGrid() {
    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // Important for nested scroll
        itemCount: controller.popularServices.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75, // Adjust item height vs width
        ),
        itemBuilder: (context, index) {
          final service = controller.popularServices[index];
          return _buildPopularServiceItem(service);
        },
      ),
    );
  }

  // Helper Widget for a single service item
  Widget _buildPopularServiceItem(PopularServiceModel service) {
    return GestureDetector(
      onTap: () => controller.selectPopularService(service),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              service.iconText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service.name,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Main function for testing the UI (Optional but helpful) ---

// void main() {
//   // Register the AddAccountController before running the app
//   // Get.put(AddAccountController());
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Add Account Demo',
//       initialRoute: '/',
//       getPages: [
//         GetPage(name: '/', page: () => const AddAccountPage()),
//         // Add other routes here, e.g., '/qr_scanner', '/manual_setup'
//         GetPage(name: '/qr_scanner', page: () => const Placeholder(child: Center(child: Text('QR Scanner Page')))),
//         GetPage(name: '/manual_setup', page: () => const Placeholder(child: Center(child: Text('Manual Setup Page')))),
//       ],
//     );
//   }
// }
