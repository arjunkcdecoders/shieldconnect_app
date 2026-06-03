import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/notification_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/socket_service.dart';

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
  final Set<String> _seenRequestIds = {};

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
      // Load stored seen request IDs from SharedPreferences
      final List<String>? savedSeen = prefs.getStringList('seen_connection_requests_$_userId');
      if (savedSeen != null) {
        _seenRequestIds.addAll(savedSeen);
      }

      await fetchTicketNotifications();
      await fetchConnectionRequests();
      _calculateUnreadCount();

      // Setup real-time listeners for socket friend requests and notifications
      SocketService().connectionRequestNotifier.removeListener(_onConnectionRequestReceived);
      SocketService().connectionRequestNotifier.addListener(_onConnectionRequestReceived);

      SocketService().newNotificationNotifier.removeListener(_onNewNotificationReceived);
      SocketService().newNotificationNotifier.addListener(_onNewNotificationReceived);
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
        // Clean up _seenRequestIds to only retain active connection request IDs in SharedPreferences
        final Set<String> currentIds = _connectionRequests.map((r) => r['_id']?.toString() ?? '').toSet();
        final bool changed = _seenRequestIds.any((id) => !currentIds.contains(id));
        if (changed) {
          _seenRequestIds.retainWhere((id) => currentIds.contains(id));
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('seen_connection_requests_$_userId', _seenRequestIds.toList());
        }
      }
    } catch (e) {
      debugPrint("Error fetching connection requests: $e");
    }
    notifyListeners();
  }

  void _calculateUnreadCount() {
    int notificationsUnread = _ticketNotifications.where((n) => n.isRead == false).length;
    int requestsPending = _connectionRequests
        .where((r) => !_seenRequestIds.contains(r['_id']?.toString()))
        .length;
    _unreadCount = notificationsUnread + requestsPending;
  }

  Future<void> acceptConnection(String requestId, String senderId) async {
    if (_userId == null) return;
    _loadingAcceptRequestIds.add(requestId);
    notifyListeners();
    try {
      final response = await ApiService().put(
        '/connections/respond',
        data: {
          "userId": _userId,
          "otherUserId": senderId,
          "action": "accepted",
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _connectionRequests.removeWhere((r) => r['_id'] == requestId || r['user_id']?['_id'] == senderId || r['user_id']?['id'] == senderId);
        _seenRequestIds.remove(requestId);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('seen_connection_requests_$_userId', _seenRequestIds.toList());
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
      final response = await ApiService().put(
        '/connections/respond',
        data: {
          "userId": _userId,
          "otherUserId": senderId,
          "action": "rejected",
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _connectionRequests.removeWhere((r) => r['_id'] == requestId || r['user_id']?['_id'] == senderId || r['user_id']?['id'] == senderId);
        _seenRequestIds.remove(requestId);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('seen_connection_requests_$_userId', _seenRequestIds.toList());
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

  void _onConnectionRequestReceived() {
    final data = SocketService().connectionRequestNotifier.value;
    if (data == null) return;

    final String? recipientId = data['recipientId']?.toString();
    if (recipientId == _userId) {
      // Re-fetch connections to keep connectionRequests list and unreadCount fully consistent
      fetchConnectionRequests().then((_) => _calculateUnreadCount());
    }
  }

  void _onNewNotificationReceived() {
    final data = SocketService().newNotificationNotifier.value;
    if (data == null) return;

    final String? recipientId = data['recipientId']?.toString();
    if (recipientId == _userId) {
      // Re-fetch support tickets to keep ticketNotifications list and unreadCount fully consistent
      fetchTicketNotifications().then((_) => _calculateUnreadCount());
    }
  }

  Future<void> fetchNotificationsInBackground() async {
    // Mark existing notifications as read immediately for a responsive UI
    await markAllNotificationsAsRead();

    // Fetch new updates in the background
    await fetchTicketNotifications();
    await fetchConnectionRequests();
    _calculateUnreadCount();

    // Mark any newly fetched notifications as read
    await markAllNotificationsAsRead();
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_userId == null) return;
    try {
      bool changed = false;
      final List<NotificationModel> updatedList = [];
      for (var n in _ticketNotifications) {
        if (n.isRead == false) {
          updatedList.add(NotificationModel(
            id: n.id,
            recipientId: n.recipientId,
            type: n.type,
            title: n.title,
            message: n.message,
            metadata: n.metadata,
            isRead: true,
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          ));
          changed = true;
        } else {
          updatedList.add(n);
        }
      }

      // Mark all current connection requests as seen when notification screen is opened
      for (var r in _connectionRequests) {
        final String? rId = r['_id']?.toString();
        if (rId != null && !_seenRequestIds.contains(rId)) {
          _seenRequestIds.add(rId);
          changed = true;
        }
      }

      if (changed) {
        _ticketNotifications = updatedList;
        _calculateUnreadCount();
        notifyListeners();
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('seen_connection_requests_$_userId', _seenRequestIds.toList());
      }

      // Synchronize read receipt with backend database
      await ApiService().put('/notifications/$_userId');
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
    }
  }

  Future<void> clearAllNotifications() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().delete('/notifications/clear/$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String 
          ? jsonDecode(responseData) 
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _ticketNotifications = [];
        _calculateUnreadCount();
      }
    } catch (e) {
      debugPrint("Error clearing notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    SocketService().connectionRequestNotifier.removeListener(_onConnectionRequestReceived);
    SocketService().newNotificationNotifier.removeListener(_onNewNotificationReceived);
    super.dispose();
  }
}
