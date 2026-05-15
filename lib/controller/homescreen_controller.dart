import 'package:flutter/material.dart';

class HomeScreenController extends ChangeNotifier {
  List<dynamic> _recentChats = [];
  List<dynamic> get recentChats => _recentChats;

  String? _profileImage;
  String? get profileImage => _profileImage;

  String? _adminAnnouncement;
  String? get adminAnnouncement => _adminAnnouncement;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await fetchRecentChats();
    await fetchProfileImage();
    await fetchAdminAnnouncement();
    await fetchNotificationCount();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRecentChats() async {
    // Mock fetching recent chats
    await Future.delayed(const Duration(milliseconds: 500));
    _recentChats = [
      {'name': 'John Doe', 'message': 'Hey, how are you?', 'time': '10:30 AM'},
      {'name': 'Jane Smith', 'message': 'See you soon!', 'time': '9:15 AM'},
    ];
    notifyListeners();
  }

  Future<void> fetchProfileImage() async {
    // Mock fetching profile image
    await Future.delayed(const Duration(milliseconds: 300));
    _profileImage = 'https://example.com/profile.jpg';
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
