import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/user_model.dart';
import '../../services/moderation_api_client.dart';
import '../../model/moderator/moderation_item.dart';

class ModerationController extends ChangeNotifier {
  final ModerationApiClient _apiClient = ModerationApiClient();

  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Approved",
    "Rejected",
    "Escalations",
    "Pendings"
  ];

  List<ModerationItem> moderationItems = [];
  bool isLoading = false;
  bool hasError = false;

  ModerationController() {
    fetchHistory();
  }

  List<ModerationItem> get filteredItems => moderationItems;

  Future<void> fetchHistory() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        moderationItems = [];
        hasError = true;
        return;
      }
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? moderatorId = user.id;

      if (moderatorId == null || moderatorId.isEmpty) {
        moderationItems = [];
        hasError = true;
        return;
      }

      String apiStatus = "";
      if (selectedCategory == "Approved") {
        apiStatus = "Approved";
      } else if (selectedCategory == "Rejected") {
        apiStatus = "Blocked";
      } else if (selectedCategory == "Escalations") {
        apiStatus = "Escalate";
      } else if (selectedCategory == "Pendings") {
        apiStatus = "Moderation";
      }

      final response = await _apiClient.fetchHistory(
        page: 1,
        limit: 20,
        moderatorId: moderatorId,
        status: apiStatus,
      );

      if (response.success) {
        moderationItems = response.data;
        hasError = false;
      } else {
        moderationItems = [];
        hasError = true;
      }
    } catch (e) {
      debugPrint("ModerationController: fetchHistory error: $e");
      moderationItems = [];
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void changeCategory(String category) {
    selectedCategory = category;
    fetchHistory();
  }

  Future<bool> updateItemStatus({
    required String itemId,
    required String status,
    bool isProfileUpdate = false,
    String? profileType,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        debugPrint("ModerationController: No user_session found, aborting API call");
        return false;
      }
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? moderatorId = user.id;
      if (moderatorId == null || moderatorId.isEmpty) {
        debugPrint("ModerationController: moderatorId is null or empty, aborting API call");
        return false;
      }

      final response = await _apiClient.updateItemStatus(
        itemId: itemId,
        status: status,
        moderatorId: moderatorId,
        isProfileUpdate: isProfileUpdate,
        profileType: profileType,
      );
      if (response.success) {
        fetchHistory();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("ModerationController: API status update error: $e");
      return false;
    }
  }
}
