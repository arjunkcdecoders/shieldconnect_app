import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/wallpaper_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

class AccountController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userId;
  String? get userId => _userId;

  String? _unblockingUserId;
  String? get unblockingUserId => _unblockingUserId;

  // Unblock Errors map (otherUserId -> error message)
  final Map<String, String> _unblockErrors = {};
  Map<String, String> get unblockErrors => _unblockErrors;

  // Blocked Users
  List<Map<String, String>> _blockedUsers = [];
  List<Map<String, String>> get blockedUsers => _blockedUsers;

  // Wallpapers
  List<WallpaperModel> _wallpapers = [];
  List<WallpaperModel> get wallpapers => _wallpapers;
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

  // Load current selected wallpaper from local user session
  Future<void> init() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _selectedWallpaperId = user.chatWallpaper;
        _userId = user.id;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("AccountController: Error loading selected wallpaper from session: $e");
    }
  }

  // Fetch Blocked Users
  Future<void> fetchBlockedUsers() async {
    if (_isLoading) return;
    _isLoading = true;
    _unblockErrors.clear();
    notifyListeners();

    try {
      if (_userId == null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? sessionStr = prefs.getString('user_session');
        if (sessionStr != null) {
          final Map<String, dynamic> userMap = jsonDecode(sessionStr);
          final UserModel user = UserModel.fromJson(userMap);
          _userId = user.id;
        }
      }

      if (_userId != null) {
        final response = await ApiService().get('/connections/blocked/$_userId');
        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true && json['data'] != null) {
          final List<dynamic> dataList = json['data'];
          _blockedUsers = dataList.map<Map<String, String>>((item) {
            final userObj = item['user'] as Map<String, dynamic>? ?? {};
            return {
              "id": (userObj['_id'] ?? userObj['id'] ?? '').toString(),
              "name": (userObj['name'] ?? '').toString(),
              "image": (userObj['avatar'] ?? '').toString(),
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching blocked users: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Unblock User
  Future<void> unblockUser(String otherUserId) async {
    if (_unblockingUserId != null) return;
    _unblockingUserId = otherUserId;
    _unblockErrors.remove(otherUserId);
    notifyListeners();

    try {
      if (_userId == null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? sessionStr = prefs.getString('user_session');
        if (sessionStr != null) {
          final Map<String, dynamic> userMap = jsonDecode(sessionStr);
          final UserModel user = UserModel.fromJson(userMap);
          _userId = user.id;
        }
      }

      if (_userId != null) {
        final response = await ApiService().post(
          '/connections/unblock',
          data: {
            "userId": _userId,
            "otherUserId": otherUserId,
          },
        );

        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true) {
          _blockedUsers.removeWhere((user) => user['id'] == otherUserId);
        } else {
          _unblockErrors[otherUserId] = "Failed to unblock";
        }
      } else {
        _unblockErrors[otherUserId] = "Failed to unblock";
      }
    } catch (e) {
      debugPrint("Error unblocking user: $e");
      _unblockErrors[otherUserId] = "Failed to unblock";
    }

    _unblockingUserId = null;
    notifyListeners();
  }

  // Fetch Wallpapers
  Future<void> fetchWallpapers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().get('/admin/wallpapers?status=Active');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final List<dynamic> dataList = json['data'];
        _wallpapers = dataList
            .map((item) => WallpaperModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching wallpapers: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Select Wallpaper
  Future<void> selectWallpaper(BuildContext context, String wallpaperId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);

        final response = await ApiService().put(
          '/users/profile/${user.id}',
          data: {"chat_wallpaper": wallpaperId},
        );

        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true && json['data'] != null) {
          final updatedUser = UserModel.fromJson(json['data'] as Map<String, dynamic>);
          await prefs.setString('user_session', jsonEncode(updatedUser.toJson()));
          _selectedWallpaperId = updatedUser.chatWallpaper;
          if (context.mounted) {
            ToastHelper.showToast(context, "Wallpaper updated successfully!");
          }
        } else {
          if (context.mounted) {
            ToastHelper.showToast(context, json['message'] ?? "Failed to update wallpaper");
          }
        }
      } else {
        if (context.mounted) {
          ToastHelper.showToast(context, "User session not found");
        }
      }
    } catch (e) {
      debugPrint("Error selecting wallpaper: $e");
      if (context.mounted) {
        ToastHelper.showToast(context, "Connection error. Please try again.");
      }
    }

    _isLoading = false;
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

  // Toggle Bio Visibility
  void toggleBioVisibility(bool value) {
    _isBioVisible = value;
    notifyListeners();
  }

  // Toggle Last Seen Visibility
  void toggleLastSeenVisibility(bool value) {
    _isLastSeenVisible = value;
    notifyListeners();
  }

  // Toggle Read Receipts
  void toggleReadReceipts(bool value) {
    _isReadReceiptsEnabled = value;
    notifyListeners();
  }

  // Toggle Typing Indicator
  void toggleTypingIndicator(bool value) {
    _isTypingIndicatorEnabled = value;
    notifyListeners();
  }
}
