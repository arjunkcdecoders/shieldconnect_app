import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/view/onboarding_screen.dart';

class SplashController extends ChangeNotifier {
  bool _hasStarted = false;

  void initSplash(BuildContext context) {
    if (_hasStarted) return;
    _hasStarted = true;

    Timer(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }
}
