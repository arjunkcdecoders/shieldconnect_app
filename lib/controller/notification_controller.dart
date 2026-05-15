import 'package:flutter/material.dart';

class NotificationController extends ChangeNotifier {
  List<dynamic> _connectionRequests = [];
  List<dynamic> get connectionRequests => _connectionRequests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await fetchConnectionRequests();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchConnectionRequests() async {
    // Mock fetching connection requests
    await Future.delayed(const Duration(milliseconds: 500));
    _connectionRequests = [
      {'name': 'Alice Johnson', 'status': 'pending', 'id': '1'},
      {'name': 'Bob Wilson', 'status': 'pending', 'id': '2'},
      {'name': 'Charlie Davis', 'status': 'pending', 'id': '3'},
    ];
    notifyListeners();
  }
}
