import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/moderation_api_client.dart';
import 'package:shieldconnect_app/model/moderator/moderation_stats_response.dart';

class ModeratorHomeController extends ChangeNotifier {
  final ModerationApiClient _apiClient = ModerationApiClient();

  bool isLoadingStats = false;
  bool hasError = false;
  ModerationStats? stats;
  bool _hasFetched = false;

  ModeratorHomeController() {
    fetchModerationStats();
  }

  Future<void> fetchModerationStats({bool force = false}) async {
    if (isLoadingStats) return;
    if (_hasFetched && !force) return;
    isLoadingStats = true;
    _hasFetched = true;
    hasError = false;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        stats = null;
        hasError = true;
        _updateStatsWithNoData();
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? moderatorId = user.id;

      if (moderatorId == null || moderatorId.isEmpty) {
        stats = null;
        hasError = true;
        _updateStatsWithNoData();
        return;
      }

      final response = await _apiClient.fetchStats(moderatorId);
      if (response.success && response.data != null) {
        stats = response.data;
        hasError = false;
        // Update values dynamically
        dashboardStats[0]["value"] = _formatValue(stats!.usersCount);
        dashboardStats[1]["value"] = _formatValue(stats!.pending);
        dashboardStats[2]["value"] = _formatValue(stats!.reviewedToday);
        dashboardStats[3]["value"] = _formatValue(stats!.escalations);
      } else {
        stats = null;
        hasError = true;
        _updateStatsWithNoData();
      }
    } catch (e) {
      debugPrint("ModeratorHomeController: Error fetching stats: $e");
      stats = null;
      hasError = true;
      _updateStatsWithNoData();
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  void _updateStatsWithNoData() {
    for (var stat in dashboardStats) {
      stat["value"] = "-";
    }
  }

  String _formatValue(int val) {
    if (val < 10) return "0$val";
    return val.toString();
  }

  // Dummy data for the dashboard based on the image
  final List<Map<String, dynamic>> dashboardStats = [
    {"title": "Total Users", "value": "04", "color": const Color(0xFF0CA1CF)},
    {
      "title": "Pending Review",
      "value": "04",
      "color": const Color(0xFF1A9E16),
    },
    {
      "title": "Reviewed Today",
      "value": "04",
      "color": const Color(0xFFC61D1D),
    },
    {"title": "Escalations", "value": "02", "color": const Color(0xFFD42554)},
  ];

  final List<Map<String, dynamic>> moderationItems = [
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content":
          "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content":
          "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content":
          "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
    {
      "postId": "post-007",
      "userName": "SkyRunner",
      "riskScore": "0.87",
      "tags": ["GROOMING", "TRUST_BUILDING"],
      "content":
          "You seem so mature for your age. I've never met anyone who underst...",
      "timestamp": "1/15/2025  8:45:00 PM",
    },
  ];

  final List<Map<String, dynamic>> recentRegistrations = [
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image":
          "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image":
          "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
    },
    {
      "name": "Maisie williams",
      "email": "maisiewilliams@gmail.com",
      "phone": "9898989898",
      "country": "USA",
      "flag": "🇺🇸",
      "image":
          "https://images.pexels.com/photos/1520760/pexels-photo-1520760.jpeg?auto=compress&cs=tinysrgb&h=200",
    },
  ];
}
