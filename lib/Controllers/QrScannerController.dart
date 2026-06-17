// lib/controllers/qr_scanner_controller.dart (UPDATED)

import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zenauth/Controllers/HomeController.dart';

import '../Models/OtpAccountModel.dart';

class QrScannerController extends GetxController {
  final homeController = Get.find<HomeController>();
  final Rx<OtpAccountModel?> scannedAccount = Rx<OtpAccountModel?>(null);
  final RxBool isProcessing = false.obs;

  // ✅ NEW REACTIVE STATE for the flash status
  RxBool isFlashOn = false.obs;

  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void onInit() {
    super.onInit();

    scannerController.addListener(_updateTorchState);
  }

  @override
  void onClose() {
    scannerController.removeListener(_updateTorchState);
    scannerController.dispose();
    super.onClose();
  }

  /// Handles the raw barcode data detected
  void onBarcodeDetect(BarcodeCapture capture) async {
    // ... (rest of the logic remains the same)
    if (isProcessing.isTrue || capture.barcodes.isEmpty) {
      return;
    }

    final rawValue = capture.barcodes.first.rawValue;

    if (rawValue != null) {
      await scannerController.stop();
      isProcessing.value = true;

      try {
        print("The Extracted Raw Value$rawValue");
        final account = OtpAccountModel.fromUri(rawValue);
        scannedAccount.value = account;

        // Pop via the root navigator (not Get.back) to avoid a GetX
        // SnackbarController LateInitializationError when an open snackbar
        // (e.g. the flashlight toggle) is closed during navigation.
        Get.key.currentState?.pop(account);
        // homeController.addAccount(account);

        Get.snackbar(
          'QR Scanned Success',
          'Account for ${account.issuer} added!',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        isProcessing.value = false;
        await scannerController.start();
        Get.snackbar(
          'Scan Error',
          'Invalid or unsupported QR code format.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    }
  }

  // --- Utility Methods ---

  void toggleFlash() async {
    // 1. Tell the MobileScannerController to toggle the flash
    await scannerController.toggleTorch();

    // 2. The listener (_updateTorchState) will automatically update
    //    isFlashOn.value when the toggle is complete.

    // Optional: Add feedback based on the new state
    Get.snackbar(
      'Flash',
      isFlashOn.value ? 'Flashlight ON' : 'Flashlight OFF',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _updateTorchState() {
    // Check the torchState from the controller's current value
    isFlashOn.value = scannerController.value.torchState == TorchState.on;
  }
}
