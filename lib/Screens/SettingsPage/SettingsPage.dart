// lib/Views/SettingsPage.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/SettingsController.dart';
// Ensure correct path

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.navigateBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() {
          final settingsData = controller.settings.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- Header: User Info ---
              _buildHeader(
                settingsData.userName,
                settingsData.accountsSecuredCount,
              ),
              const SizedBox(height: 16),

              // --- Section 1: SECURITY ---
              _buildSectionTitle('SECURITY'),
              _buildSwitchItem(
                title: 'Enable Biometrics',
                subtitle: 'Use Face ID or Fingerprint',
                icon: Icons.fingerprint,
                value: settingsData.isBiometricsEnabled,
                onChanged: controller.toggleBiometrics,
              ),
              _buildNavigationItem(
                title: 'Passcode Lock',
                subtitle: settingsData.isPasscodeSet ? 'Change PIN' : 'Set PIN',
                icon: Icons.lock_outline,
                onTap: controller.navigateToPasscodeLock,
              ),
              const Divider(height: 1, thickness: 1),

              // --- Section 2: DATA MANAGEMENT ---
              _buildSectionTitle('DATA MANAGEMENT'),
              _buildNavigationItem(
                title: 'Backup & Restore',
                subtitle: 'Cloud or local backup',
                icon: Icons.cloud_upload_outlined,
                onTap: controller.navigateToBackupRestore,
              ),
              const Divider(height: 1, thickness: 1),

              // --- Section 3: APPEARANCE ---
              _buildSectionTitle('APPEARANCE'),
              _buildNavigationItem(
                title: 'Theme',
                subtitle: settingsData.currentTheme,
                icon: Icons.light_mode_outlined,
                onTap: controller.navigateToTheme,
              ),
              const Divider(height: 1, thickness: 1),

              // --- Section 4: HELP & INFO ---
              _buildSectionTitle('HELP & INFO'),
              _buildNavigationItem(
                title: 'About',
                subtitle: 'App info & version',
                icon: Icons.info_outline,
                onTap: controller.navigateToAbout,
              ),
              _buildNavigationItem(
                title: 'FAQ',
                subtitle: 'Frequently asked questions',
                icon: Icons.question_mark_outlined,
                onTap: controller.navigateToFAQ,
              ),
              _buildNavigationItem(
                title: 'Contact Support',
                subtitle: 'Get help from our team',
                icon: Icons.headset_mic_outlined,
                onTap: controller.navigateToContactSupport,
              ),
            ],
          );
        }),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader(String name, int count) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Placeholder for User Avatar/Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueGrey.shade100,
            ),
            child: const Icon(Icons.person, size: 30, color: Colors.blueGrey),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count accounts secured',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Get.theme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Get.theme.primaryColor,
      ),
      onTap: () => onChanged(!value), // Allows tapping the whole tile to toggle
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}
