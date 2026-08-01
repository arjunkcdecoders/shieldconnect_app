import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/view/bottomnav_screen.dart';

class LaunchLoadingController extends ChangeNotifier {
  bool _hasNavigated = false;

  void startTimer(BuildContext context) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Timer(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomnavScreen()),
        );
        _hasNavigated = false;
      }
    });
  }
}
