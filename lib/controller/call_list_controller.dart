import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class CallListController extends ChangeNotifier {
  List<Map<String, dynamic>> _callHistory = [];
  List<Map<String, dynamic>> get callHistory => _callHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _profileImage;
  String? get profileImage => _profileImage;

  String? _userId;

  CallListController() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await fetchProfileImage();
    await fetchCallHistory();

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _allCalls = []; // Backup for filtering

  Future<void> fetchCallHistory() async {
    // Mock fetching call history
    await Future.delayed(const Duration(milliseconds: 500));
    _allCalls = [
      {
        "name": "Alice Johnson",
        "time": "10:30 AM",
        "type": "voice",
        "status": "missed",
        "avatar": "assets/images/obchild1.png",
        "date": "Today",
      },
      {
        "name": "Bob Wilson",
        "time": "09:15 AM",
        "type": "video",
        "status": "outgoing",
        "avatar": "assets/images/obchild2.png",
        "date": "Today",
      },
      {
        "name": "Design Team",
        "time": "Yesterday, 04:20 PM",
        "type": "voice",
        "status": "incoming",
        "isGroup": true,
        "avatar":
            "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
        "date": "Yesterday",
      },
      {
        "name": "Charlie Brown",
        "time": "May 12, 11:00 AM",
        "type": "video",
        "status": "missed",
        "avatar": "assets/images/maisie_avatar.png",
        "date": "May 12",
      },
    ];
    _callHistory = List.from(_allCalls);
    notifyListeners();
  }

  Future<void> fetchProfileImage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      debugPrint("HomeScreenController: sessionStr: $sessionStr");

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
        debugPrint("HomeScreenController: userId: $_userId");

        if (_userId != null) {
          final response = await ApiService().get(
            '/users/$_userId?currentUserId=$_userId',
          );
          debugPrint("HomeScreenController: API Response: ${response.data}");

          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json.containsKey('success') && json['success'] == true) {
            final data = json['data'];
            if (data != null) {
              _profileImage = data['avatar'];
            }
          }
        }
      } else {
        _profileImage = null;
      }
    } catch (e) {
      debugPrint("Error fetching profile image: $e");
      _profileImage = null;
    }
    notifyListeners();
  }

  void searchCalls(String query) {
    if (query.isEmpty) {
      _callHistory = List.from(_allCalls);
    } else {
      _callHistory = _allCalls
          .where(
            (call) => call["name"].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    }
    notifyListeners();
  }
}
