import 'package:flutter/material.dart';

class AnnouncementController extends ChangeNotifier {
  List<dynamic> _announcements = [];
  List<dynamic> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await fetchAnnouncements();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAnnouncements() async {
    // Mock fetching announcements
    await Future.delayed(const Duration(milliseconds: 600));
    _announcements = [
      {
        'title': 'New Update Available',
        'content': 'We have released a new version of the app with improved security features.',
        'time': '2 hours ago',
      },
      {
        'title': 'System Maintenance',
        'content': 'The system will be down for maintenance on Sunday from 2 AM to 4 AM.',
        'time': '1 day ago',
      },
    ];
    notifyListeners();
  }
}
