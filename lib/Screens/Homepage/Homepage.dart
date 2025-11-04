// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:get/get.dart';

import '../../Controllers/HomeController.dart';
import '../../Widgets/AccountCard.dart';
import '../../Widgets/BottomNavBar.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  // Inject the controller
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => controller.navigateToSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          // List of Authenticator Accounts
          Expanded(
            child: Obx(() {
              if (controller.filteredAccounts.isEmpty &&
                  controller.searchController.text.isEmpty) {
                return const Center(
                  child: Text('No authenticator accounts added.'),
                );
              } else if (controller.filteredAccounts.isEmpty &&
                  controller.searchController.text.isNotEmpty) {
                return Center(
                  child: Text(
                    'No results for "${controller.searchController.text}"',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: controller.filteredAccounts.length,
                itemBuilder: (context, index) {
                  final account = controller.filteredAccounts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AccountCard(
                      account: account,
                      onCopy: () {
                        controller.copyOtpToClipboard(account.currentOtp);
                        Clipboard.setData(
                          ClipboardData(
                            text: account.currentOtp.replaceAll(' ', ''),
                          ),
                        ); // Copy without spaces
                      },
                      onMoreOptions: () {
                        // Implement more options (edit, delete)
                        Get.bottomSheet(
                          Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Edit Account'),
                                onTap: () {
                                  Get.back(); // Close bottom sheet
                                  // Navigate to edit screen or show dialog
                                  Get.snackbar(
                                    'Feature',
                                    'Edit not yet implemented',
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                title: const Text('Delete Account'),
                                onTap: () {
                                  Get.back(); // Close bottom sheet
                                  controller.deleteAccount(account.id);
                                },
                              ),
                            ],
                          ),
                          backgroundColor: Colors.white,
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.navigateToAddAccount(),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Position to the right
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Home is the first tab
        onTap: (index) {
          // Handle navigation based on index
          if (index == 0) {
            // Already on Home
          } else if (index == 1) {
            // Scan
            Get.toNamed('/scan');
          } else if (index == 2) {
            // Add
            controller.navigateToAddAccount();
          } else if (index == 3) {
            // Settings
            controller.navigateToSettings();
          }
        },
      ),
    );
  }
}
