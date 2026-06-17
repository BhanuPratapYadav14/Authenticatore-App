// lib/Screens/SettingsPage/BackupRestore/BackupRestoreView.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Controllers/BackupController.dart';

class BackupRestoreView extends StatelessWidget {
  BackupRestoreView({super.key});

  final BackupController controller = Get.put(BackupController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoBanner(),
              const SizedBox(height: 24),
              _actionCard(
                icon: Icons.cloud_upload_outlined,
                title: 'Create Backup',
                subtitle:
                    'Export an encrypted backup, then save it to Google Drive, '
                    'OneDrive, Files or any app you choose.',
                buttonLabel: 'Create & Save Backup',
                onPressed: () => _onCreateBackup(context),
              ),
              const SizedBox(height: 16),
              _actionCard(
                icon: Icons.cloud_download_outlined,
                title: 'Restore Backup',
                subtitle:
                    'Pick a .zenauth backup file from any drive and enter its '
                    'password to restore your accounts.',
                buttonLabel: 'Restore from File',
                onPressed: () => _onRestoreBackup(context),
              ),
            ],
          ),
          // Blocking progress overlay while a backup/restore runs.
          Obx(
            () => controller.isWorking.value
                ? Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- Actions ---

  Future<void> _onCreateBackup(BuildContext context) async {
    final password = await _askPassword(context, isNew: true);
    if (password == null) return;
    await controller.createAndShareBackup(password);
  }

  Future<void> _onRestoreBackup(BuildContext context) async {
    final bytes = await controller.pickBackupFile();
    if (bytes == null) return; // cancelled
    if (!context.mounted) return;
    final password = await _askPassword(context, isNew: false);
    if (password == null) return;
    await controller.restoreBackup(bytes, password);
  }

  // --- Password dialog ---

  /// Returns the entered password, or null if cancelled. When [isNew] is true,
  /// a confirmation field is shown and both must match.
  Future<String?> _askPassword(
    BuildContext context, {
    required bool isNew,
  }) {
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    bool acknowledged = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isNew ? 'Set Backup Password' : 'Enter Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNew)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'You will need this password to restore the backup. '
                          'It cannot be recovered if lost.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (isNew && v.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (isNew)
                      TextFormField(
                        controller: confirmCtrl,
                        obscureText: obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                        validator: (v) {
                          if (v != passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    if (isNew)
                      CheckboxListTile(
                        value: acknowledged,
                        onChanged: (v) =>
                            setState(() => acknowledged = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'I understand this password cannot be recovered, '
                          'and the backup is useless without it.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  // For a new backup the user must acknowledge the password
                  // cannot be recovered before the button is enabled.
                  onPressed: (isNew && !acknowledged)
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(dialogContext).pop(passwordCtrl.text);
                          }
                        },
                  child: Text(isNew ? 'Create' : 'Restore'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- UI helpers ---

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Backups are encrypted with your password. Anyone with the file '
              'still needs the password to read your accounts.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Get.theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
