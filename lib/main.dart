import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';
import 'package:shieldconnect_app/controller/group_chat_controller.dart';
import 'package:shieldconnect_app/controller/login_controller.dart';
import 'package:shieldconnect_app/controller/onboarding_controller.dart';
import 'package:shieldconnect_app/controller/splash_controller.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/view/splash_screen.dart';

import 'package:shieldconnect_app/controller/signup_controller.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/controller/create_group_controller.dart';
import 'package:shieldconnect_app/controller/change_password_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/forgot_password_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/controller/account_controller.dart';
import 'package:shieldconnect_app/controller/help_support_controller.dart';
import 'package:shieldconnect_app/controller/call_list_controller.dart';

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
        ChangeNotifierProvider(create: (_) => ChangePasswordController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordController()),
        ChangeNotifierProvider(create: (_) => HomeScreenController()),
        ChangeNotifierProvider(create: (_) => AnnouncementController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => AddNewChatController()),
        ChangeNotifierProvider(create: (_) => AccountController()),
        ChangeNotifierProvider(create: (_) => GroupChatController()),
        ChangeNotifierProvider(create: (_) => StatusController()),
        ChangeNotifierProvider(create: (_) => HelpSupportController()),
        ChangeNotifierProvider(create: (_) => CallListController()),
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
