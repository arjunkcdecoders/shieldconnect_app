import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class ChatSettingsController extends ChangeNotifier {
  ChatSettingsController() {
    init();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUpdatingPrivacy = false;
  bool get isUpdatingPrivacy => _isUpdatingPrivacy;

  String? _updatingPrivacyOption;
  String? get updatingPrivacyOption => _updatingPrivacyOption;

  String _userId = "";
  String get userId => _userId;

  String _statusPrivacy = "contacts";
  String get statusPrivacy => _statusPrivacy;

  List<String> _statusPrivacyList = [];
  List<String> get statusPrivacyList => _statusPrivacyList;

  List<Map<String, dynamic>> _connectedUsers = [];
  List<Map<String, dynamic>> get connectedUsers => _connectedUsers;

  // Toggle settings
  bool _showProfilePic = true;
  bool get showProfilePic => _showProfilePic;

  bool _showBio = true;
  bool get showBio => _showBio;

  bool _showLastSeen = true;
  bool get showLastSeen => _showLastSeen;

  bool _readReceipts = true;
  bool get readReceipts => _readReceipts;

  bool _typingIndicators = true;
  bool get typingIndicators => _typingIndicators;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id ?? "";

        if (_userId.isNotEmpty) {
          // Fetch latest user details from server to populate settings
          final response = await ApiService().get('/users/$_userId?currentUserId=$_userId');
          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json['success'] == true && json['data'] != null) {
            final data = json['data'];
            _statusPrivacy = data['status_privacy']?.toString() ?? "contacts";
            
            final dynamic listData = data['status_privacy_list'];
            if (listData is List) {
              _statusPrivacyList = listData.map((e) => e.toString()).toList();
            } else {
              _statusPrivacyList = [];
            }

            _showProfilePic = data['show_profile_pic'] as bool? ?? true;
            _showBio = data['show_bio'] as bool? ?? true;
            _showLastSeen = data['show_last_seen'] as bool? ?? true;
            _readReceipts = data['show_read_receipts'] as bool? ?? true;
            _typingIndicators = data['show_typing_indicator'] as bool? ?? true;
          }

          // Fetch list of connected users (friends)
          await fetchConnectedUsers();
        }
      }
    } catch (e) {
      debugPrint("Error initializing ChatSettingsController: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConnectedUsers() async {
    if (_userId.isEmpty) return;
    try {
      final response = await ApiService().get('/connections/friends/$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _connectedUsers = data.map((item) {
          final Map<String, dynamic> friend = item as Map<String, dynamic>;
          return {
            "id": friend['user_id']?.toString() ?? "",
            "name": friend['name']?.toString() ?? "Unknown",
            "subtitle": friend['email']?.toString() ?? (friend['bio']?.toString() ?? "Hey there!"),
            "avatar": friend['avatar']?.toString() ?? "",
            "isSelected": _statusPrivacyList.contains(friend['user_id']?.toString()),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching connected users: $e");
    }
  }

  Future<void> updateStatusPrivacy(String privacy, {List<String>? privacyList}) async {
    if (_userId.isEmpty) return;
    _isUpdatingPrivacy = true;
    _updatingPrivacyOption = privacy;
    notifyListeners();

    try {
      final Map<String, dynamic> requestData = {
        "status_privacy": privacy,
      };
      if (privacyList != null) {
        requestData["status_privacy_list"] = privacyList;
      }

      final response = await ApiService().put(
        '/users/profile/$_userId',
        data: requestData,
      );
      final Map<String, dynamic> json = response.data is String
          ? jsonDecode(response.data)
          : response.data as Map<String, dynamic>;

      if (json['success'] == true) {
        _statusPrivacy = privacy;
        if (privacyList != null) {
          _statusPrivacyList = List<String>.from(privacyList);
        }

        // Update isSelected flag in connected users list
        for (var user in _connectedUsers) {
          user["isSelected"] = _statusPrivacyList.contains(user["id"]);
        }

        // Save to SharedPreferences session to keep it in sync globally
        await _updateLocalSession({
          "status_privacy": privacy,
          "status_privacy_list": _statusPrivacyList,
        });
      }
    } catch (e) {
      debugPrint("Error updating status privacy: $e");
    } finally {
      _isUpdatingPrivacy = false;
      _updatingPrivacyOption = null;
      notifyListeners();
    }
  }

  Future<void> updateToggleSetting(String field, bool value) async {
    if (_userId.isEmpty) return;

    // Capture the current value for potential rollback on failure
    bool previousValue = true;
    if (field == 'show_profile_pic') {
      previousValue = _showProfilePic;
      _showProfilePic = value;
    } else if (field == 'show_bio') {
      previousValue = _showBio;
      _showBio = value;
    } else if (field == 'show_last_seen') {
      previousValue = _showLastSeen;
      _showLastSeen = value;
    } else if (field == 'show_read_receipts') {
      previousValue = _readReceipts;
      _readReceipts = value;
    } else if (field == 'show_typing_indicator') {
      previousValue = _typingIndicators;
      _typingIndicators = value;
    }

    // Optimistically update the UI immediately
    notifyListeners();

    try {
      final response = await ApiService().put(
        '/users/profile/$_userId',
        data: {field: value},
      );
      final Map<String, dynamic> json = response.data is String
          ? jsonDecode(response.data)
          : response.data as Map<String, dynamic>;

      if (json['success'] == true) {
        await _updateLocalSession({field: value});
      } else {
        // Rollback state since API indicated failure
        _rollbackToggle(field, previousValue);
      }
    } catch (e) {
      debugPrint("Error updating toggle setting $field: $e");
      // Rollback state due to network or other errors
      _rollbackToggle(field, previousValue);
    }
  }

  void _rollbackToggle(String field, bool previousValue) {
    if (field == 'show_profile_pic') _showProfilePic = previousValue;
    if (field == 'show_bio') _showBio = previousValue;
    if (field == 'show_last_seen') _showLastSeen = previousValue;
    if (field == 'show_read_receipts') _readReceipts = previousValue;
    if (field == 'show_typing_indicator') _typingIndicators = previousValue;
    notifyListeners();
  }

  Future<void> _updateLocalSession(Map<String, dynamic> updatedUserData) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        userMap.addAll(updatedUserData);
        await prefs.setString('user_session', jsonEncode(userMap));
        debugPrint("ChatSettingsController: SharedPreferences user_session successfully updated.");
      }
    } catch (e) {
      debugPrint("Error updating local session: $e");
    }
  }
}
