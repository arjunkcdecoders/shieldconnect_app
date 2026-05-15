import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/login_controller.dart';
import 'package:shieldconnect_app/controller/onboarding_controller.dart';
import 'package:shieldconnect_app/controller/splash_controller.dart';
import 'package:shieldconnect_app/view/splash_screen.dart';

import 'package:shieldconnect_app/controller/signup_controller.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/controller/create_group_controller.dart';
import 'package:shieldconnect_app/controller/edit_profile_controller.dart';
import 'package:shieldconnect_app/controller/change_password_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashController()),
        ChangeNotifierProvider(create: (_) => OnboardingController()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => SignupController()),
        ChangeNotifierProvider(create: (_) => BottomnavController()),
        ChangeNotifierProvider(create: (_) => CreateGroupController()),
        ChangeNotifierProvider(create: (_) => EditProfileController()),
        ChangeNotifierProvider(create: (_) => ChangePasswordController()),
      ],
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

