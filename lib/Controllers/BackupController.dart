// lib/Controllers/BackupController.dart

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenauth/Controllers/HomeController.dart';

import '../Services/BackupService.dart';

class BackupController extends GetxController {
  final BackupService _backupService = BackupService();

  /// True while a backup or restore operation is running, used to show a
  /// blocking progress indicator and disable the action buttons.
  final RxBool isWorking = false.obs;

  /// Creates an encrypted backup file and opens the system share/save sheet so
  /// the user can store it on any drive (Google Drive, OneDrive, Files, ...).
  Future<void> createAndShareBackup(String password) async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      final file = await _backupService.createBackupFile(password);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'ZenAuth encrypted backup',
          text:
              'ZenAuth encrypted backup. Keep this file and its password safe.',
        ),
      );
      Get.snackbar(
        'Backup ready',
        'Choose a drive or app to save your encrypted backup.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on BackupException catch (e) {
      _error(e.message);
    } catch (e) {
      _error('Could not create backup. Please try again.');
    } finally {
      isWorking.value = false;
    }
  }

  /// Lets the user pick a backup file (from any drive/app via the system file
  /// picker). Returns its bytes, or null if the user cancelled.
  Future<Uint8List?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true, // ensures bytes are available even for cloud files
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.bytes;
  }

  /// Restores accounts from the previously picked backup [bytes].
  Future<void> restoreBackup(Uint8List bytes, String password) async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      final imported = await _backupService.restoreFromBytes(bytes, password);

      // Refresh the live account list if the home screen is active.
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().reloadAccounts();
      }

      Get.snackbar(
        'Restore complete',
        'Imported $imported account${imported == 1 ? '' : 's'}. '
            'Your settings and passcode were also restored.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on BackupException catch (e) {
      _error(e.message);
    } catch (e) {
      _error('Could not restore backup. Please try again.');
    } finally {
      isWorking.value = false;
    }
  }

  void _error(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }
}
