// lib/views/qr_scanner_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../Controllers/QrScannerController.dart';

class QrScannerPage extends GetView<QrScannerController> {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    Get.put(QrScannerController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // --- 1. Mobile Scanner Camera View ---
          MobileScanner(
            controller: controller.scannerController,
            onDetect: controller.onBarcodeDetect,
            // Ensure the camera stream fills the entire body
            fit: BoxFit.cover,
          ),

          // --- 2. Scanner Overlay (Optional: Focus box, text) ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Highlight area for QR code (the "window")
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Align QR code within the frame to scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // --- 3. Control Buttons (Flash, Manual Entry) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash/Torch Button
                  Obx(
                    () => IconButton(
                      icon: Icon(
                        controller.isFlashOn.value
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: controller.isFlashOn.value
                            ? Colors.yellow
                            : Colors.white,
                        size: 32,
                      ),
                      onPressed: controller.toggleFlash,
                    ),
                  ),

                  // Manual Entry Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Stop the scanner before navigating
                      controller.scannerController.stop();
                      Get.back(); // Close scanner page
                      Get.toNamed('/manual_setup'); // Navigate to manual setup
                    },
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
