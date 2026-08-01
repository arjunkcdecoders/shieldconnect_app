import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/controller/moderator/moderation_controller.dart';

class ModeratorUsersController extends ChangeNotifier {

  List<Map<String, dynamic>> users = [];
  bool isLoading = false;
  bool hasError = false;
  String searchQuery = '';

  ModeratorUsersController() {
    fetchUsers();
  }

  List<Map<String, dynamic>> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          email.contains(searchQuery.toLowerCase());
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        hasError = true;
        isLoading = false;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final String? moderatorId = userMap['_id'] ?? userMap['id'];
      if (moderatorId == null || moderatorId.isEmpty) {
        hasError = true;
        isLoading = false;
        notifyListeners();
        return;
      }

      final responseJson = await ModerationController.apiFetchUsers(
        moderatorId: moderatorId,
        page: 1,
        limit: 100,
      );

      if (responseJson['success'] == true && responseJson['data'] != null) {
        final List<dynamic> fetchedList = responseJson['data'];
        users = fetchedList.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        hasError = true;
      }
    } catch (e) {
      debugPrint("ModeratorUsersController: Error fetching users: $e");
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(int index) async {
    final List<Map<String, dynamic>> currentFiltered = filteredUsers;
    if (index < 0 || index >= currentFiltered.length) return;
    
    final user = currentFiltered[index];
    final userId = user['_id'];
    if (userId == null) return;

    // Find the actual index in the complete users list to update it correctly
    final actualIndex = users.indexWhere((u) => u['_id'] == userId);
    if (actualIndex == -1) return;

    final currentStatus = user['approval_status'] ?? 'Active';
    final newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';

    // Optimistically update status
    users[actualIndex]['approval_status'] = newStatus;
    notifyListeners();

    final success = await ModerationController.apiUpdateUserApprovalStatus(
      userId: userId,
      approvalStatus: newStatus,
    );

    if (!success) {
      // Revert status on failure
      users[actualIndex]['approval_status'] = currentStatus;
      notifyListeners();
    }
  }
}
