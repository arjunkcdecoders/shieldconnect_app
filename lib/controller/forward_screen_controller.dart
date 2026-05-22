import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

class ForwardScreenController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  final Set<String> _selectedUserIds = {};
  final Set<String> _selectedGroupIds = {};
  
  bool _isLoading = true;
  String? _currentUserId;

  List<Map<String, dynamic>> get allChats => _allChats;
  List<Map<String, dynamic>> get filteredChats => _filteredChats;
  Set<String> get selectedUserIds => _selectedUserIds;
  Set<String> get selectedGroupIds => _selectedGroupIds;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  Future<void> fetchRecentChats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      _currentUserId = user.id;

      if (_currentUserId == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService().get('/chat/recent/$_currentUserId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _allChats.clear();
        for (var item in data) {
          final conversation = item['conversation'] ?? {};
          final bool isGroup = conversation['type'] == 'group';
          final String name = conversation['name']?.toString() ?? "Unknown";
          final String email = conversation['email']?.toString() ?? "";
          final String id = (conversation['id'] ?? conversation['_id'])?.toString() ?? "";
          final String avatar = conversation['image']?.toString() ?? "";
          final bool isSystem = conversation['isSystem'] == true || item['isSystem'] == true;

          if (!isSystem && name.toLowerCase() != 'admin') {
            _allChats.add({
              "id": id,
              "name": name,
              "subtitle": isGroup ? "Group Chat" : email,
              "avatar": avatar,
              "isGroup": isGroup,
            });
          }
        }
        _filteredChats = List.from(_allChats);
      }
    } catch (e) {
      debugPrint("Error fetching recent chats in forward screen controller: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterChats(String query) {
    if (query.isEmpty) {
      _filteredChats = List.from(_allChats);
    } else {
      _filteredChats = _allChats
          .where((chat) =>
              chat['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
              chat['subtitle'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void toggleSelection(String id, bool isGroup) {
    if (isGroup) {
      if (_selectedGroupIds.contains(id)) {
        _selectedGroupIds.remove(id);
      } else {
        _selectedGroupIds.add(id);
      }
    } else {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    }
    notifyListeners();
  }

  Future<void> forwardMessage(BuildContext context, String messageId) async {
    if ((_selectedUserIds.isEmpty && _selectedGroupIds.isEmpty) || _currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().post('/chat/forward', data: {
        "senderId": _currentUserId,
        "messageId": messageId,
        "targetUserIds": _selectedUserIds.toList(),
        "targetGroupIds": _selectedGroupIds.toList(),
      });

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        if (context.mounted) {
          ToastHelper.showToast(context, "Message forwarded successfully!");
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          ToastHelper.showToast(context, json['message']?.toString() ?? "Failed to forward message");
        }
      }
    } catch (e) {
      debugPrint("Error forwarding message: $e");
      if (context.mounted) {
        ToastHelper.showToast(context, "An error occurred while forwarding");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
