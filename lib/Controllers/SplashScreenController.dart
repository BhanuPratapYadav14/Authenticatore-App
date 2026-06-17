import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:zenauth/Screens/Homepage/Homepage.dart';
import 'package:zenauth/Screens/Loginpage/Loginpage.dart';
import 'package:zenauth/Screens/WelcomeScreen/welcomeScreen.dart';

import '../util/helperClasses/HiveHelper.dart';

class Splashscreencontroller extends GetxController {
  RxBool onBoardingVisited = false.obs;
  late final HiveHelper _hiveHelper;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _validateUser();
  }

  void _validateUser() async {
    _hiveHelper = await HiveHelper.init();
    onBoardingVisited.value = _hiveHelper.getBool("isOnBoardingVisited");

    final bool isSignedIn = _auth.currentUser != null;

    if (isSignedIn && onBoardingVisited.value) {
      // Signed in and onboarded -> go straight to home.
      print("Redirecting Home page");
      Get.offAll(() => HomeView());
    } else if (!isSignedIn && onBoardingVisited.value) {
      Future.delayed(Duration(seconds: 1), () {
        Get.to(() => LoginView());
      });
    } else {
      Future.delayed(Duration(seconds: 1), () {
        Get.to(() => WelcomeScreen());
      });
    }
  }
}
