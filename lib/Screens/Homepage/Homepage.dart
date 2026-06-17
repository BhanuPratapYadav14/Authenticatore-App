// lib/views/home_view.dart
import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:get/get.dart';

import '../../Controllers/AppLockController.dart';
import '../../Controllers/HomeController.dart';
import '../../Widgets/AccountCard.dart';

enum MenuItem { home, addAccount, settings }

class HomeView extends StatefulWidget {
  HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Inject the controller
  final HomeController controller = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
    // Show the passcode lock on first app open (cold start). The controller
    // is a no-op when the passcode feature is disabled or already locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AppLockController>().lockOnStartup();
    });
  }

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
                                  // Close bottom sheet
                                  // print(
                                  //   "The Account Selected to Delete is: ${account.id}",
                                  // );
                                  controller.deleteAccount(account.id);
                                  Get.back();
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
      floatingActionButton: CircularMenu(
        key: controller.menuKey,
        alignment: Alignment.bottomRight, // Position the menu
        toggleButtonColor: Colors.black,
        // toggleButtonIcon: const Icon(Icons.menu, color: Colors.white),
        radius: 100, // Distance of items from the center
        toggleButtonBoxShadow: [],

        items: [
          CircularMenuItem(
            icon: Icons.home,
            color: Colors.black,
            onTap: () => controller.onMenuItemSelected(MenuItem.home),
            boxShadow: [],
          ),
          CircularMenuItem(
            icon: Icons.add,
            color: Colors.black,
            onTap: () => controller.onMenuItemSelected(MenuItem.addAccount),
            boxShadow: [],
          ),
          CircularMenuItem(
            icon: Icons.settings,
            color: Colors.black,
            onTap: () => controller.onMenuItemSelected(MenuItem.settings),
            boxShadow: [],
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Position to the right
      // Bottom Navigation Bar
    );
  }
}
