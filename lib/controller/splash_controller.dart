import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/view/bottomnav_screen.dart';
import 'package:shieldconnect_app/view/onboarding_screen.dart';
import 'package:shieldconnect_app/services/socket_service.dart';

import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/view/moderator/bottomnav_screen/bottomnav_screen.dart'
    as mod;

class SplashController extends ChangeNotifier {
  bool _hasStarted = false;

  Future<void> initSplash(BuildContext context) async {
    if (_hasStarted) return;
    _hasStarted = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userSession = prefs.getString('user_session');

    if (userSession != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userSession);
        final String? userId = userMap['_id'] ?? userMap['id'];
        if (userId != null) {
          // Connect to the socket server during the splash screen duration
          SocketService().connect(userId);
          CallManager().init(
            userId,
            userMap['name']?.toString() ?? 'User',
            myUserAvatar: userMap['avatar']?.toString(),
          );
        }
      } catch (e) {
        debugPrint(
          "SplashController: Error parsing user_session for socket: $e",
        );
      }
    }

    Timer(const Duration(seconds: 3), () {
      if (context.mounted) {
        if (userSession != null) {
          final String appMode = prefs.getString('app_mode') ?? 'user';
          if (appMode == 'moderator') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const mod.BottomnavScreen(),
              ),
            );
          } else {
            Provider.of<HomeScreenController>(context, listen: false).init();
            Provider.of<ProfileController>(
              context,
              listen: false,
            ).init(context: context);
            Provider.of<AnnouncementController>(
              context,
              listen: false,
            ).fetchAnnouncements();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomnavScreen()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    });
  }
}
