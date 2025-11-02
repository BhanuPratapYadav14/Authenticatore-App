import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zenauth/Controllers/SplashScreenController.dart';

class Splashscreen extends StatelessWidget {
  Splashscreen({super.key});
  final Splashscreencontroller _splashscreencontroller = Get.put(
    Splashscreencontroller(),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  height: Get.height * 0.12,
                  width: Get.width * 0.25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      topLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                    color: Colors.black,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Universal Auth',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unified Authenticator',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const Spacer(flex: 1),

                const Spacer(flex: 3),

                Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '\u00A9 2025 SecurAuth',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
