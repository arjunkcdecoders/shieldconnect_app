import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/user_model.dart';
import '../../services/moderation_api_client.dart';

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

  List<Map<String, dynamic>> moderationItems = [
    {
      "postId": "post-007",
      "userName": "Sun Flower Kid",
      "riskScore": "0.87",
      "confidence": "98%",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content": "You seem so mature for your age. I've never met anyone who underetands me like you do. Can we talk somewhere more private?",
      "timestamp": "1/15/2025  8:45:00 PM",
      "status": "Pending",
    },
    {
      "postId": "post-008",
      "userName": "Maisie Williams",
      "riskScore": "98%",
      "confidence": "98%",
      "reason": "GROOMING . SECRECY",
      "tags": ["Safe"],
      "content": "Hello! How are you doing today? I hope you're having a great time.",
      "timestamp": "1/16/2025  10:30:00 AM",
      "status": "Approved",
    },
    {
      "postId": "post-009",
      "userName": "John Doe",
      "riskScore": "95%",
      "confidence": "92%",
      "reason": "COMMUNITY_GUIDELINES",
      "tags": ["Safe"],
      "content": "Just sharing some travel tips for the summer!",
      "timestamp": "1/16/2025  11:15:00 AM",
      "status": "Approved",
    },
    {
      "postId": "post-010",
      "userName": "Alex Smith",
      "riskScore": "99%",
      "reason": "HATE_SPEECH . HARASSMENT",
      "tags": [],
      "content": "You are terrible and should leave this platform immediately!",
      "timestamp": "1/17/2025  9:00:00 AM",
      "status": "Rejected",
    },
    {
      "postId": "post-011",
      "userName": "User-442",
      "riskScore": "97%",
      "reason": "SPAM . PHISHING",
      "tags": [],
      "content": "Click here to win a free iPhone! Totally legit link inside.",
      "timestamp": "1/17/2025  9:45:00 AM",
      "status": "Rejected",
    },
    {
      "postId": "ESC-post-101",
      "userName": "MountainClimber",
      "riskScore": "CRITICAL",
      "reason": "Potential life safety threat detected in chat log",
      "statusTag": "Under Review",
      "tags": [],
      "content": "I'm standing at the edge of the bridge and I don't know what to do.",
      "timestamp": "1/18/2025  2:30:00 PM",
      "status": "Escalations",
    },
    {
      "postId": "ESC-post-102",
      "userName": "NightOwl",
      "riskScore": "HIGH",
      "reason": "Explicit predatory behavior pattern identified",
      "statusTag": "Pending Action",
      "tags": [],
      "content": "Where do you live? Can I come over while your parents are away?",
      "timestamp": "1/18/2025  3:15:00 PM",
      "status": "Escalations",
    },
  ];

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == "All") return moderationItems;
    final status = selectedCategory == "Pendings" ? "Pending" : selectedCategory;
    return moderationItems.where((item) => item['status'] == status).toList();
  }

  void changeCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void approveItem(int index) {
    moderationItems[index]['status'] = "Approved";
    notifyListeners();
  }

  void rejectItem(int index) {
    moderationItems[index]['status'] = "Rejected";
    notifyListeners();
  }

  void escalateItem(int index) {
    moderationItems[index]['status'] = "Escalated";
    notifyListeners();
  }

  Future<bool> updateItemStatus({
    required String itemId,
    required String status,
  }) async {
    bool apiSuccess = false;

    // 1. Try to make API call
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
      );
      apiSuccess = response.success;
    } catch (e) {
      debugPrint("ModerationController: API status update error: $e");
    }

    // 2. Fallback / Sync update: update local list item status
    final index = moderationItems.indexWhere((i) => i['postId'] == itemId || i['_id'] == itemId);
    if (index != -1) {
      String localStatus = "Pending";
      if (status == 'Approved') {
        localStatus = 'Approved';
      } else if (status == 'Blocked') {
        localStatus = 'Rejected';
      } else if (status == 'Escalate') {
        localStatus = 'Escalations';
      }
      moderationItems[index]['status'] = localStatus;
      notifyListeners();
      return true; // Return true as local state was updated successfully
    }

    return apiSuccess;
  }
}
