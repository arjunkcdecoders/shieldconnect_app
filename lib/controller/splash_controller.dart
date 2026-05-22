import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/view/bottomnav_screen.dart';
import 'package:shieldconnect_app/view/onboarding_screen.dart';

class SplashController extends ChangeNotifier {
  bool _hasStarted = false;

  Future<void> initSplash(BuildContext context) async {
    if (_hasStarted) return;
    _hasStarted = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userSession = prefs.getString('user_session');

    Timer(const Duration(seconds: 3), () {
      if (context.mounted) {
        if (userSession != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomnavScreen()),
          );
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
