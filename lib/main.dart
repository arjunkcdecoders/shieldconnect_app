import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';
import 'package:shieldconnect_app/controller/group_chat_controller.dart';
import 'package:shieldconnect_app/controller/login_controller.dart';
import 'package:shieldconnect_app/controller/onboarding_controller.dart';
import 'package:shieldconnect_app/controller/splash_controller.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/firebase_options.dart';
import 'package:shieldconnect_app/view/splash_screen.dart';

import 'package:shieldconnect_app/controller/signup_controller.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/controller/change_password_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/forgot_password_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/controller/account_controller.dart';
import 'package:shieldconnect_app/controller/help_support_controller.dart';
import 'package:shieldconnect_app/controller/call_list_controller.dart';
import 'package:shieldconnect_app/controller/chat_settings_controller.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shieldconnect_app/services/fcm_service.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/view/global_ongoing_call_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Register background handler for call signaling push events
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  await FcmService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashController()),
        ChangeNotifierProvider(create: (_) => OnboardingController()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => SignupController()),
        ChangeNotifierProvider(create: (_) => BottomnavController()),
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
        ChangeNotifierProvider(create: (_) => ChatSettingsController()),
        ChangeNotifierProvider(create: (_) => CallManager()),
        ChangeNotifierProvider(create: (_) => CallController()),
      ],
      child: const MyApp(),
    ),
  );
}



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const GlobalOngoingCallBanner(),
          ],
        );
      },
    );
  }
}
