import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/model/settings_model.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

class AddMembersController extends ChangeNotifier {
  String? _userId;
  String? _groupId;

  Set<String> _existingMemberIds = {};
  Set<String> get existingMemberIds => _existingMemberIds;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> get friends => _friends;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  Timer? _searchDebounce;

  AddMembersController() {
    scrollController.addListener(_scrollListener);
    searchController.addListener(_searchListener);
  }

  Future<void> init(String userId, String groupId) async {
    _userId = userId;
    _groupId = groupId;
    _currentPage = 1;
    _hasMore = true;
    _friends = [];
    _existingMemberIds = {};
    _isLoading = true;
    notifyListeners();

    await fetchGroupMembers(groupId);
    await fetchConnectedUsers(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGroupMembers(String groupId) async {
    try {
      final response = await ApiService().get('/groups/$groupId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final Map<String, dynamic> details = json['data'];
        final List<dynamic>? membersList = details['members'];
        if (membersList != null) {
          for (var item in membersList) {
            if (item is Map) {
              final userMap = item['user_id'] is Map ? item['user_id'] as Map : null;
              final String mId = userMap?['_id']?.toString() ??
                  userMap?['id']?.toString() ??
                  item['user_id']?.toString() ??
                  "";
              if (mId.isNotEmpty) {
                _existingMemberIds.add(mId);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching group members in AddMembersController: $e");
    }
  }

  Future<void> fetchConnectedUsers(String userId, {bool isLoadMore = false, String name = ""}) async {
    if (isLoadMore) {
      if (!_hasMore || _isLoading) return;
    } else {
      _currentPage = 1;
      _hasMore = true;
      _friends = [];
    }

    try {
      final response = await ApiService().get(
        '/connections/friends/$userId?page=$_currentPage&limit=10${name.isNotEmpty ? "&name=${Uri.encodeComponent(name)}" : ""}',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final List<Map<String, dynamic>> newFriends = [];
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            final String fId = item['user_id']?.toString() ?? "";
            if (fId.isNotEmpty && !_existingMemberIds.contains(fId)) {
              newFriends.add({
                "id": fId,
                "name": item['name']?.toString() ?? "Unknown",
                "subtitle": item['email']?.toString() ?? (item['bio']?.toString() ?? "Hey there!"),
                "avatar": item['avatar']?.toString() ?? "",
                "isSelected": false,
              });
            }
          }
        }

        if (newFriends.length < 10) {
          _hasMore = false;
        }

        _friends.addAll(newFriends);
        if (newFriends.isNotEmpty) {
          _currentPage++;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Error fetching connected users in AddMembersController: $e");
      _hasMore = false;
    }
    notifyListeners();
  }

  void toggleUserSelection(int index) {
    if (index >= 0 && index < _friends.length) {
      _friends[index]['isSelected'] = !(_friends[index]['isSelected'] ?? false);
      notifyListeners();
    }
  }

  Future<bool> addMembers({BuildContext? context}) async {
    final List<String> selectedIds = _friends
        .where((f) => f['isSelected'] == true)
        .map((f) => f['id'].toString())
        .toList();

    if (selectedIds.isEmpty) return false;
    if (_userId == null || _groupId == null) return false;

    // Check dynamic member limit!
    final settings = await SettingsModel.loadActiveSettings();
    final maxMembers = settings.maxGroupMembers ?? 256;
    final int projectedTotal = _existingMemberIds.length + selectedIds.length;
    if (projectedTotal > maxMembers) {
      if (context != null && context.mounted) {
        ToastHelper.showWarningDialog(
          context,
          "Group Member Limit Exceeded",
          "This group cannot have more than $maxMembers members. Currently, the group has ${_existingMemberIds.length} members, and you selected ${selectedIds.length} members (Total: $projectedTotal)."
        );
      }
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/groups/$_groupId/members',
        data: {
          "requesterId": _userId,
          "userIds": selectedIds,
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding members in AddMembersController: $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (_userId != null) {
        fetchConnectedUsers(_userId!, isLoadMore: true, name: searchController.text);
      }
    }
  }

  void _searchListener() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_userId != null) {
        fetchConnectedUsers(_userId!, isLoadMore: false, name: searchController.text);
      }
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    searchController.removeListener(_searchListener);
    scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
}
