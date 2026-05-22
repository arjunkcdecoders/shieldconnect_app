import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class HomeScreenController extends ChangeNotifier {
  HomeScreenController() {
    init();
  }

  List<dynamic> _recentChats = [];
  List<dynamic> get recentChats => _recentChats;

  String? _profileImage;
  String? get profileImage => _profileImage;

  String? _adminAnnouncement;
  String? get adminAnnouncement => _adminAnnouncement;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  int _requestCount = 0;
  int get requestCount => _requestCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _activeTab = 'All';
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
    fetchRecentChats(tab: tab);
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await fetchRecentChats(updateLoadingState: false);
    await fetchRequestCount();
    await fetchProfileImage();
    await fetchAdminAnnouncement();
    await fetchNotificationCount();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRequestCount() async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get('/chat/recent/$_userId?tab=Requests');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      if (json['success'] == true) {
        final List<dynamic> requests = json['data'] ?? [];
        _requestCount = requests.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching request count: $e");
    }
  }

  Future<void> fetchRecentChats({String? tab, bool updateLoadingState = true}) async {
    try {
      if (updateLoadingState) {
        _isLoading = true;
        notifyListeners();
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
      } else {
        _userId = null;
        _recentChats = [];
      }

      if (_userId != null) {
        String endpoint = '/chat/recent/$_userId';
        String currentTab = tab ?? _activeTab;
        if (currentTab.isNotEmpty && currentTab != 'All') {
          endpoint += '?tab=$currentTab';
        }

        final response = await ApiService().get(endpoint);
        debugPrint(
          "HomeScreenController fetchRecentChats: API Response: ${response.data}",
        );

        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true) {
          _recentChats = json['data'] ?? [];
        } else {
          _recentChats = [];
        }

        await fetchRequestCount();
      }
    } catch (e) {
      debugPrint("Error fetching recent chats: $e");
      _recentChats = [];
    } finally {
      if (updateLoadingState) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  String? _userId;

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

  Future<void> fetchAdminAnnouncement() async {
    // Mock fetching admin announcement
    await Future.delayed(const Duration(milliseconds: 400));
    _adminAnnouncement = 'Maintenance scheduled for tonight at 12 AM.';
    notifyListeners();
  }

  Future<void> fetchNotificationCount() async {
    // Mock fetching notification count
    await Future.delayed(const Duration(milliseconds: 200));
    _notificationCount = 5;
    notifyListeners();
  }
}
