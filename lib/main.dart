import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zenauth/Controllers/AppLockController.dart';
import 'package:zenauth/Controllers/SettingsController.dart';
import 'package:zenauth/Screens/SplashScreenPage/SplashScreen.dart';
import 'package:zenauth/Services/BiometricService.dart';
import 'package:zenauth/Services/SecureStorageService.dart';
import 'package:zenauth/firebase_options.dart';
import 'package:zenauth/util/AppTheme.dart';
import 'package:zenauth/util/helperClasses/HiveHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveHelper.init();
  Get.put(BiometricService(), permanent: true);
  await Get.putAsync<SettingsController>(
    () async => await SettingsController.init(),
    permanent: true,
  );
  Get.put(SecureStoragePassCodeService(), permanent: true);
  // Global app-lock controller. Depends on SettingsController, so it must be
  // registered after it. Observes the app lifecycle to show the passcode
  // lock screen when the app is opened or resumed from the background.
  Get.put(AppLockController(), permanent: true);

  runApp(MyApp());
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      // Seed the initial mode from the persisted setting; later changes are
      // applied live via Get.changeThemeMode in SettingsController.updateTheme.
      themeMode: settingsController.themeMode,
      home: Splashscreen(),
    );
  }
}
