import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/view/call_list_screen.dart';
import 'package:shieldconnect_app/view/chatlist_screen.dart';
import 'package:shieldconnect_app/view/dhsi_screen.dart';
import 'package:shieldconnect_app/view/status_screen.dart';
import 'package:shieldconnect_app/view/profile_screen.dart';

class BottomnavController extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _statusFeatureEnabled = true;
  bool get statusFeatureEnabled => _statusFeatureEnabled;

  BottomnavController() {
    checkStatusFeature();
  }

  Future<void> checkStatusFeature() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final dynamic settings = userMap['settings'];
        if (settings is Map) {
          final bool statusFeature = settings['statusFeature'] != false;
          final bool statusFeatureActive = settings['statusFeatureActive'] != false;
          final bool isEnabled = statusFeature && statusFeatureActive;
          if (_statusFeatureEnabled != isEnabled) {
            _statusFeatureEnabled = isEnabled;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking status feature: $e");
    }
  }

  List<Widget> get screens => [
    const ChatlistScreen(),
    const CallListScreen(),
    const DhsiScreen(),
    if (_statusFeatureEnabled) const StatusScreen(),
    const ProfileScreen(),
  ];

  Widget get currentScreen {
    final activeScreens = screens;
    if (_currentIndex >= activeScreens.length) {
      _currentIndex = 0;
    }
    return activeScreens[_currentIndex];
  }

  void changeTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}
