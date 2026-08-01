import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/model/api_response.dart';
import 'package:shieldconnect_app/services/local_db_service.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController() {
    init();
  }

  List<dynamic> _announcements = [];
  List<dynamic> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Future<void> init() async {
    await loadCachedAnnouncements();
    await fetchAnnouncements();
  }

  Future<void> loadCachedAnnouncements() async {
    try {
      final List<Map<String, dynamic>> cached = await LocalDbService().getAnnouncements();
      if (cached.isNotEmpty) {
        _announcements = cached;
        // Calculate unread count
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? sessionStr = prefs.getString('user_session');
        String? lastReadTimestamp;
        if (sessionStr != null) {
          final Map<String, dynamic> userMap = jsonDecode(sessionStr);
          lastReadTimestamp = userMap['lastReadAnnouncementTimestamp']?.toString();
        }
        if (lastReadTimestamp == null || lastReadTimestamp.isEmpty) {
          _unreadCount = _announcements.length;
        } else {
          final DateTime lastReadDateTime = DateTime.parse(lastReadTimestamp).toUtc();
          _unreadCount = 0;
          for (final ann in _announcements) {
            final String? createdStr = ann['createdAt'] ?? ann['created_at'] ?? ann['time'];
            if (createdStr != null && createdStr.isNotEmpty) {
              try {
                final DateTime annDateTime = DateTime.parse(createdStr).toUtc();
                if (annDateTime.isAfter(lastReadDateTime)) {
                  _unreadCount++;
                }
              } catch (_) {}
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading cached announcements: $e");
    }
  }

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      String? userId;
      String? lastReadTimestamp;

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        userId = userMap['_id'] ?? userMap['id'];
        lastReadTimestamp = userMap['lastReadAnnouncementTimestamp']?.toString();
      }

      String? regionParam;
      if (userId != null && userId.isNotEmpty) {
        try {
          final userResponse = await ApiService().get('/users/$userId?currentUserId=$userId');
          final dynamic userData = userResponse.data;
          final Map<String, dynamic> userJson = userData is String 
              ? jsonDecode(userData) 
              : userData as Map<String, dynamic>;
          
          if (userJson['success'] == true && userJson['data'] != null) {
            final data = userJson['data'];
            final dynamic rawRegion = data['region'];
            if (rawRegion is Map) {
              regionParam = (rawRegion['_id'] ?? rawRegion['id'] ?? rawRegion['name'])?.toString();
            } else if (rawRegion != null) {
              regionParam = rawRegion.toString();
            }
          }
        } catch (e) {
          debugPrint("Error fetching user region from API inside AnnouncementController: $e");
        }
      }

      String url = '/announcements';
      if (regionParam != null && regionParam.isNotEmpty) {
        url += '?region=${Uri.encodeComponent(regionParam)}';
      }

      final response = await ApiService().get(url);
      
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      // Correctly parsing the nested structure: data -> announcements
      if (json.containsKey('success') && json['success'] == true) {
        final data = json['data'];
        if (data != null && data is Map<String, dynamic>) {
          _announcements = data['announcements'] as List<dynamic>? ?? [];
        } else if (data is List<dynamic>) {
          _announcements = data;
        } else {
          _announcements = [];
        }
        await LocalDbService().saveAnnouncements(_announcements);
      } else {
        if (_announcements.isEmpty) {
          _announcements = [];
        }
      }

      // Calculate unread count based on lastReadTimestamp
      if (lastReadTimestamp == null || lastReadTimestamp.isEmpty) {
        _unreadCount = _announcements.length;
      } else {
        final DateTime lastReadDateTime = DateTime.parse(lastReadTimestamp).toUtc();
        _unreadCount = 0;
        for (final ann in _announcements) {
          final String? createdStr = ann['createdAt'] ?? ann['created_at'] ?? ann['time'];
          if (createdStr != null && createdStr.isNotEmpty) {
            try {
              final DateTime annDateTime = DateTime.parse(createdStr).toUtc();
              if (annDateTime.isAfter(lastReadDateTime)) {
                _unreadCount++;
              }
            } catch (_) {
              // Ignore invalid date format
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
      if (_announcements.isEmpty) {
        _announcements = [];
        _unreadCount = 0;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    _unreadCount = 0;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        DateTime? maxDateTime;
        for (final ann in _announcements) {
          final String? createdStr = ann['createdAt'] ?? ann['created_at'] ?? ann['time'];
          if (createdStr != null && createdStr.isNotEmpty) {
            try {
              final DateTime dt = DateTime.parse(createdStr).toUtc();
              if (maxDateTime == null || dt.isAfter(maxDateTime)) {
                maxDateTime = dt;
              }
            } catch (_) {}
          }
        }
        final DateTime finalTimestamp = maxDateTime ?? DateTime.now().toUtc();
        userMap['lastReadAnnouncementTimestamp'] = finalTimestamp.toIso8601String();
        await prefs.setString('user_session', jsonEncode(userMap));
      }
    } catch (e) {
      debugPrint("Error marking announcements as read: $e");
    }
  }
}
