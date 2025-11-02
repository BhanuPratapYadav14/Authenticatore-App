import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zenauth/Models/features.dart';
import 'package:zenauth/Screens/Loginpage/Loginpage.dart';

import '../util/helperClasses/HiveHelper.dart';

class WelcomeController extends GetxController {
  RxBool onBoardingVisited = false.obs;
  late final HiveHelper _hiveHelper;
  final List<Feature> features = [
    Feature(
      icon: Icons.lock_outline,
      title: 'Secure & Private',
      subtitle: 'Your data stays on your device',
    ),
    Feature(
      icon: Icons.all_inbox_outlined,
      title: 'All-in-One',
      subtitle: 'Manage all your 2FA codes in one app',
    ),
    Feature(
      icon: Icons.access_time,
      title: 'Always Ready',
      subtitle: 'Quick access to your codes anytime',
    ),
  ];

  @override
  void onInit() async {
    // TODO: implement onInit
    super.onInit();
    _hiveHelper = await HiveHelper.init();
    onBoardingVisited.value = _hiveHelper.getBool("isOnBoardingVisited");
  }

  void onGetStarted() {
    _hiveHelper.saveBool("isOnBoardingVisited", true);

    Future.delayed(Duration(seconds: 1), () {
      Get.to(LoginView());
    });
  }

  void initializedHiveHelper() async {}
}
