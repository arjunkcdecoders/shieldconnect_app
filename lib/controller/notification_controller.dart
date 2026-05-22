import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/notification_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class NotificationController extends ChangeNotifier {
  NotificationController() {
    init();
  }

  List<NotificationModel> _ticketNotifications = [];
  List<NotificationModel> get ticketNotifications => _ticketNotifications;

  List<dynamic> _connectionRequests = [];
  List<dynamic> get connectionRequests => _connectionRequests;

  final List<String> _loadingAcceptRequestIds = [];
  List<String> get loadingAcceptRequestIds => _loadingAcceptRequestIds;

  final List<String> _loadingRejectRequestIds = [];
  List<String> get loadingRejectRequestIds => _loadingRejectRequestIds;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userId;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      _userId = user.id;
    }

    if (_userId != null) {
      await fetchTicketNotifications();
      await fetchConnectionRequests();
      _calculateUnreadCount();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTicketNotifications() async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get('/notifications/$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> list = json['data'] ?? [];
        _ticketNotifications = list.map((item) => NotificationModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching ticket notifications: $e");
    }
    notifyListeners();
  }

  Future<void> fetchConnectionRequests() async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get(
        '/connections/requests/$_userId?type=incoming&page=1&limit=20',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _connectionRequests = json['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching connection requests: $e");
    }
    notifyListeners();
  }

  void _calculateUnreadCount() {
    int notificationsUnread = _ticketNotifications.where((n) => n.isRead == false).length;
    int requestsPending = _connectionRequests.length; // All incoming requests are "new" until acted upon
    _unreadCount = notificationsUnread + requestsPending;
  }

  Future<void> acceptConnection(String requestId, String senderId) async {
    if (_userId == null) return;
    _loadingAcceptRequestIds.add(requestId);
    notifyListeners();
    try {
      final response = await ApiService().post(
        '/connections/connect',
        data: {
          "senderId": _userId,
          "recipientId": senderId,
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _connectionRequests.removeWhere((r) => r['_id'] == requestId || r['user_id']?['_id'] == senderId || r['user_id']?['id'] == senderId);
        _calculateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error accepting connection request: $e");
    } finally {
      _loadingAcceptRequestIds.remove(requestId);
      notifyListeners();
    }
  }

  Future<void> rejectConnection(String requestId, String senderId) async {
    if (_userId == null) return;
    _loadingRejectRequestIds.add(requestId);
    notifyListeners();
    try {
      final response = await ApiService().delete(
        '/connections/cancel',
        data: {
          "senderId": _userId,
          "recipientId": senderId,
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _connectionRequests.removeWhere((r) => r['_id'] == requestId || r['user_id']?['_id'] == senderId || r['user_id']?['id'] == senderId);
        _calculateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error rejecting connection request: $e");
    } finally {
      _loadingRejectRequestIds.remove(requestId);
      notifyListeners();
    }
  }
}
