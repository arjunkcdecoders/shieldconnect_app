import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/model/api_response.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController() {
    init();
  }

  List<dynamic> _announcements = [];
  List<dynamic> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().get('/announcements');
      
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
      } else {
        _announcements = [];
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
      _announcements = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
