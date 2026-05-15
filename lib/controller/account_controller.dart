import 'package:flutter/material.dart';

class AccountController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Blocked Users
  List<Map<String, String>> _blockedUsers = [];
  List<Map<String, String>> get blockedUsers => _blockedUsers;

  // Wallpapers
  List<Map<String, String>> _wallpapers = [];
  List<Map<String, String>> get wallpapers => _wallpapers;
  String? _selectedWallpaperId;
  String? get selectedWallpaperId => _selectedWallpaperId;

  // Privacy Settings
  String _statusPrivacy = "all"; // 'all' or 'selected'
  String get statusPrivacy => _statusPrivacy;

  bool _isProfileImgVisible = true;
  bool _isBioVisible = true;
  bool _isLastSeenVisible = true;
  bool _isReadReceiptsEnabled = true;
  bool _isTypingIndicatorEnabled = true;

  bool get isProfileImgVisible => _isProfileImgVisible;
  bool get isBioVisible => _isBioVisible;
  bool get isLastSeenVisible => _isLastSeenVisible;
  bool get isReadReceiptsEnabled => _isReadReceiptsEnabled;
  bool get isTypingIndicatorEnabled => _isTypingIndicatorEnabled;

  // Fetch Blocked Users
  Future<void> fetchBlockedUsers() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _blockedUsers = [
      {"id": "1", "name": "John Doe", "image": "https://i.pravatar.cc/150?u=1"},
      {"id": "2", "name": "Jane Smith", "image": "https://i.pravatar.cc/150?u=2"},
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Fetch Wallpapers
  Future<void> fetchWallpapers() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _wallpapers = [
      {"id": "w1", "url": "https://images.unsplash.com/photo-1506744038136-46273834b3fb", "name": "Nature"},
      {"id": "w2", "url": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e", "name": "Forest"},
      {"id": "w3", "url": "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05", "name": "Mountain"},
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Select Wallpaper
  void selectWallpaper(String id) {
    _selectedWallpaperId = id;
    notifyListeners();
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    // Mock success
    
    _isLoading = false;
    notifyListeners();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    // Mock success
    
    _isLoading = false;
    notifyListeners();
  }

  // Update Status Privacy
  void updateStatusPrivacy(String value) {
    _statusPrivacy = value;
    notifyListeners();
  }

  // Toggle Privacy Settings
  void toggleProfileImgVisibility(bool value) {
    _isProfileImgVisible = value;
    notifyListeners();
  }

  void toggleBioVisibility(bool value) {
    _isBioVisible = value;
    notifyListeners();
  }

  void toggleLastSeenVisibility(bool value) {
    _isLastSeenVisible = value;
    notifyListeners();
  }

  void toggleReadReceipts(bool value) {
    _isReadReceiptsEnabled = value;
    notifyListeners();
  }

  void toggleTypingIndicator(bool value) {
    _isTypingIndicatorEnabled = value;
    notifyListeners();
  }
}
