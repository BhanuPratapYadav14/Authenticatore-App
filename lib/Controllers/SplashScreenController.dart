import 'dart:convert';

import 'package:get/get.dart';
import 'package:zenauth/Models/ValidationModel.dart';
import 'package:zenauth/Screens/Homepage/Homepage.dart';
import 'package:zenauth/Screens/Loginpage/Loginpage.dart';
import 'package:zenauth/Screens/WelcomeScreen/welcomeScreen.dart';
import 'package:zenauth/Services/api_service.dart';

import '../util/helperClasses/HiveHelper.dart';

class Splashscreencontroller extends GetxController {
  RxBool onBoardingVisited = false.obs;
  // RxBool _isLogin = false.obs;
  late final HiveHelper _hiveHelper;

  late ValidationModel respnse;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    // _GoTOPage();
    _validateUser();
  }

  Future<void> GoToPage() async {
    onBoardingVisited.value = _hiveHelper.getBool("isOnBoardingVisited");

    if (respnse.status == "success" && onBoardingVisited.value) {
      // redirect to home page
      print("Redirecting Home page");
      Get.offAll(() => HomeView());
    } else if (!(respnse.status == "success") && onBoardingVisited.value) {
      Future.delayed(Duration(seconds: 1), () {
        Get.to(() => LoginView());
      });
    } else {
      Future.delayed(Duration(seconds: 1), () {
        Get.to(() => WelcomeScreen());
      });
    }
  }

  void _validateUser() async {
    _hiveHelper = await HiveHelper.init();
    final AccessToken = _hiveHelper.getString("AccessToken") ?? "";
    final httpResponse = await validateUser(AccessToken);

    if (httpResponse.statusCode == 200) {
      respnse = ValidationModel.fromJson(
        jsonDecode(httpResponse.body.toString()),
      );
    } else {
      print("Validation Failed");
      respnse = ValidationModel(
        message: "",
        status: "Faild",
        user: User(id: 0, username: "", email: "", lastLoginDevice: ""),
        tokenName: "",
      );
    }
    GoToPage();
  }

  // void _GoTOPage() {
  //   onBoardingVisited.value = _hiveHelper.getBool("isOnBoardingVisited");
  //   _isLogin.value = _hiveHelper.getBool("isUserLogedin");
  //   if (onBoardingVisited.value && _isLogin.value) {
  //     // redirect to home page
  //     Future.delayed(Duration(seconds: 1), () {
  //       Get.to(() => LoginView());
  //     });
  //   } else if (!_isLogin.value && onBoardingVisited.value) {
  //     Future.delayed(Duration(seconds: 1), () {
  //       Get.to(() => LoginView());
  //     });
  //   } else {
  //     Future.delayed(Duration(seconds: 1), () {
  //       Get.to(() => WelcomeScreen());
  //     });
  //   }
  // }
}
