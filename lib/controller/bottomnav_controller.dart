import 'package:flutter/material.dart';
import 'package:shieldconnect_app/view/call_list_screen.dart';
import 'package:shieldconnect_app/view/chatlist_screen.dart';
import 'package:shieldconnect_app/view/status_screen.dart';
import 'package:shieldconnect_app/view/profile_screen.dart';

class BottomnavController extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final List<Widget> _screens = const [
    ChatlistScreen(),
    CallListScreen(),
    StatusScreen(),
    ProfileScreen(),
  ];

  List<Widget> get screens => _screens;
  Widget get currentScreen => _screens[_currentIndex];

  void changeTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}
