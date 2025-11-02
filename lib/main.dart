import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:zenauth/Screens/SplashScreenPage/SplashScreen.dart';
import 'package:zenauth/firebase_options.dart';
import 'package:zenauth/util/helperClasses/HiveHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveHelper.init();
  // Check the value from Hive before running the app.
  bool isOnBoardingVisited = HiveHelper.instance.getBool('isOnBoardingVisited');

  runApp(MyApp(isOnBoardingVisited: isOnBoardingVisited));
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  bool isOnBoardingVisited;
  MyApp({super.key, required this.isOnBoardingVisited});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      home: Splashscreen(),
    );
  }
}
