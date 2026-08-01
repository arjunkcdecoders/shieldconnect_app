import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/user_model.dart';
import '../../model/moderator/moderation_item.dart';
import '../../services/api_services.dart';
import '../../model/moderator/session_response.dart';
import '../../model/moderator/moderation_stats_response.dart';
import '../../model/moderator/moderation_history_response.dart';
import '../../model/moderator/action_update_response.dart';
import '../../model/moderator/pagination_info.dart';

class ModerationController extends ChangeNotifier {
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

      final response = await apiFetchHistory(
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

      final response = await apiUpdateItemStatus(
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

  // --- Static API Methods ---

  // 1. Fetch Session (GET /api/admin/session)
  static Future<SessionResponse> apiFetchSession() async {
    try {
      final response = await ApiService().get('/admin/session');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return SessionResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationController: Error fetching session: $e");
      return SessionResponse(
        isLoggedIn: true,
        admin: SessionAdmin(
          id: "mod123",
          email: "moderator@shieldconnect.com",
          role: "Moderator",
          name: "System Admin",
        ),
      );
    }
  }

  // 2. Fetch Stats (GET /api/admin/moderation/stats?moderatorId=<MODERATOR_ID>)
  static Future<ModerationStatsResponse> apiFetchStats(String moderatorId) async {
    try {
      final response = await ApiService().get(
        '/admin/moderation/stats?moderatorId=$moderatorId',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      debugPrint("ModerationController: Stats $json");
      return ModerationStatsResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationController: Error fetching stats: $e");
      return ModerationStatsResponse(
        success: false,
        message: e.toString(),
        data: ModerationStats(
          pending: 0,
          reviewedToday: 0,
          escalations: 0,
          usersCount: 0,
        ),
      );
    }
  }

  // 3. Fetch History (GET /api/admin/moderation/history)
  static Future<ModerationHistoryResponse> apiFetchHistory({
    required int page,
    required int limit,
    required String moderatorId,
    required String status,
  }) async {
    try {
      String query = 'page=$page&limit=$limit&moderatorId=$moderatorId';
      if (status.isNotEmpty) {
        query += '&status=$status';
      }
      final response = await ApiService().get('/admin/moderation/history?$query');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return ModerationHistoryResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationController: Error fetching history: $e");
      return ModerationHistoryResponse(
        success: false,
        count: 0,
        status: status,
        data: [],
        pagination: PaginationInfo(
          page: page,
          limit: limit,
          totalPages: 1,
          totalRecords: 0,
        ),
      );
    }
  }

  // 4. Update Item Status (PUT /api/admin/moderation/:id)
  static Future<ActionUpdateResponse> apiUpdateItemStatus({
    required String itemId,
    required String status,
    required String moderatorId,
    bool isProfileUpdate = false,
    String? profileType,
  }) async {
    try {
      String finalId = itemId;
      if (isProfileUpdate) {
        final String rawId = itemId
            .replaceFirst('user:', '')
            .replaceFirst('group:', '');
        if (profileType == 'group') {
          finalId = 'group:$rawId';
        } else {
          finalId = 'user:$rawId';
        }
      }
      final response = await ApiService().put(
        '/admin/moderation/$finalId',
        data: {'status': status, 'moderatorId': moderatorId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return ActionUpdateResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationController: Error updating item status: $e");
      return ActionUpdateResponse(success: false, message: e.toString());
    }
  }

  // 5. Fetch Users List (GET /api/admin/users)
  static Future<Map<String, dynamic>> apiFetchUsers({
    required String moderatorId,
    required int page,
    required int limit,
  }) async {
    try {
      final response = await ApiService().get(
        '/admin/users?moderator_id=$moderatorId&page=$page&limit=$limit',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint("ModerationController: Error fetching users: $e");
      return {'success': false, 'data': []};
    }
  }

  // 6. Update User Approval Status (PUT /api/admin/users/:userId/approval)
  static Future<bool> apiUpdateUserApprovalStatus({
    required String userId,
    required String approvalStatus,
  }) async {
    try {
      final response = await ApiService().put(
        '/admin/users/$userId/approval',
        data: {'approval_status': approvalStatus},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return json['success'] ?? false;
    } catch (e) {
      debugPrint("ModerationController: Error updating user approval status: $e");
      return false;
    }
  }
}
