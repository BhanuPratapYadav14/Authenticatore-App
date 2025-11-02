import 'package:get/get.dart';
import 'package:zenauth/Screens/Loginpage/Loginpage.dart';
import 'package:zenauth/Screens/WelcomeScreen/welcomeScreen.dart';

import '../util/helperClasses/HiveHelper.dart';

class Splashscreencontroller extends GetxController {
  RxBool onBoardingVisited = false.obs;
  RxBool _isLogin = false.obs;
  late final HiveHelper _hiveHelper;
  @override
  void onInit() async {
    // TODO: implement onInit
    super.onInit();
    _hiveHelper = await HiveHelper.init();
    _GoTOPage();
  }

  void _GoTOPage() {
    onBoardingVisited.value = _hiveHelper.getBool("isOnBoardingVisited");
    _isLogin.value = _hiveHelper.getBool("isUserLogedin");
    if (onBoardingVisited.value && _isLogin.value) {
      Future.delayed(Duration(seconds: 1), () {
        Get.to(() => LoginView());
      });
    } else if (!_isLogin.value && onBoardingVisited.value) {
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
