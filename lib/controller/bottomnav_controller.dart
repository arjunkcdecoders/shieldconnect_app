import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/services/api_services.dart';
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
  bool _hasCheckedStatus = false;

  BottomnavController() {
    checkStatusFeature();
  }

  Future<void> checkStatusFeature({bool force = false}) async {
    if (_hasCheckedStatus && !force) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final String? userId = userMap['_id'] ?? userMap['id'];
        if (userId != null && userId.isNotEmpty) {
          final response = await ApiService().get('/users/$userId?currentUserId=$userId');
          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json['success'] == true && json['data'] != null) {
            final data = json['data'];
            final dynamic settings = data['settings'];
            if (settings is Map) {
              final bool statusFeatureActive =
                  settings['statusFeatureActive'] != false;
              final bool isEnabled = statusFeatureActive;
              _hasCheckedStatus = true;
              if (_statusFeatureEnabled != isEnabled) {
                _statusFeatureEnabled = isEnabled;
                notifyListeners();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking status feature via API: $e");
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
    _hasCheckedStatus = false;
    _statusFeatureEnabled = true;
    notifyListeners();
  }
}
