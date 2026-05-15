import 'package:flutter/material.dart';

class StatusController extends ChangeNotifier {
  Map<String, dynamic>? _myStatus;
  Map<String, dynamic>? get myStatus => _myStatus;

  List<Map<String, dynamic>> _recentStatuses = [];
  List<Map<String, dynamic>> get recentStatuses => _recentStatuses;

  List<Map<String, dynamic>> _viewedStatuses = [];
  List<Map<String, dynamic>> get viewedStatuses => _viewedStatuses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadMyStatus();
    await loadOthersStatuses();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyStatus() async {
    // Mock loading my current status
    await Future.delayed(const Duration(milliseconds: 300));
    _myStatus = {
      "hasStatus": true,
      "time": "Just now",
      "mediaUrl": "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400",
      "views": 12,
    };
    notifyListeners();
  }

  Future<void> loadOthersStatuses() async {
    // Mock loading others and viewed statuses
    await Future.delayed(const Duration(milliseconds: 600));
    _recentStatuses = [
      {
        "name": "Alice Johnson",
        "time": "10 mins ago",
        "avatar": "assets/images/obchild1.png",
        "statusCount": 3,
        "isViewed": false,
      },
      {
        "name": "Bob Wilson",
        "time": "25 mins ago",
        "avatar": "assets/images/obchild2.png",
        "statusCount": 1,
        "isViewed": false,
      },
    ];

    _viewedStatuses = [
      {
        "name": "Charlie Day",
        "time": "3 hours ago",
        "avatar": "assets/images/maisie_avatar.png",
        "statusCount": 2,
        "isViewed": true,
      },
    ];
    notifyListeners();
  }

  Future<void> pickMedia() async {
    // Mock picking media from device
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> uploadStatus(String mediaPath) async {
    // Mock status upload
    await Future.delayed(const Duration(seconds: 1));
    _myStatus = {
      "hasStatus": true,
      "time": "Just now",
      "mediaUrl": mediaPath,
      "views": 0,
    };
    notifyListeners();
  }

  Future<void> deleteStatus() async {
    // Mock status deletion
    await Future.delayed(const Duration(milliseconds: 400));
    _myStatus = null;
    notifyListeners();
  }

  Future<List<Map<String, String>>> fetchStatusViewers() async {
    // Mock fetching users who viewed my status
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {"name": "Alice Johnson", "time": "10:05 AM", "avatar": "assets/images/obchild1.png"},
      {"name": "Bob Wilson", "time": "10:15 AM", "avatar": "assets/images/obchild2.png"},
    ];
  }
}
