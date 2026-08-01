import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:shieldconnect_app/services/local_db_service.dart';

class CallListController extends ChangeNotifier {
  List<Map<String, dynamic>> _callHistory = [];
  List<Map<String, dynamic>> get callHistory => _callHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _profileImage;
  String? get profileImage => _profileImage;

  String? _userId;

  CallListController() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await fetchProfileImage();
    await loadCachedCalls();
    await fetchCallHistory();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCachedCalls() async {
    try {
      final List<Map<String, dynamic>> cachedRaw = await LocalDbService()
          .getCalls();
      if (cachedRaw.isNotEmpty) {
        _parseAndSetCalls(cachedRaw);
      }
    } catch (e) {
      debugPrint("Error loading cached calls: $e");
    }
  }

  List<Map<String, dynamic>> _allCalls = []; // Backup for filtering

  Future<void> fetchCallHistory() async {
    try {
      if (_userId == null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? sessionStr = prefs.getString('user_session');
        if (sessionStr != null) {
          final Map<String, dynamic> userMap = jsonDecode(sessionStr);
          final UserModel user = UserModel.fromJson(userMap);
          _userId = user.id;
        }
      }

      if (_userId == null || _userId!.isEmpty) {
        debugPrint(
          "CallListController: userId is null, skipping history fetch",
        );
        return;
      }

      final response = await ApiService().get('/call/history/$_userId');

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> rawCalls = json['data'] ?? [];
        _parseAndSetCalls(rawCalls);
        await LocalDbService().saveCalls(rawCalls);
      }
    } catch (e) {
      debugPrint("Error fetching call history: $e");
    }
  }

  void _parseAndSetCalls(List<dynamic> rawCalls) {
    final List<Map<String, dynamic>> parsedCalls = [];

    for (final dynamic call in rawCalls) {
      if (call is! Map<String, dynamic>) continue;

      final String callId = call['_id'] ?? '';
      final bool isGroup = call['is_group'] == true;
      final String callType = call['call_type'] ?? 'audio';
      final int duration = call['duration'] is int ? call['duration'] : 0;
      final String createdAt = call['created_at'] ?? '';
      final String userStatus = call['user_status'] ?? '';

      final initiator = call['initiator_id'] is Map<String, dynamic>
          ? call['initiator_id'] as Map<String, dynamic>
          : null;
      final receiver = call['receiver_id'] is Map<String, dynamic>
          ? call['receiver_id'] as Map<String, dynamic>
          : null;

      final String initiatorId = initiator != null
          ? (initiator['_id'] ?? '')
          : '';

      // Resolve name and avatar for display
      String name = '';
      String? avatar;

      bool showProfilePic = true;
      bool showLastSeen = true;
      bool showBio = true;
      bool showReadReceipts = true;
      bool showTypingIndicator = true;

      if (isGroup) {
        String tempName = call['group_name'] ?? 'Group Call';
        if (tempName == 'Group Call' || tempName.trim().isEmpty) {
          final Map<String, dynamic> participantsMap =
              call['participants'] is Map<String, dynamic>
              ? call['participants'] as Map<String, dynamic>
              : {};
          final List<Map<String, dynamic>> otherParticipants = [];
          participantsMap.forEach((key, value) {
            if (key != _userId && value is Map<String, dynamic>) {
              otherParticipants.add(value);
            }
          });

          if (otherParticipants.isNotEmpty) {
            final String firstParticipantName =
                otherParticipants[0]['name'] ?? 'User';
            final int remainingCount = otherParticipants.length - 1;
            if (remainingCount > 0) {
              tempName =
                  "$firstParticipantName + $remainingCount other${remainingCount > 1 ? 's' : ''}";
            } else {
              tempName = firstParticipantName;
            }
          }
        }
        name = tempName;
        avatar =
            call['group_avatar'] ??
            (call['group_id'] is Map<String, dynamic>
                ? call['group_id']['group_image']
                : null);
      } else {
        // 1-to-1 call: resolve details of the other participant
        final Map<String, dynamic>? otherParticipant = (initiatorId == _userId)
            ? receiver
            : initiator;
        if (otherParticipant != null) {
          name = otherParticipant['name'] ?? 'User';
          avatar = otherParticipant['avatar'];
          showProfilePic =
              otherParticipant['show_profile_pic'] as bool? ?? true;
          showLastSeen = otherParticipant['show_last_seen'] as bool? ?? true;
          showBio = otherParticipant['show_bio'] as bool? ?? true;
          showReadReceipts =
              otherParticipant['show_read_receipts'] as bool? ?? true;
          showTypingIndicator =
              otherParticipant['show_typing_indicator'] as bool? ?? true;
        } else {
          name = 'User';
        }
      }

      // Format duration: e.g. "6s", "33s"
      String durationText = '';
      if (duration > 0) {
        if (duration < 60) {
          durationText = '${duration}s';
        } else {
          final minutes = duration ~/ 60;
          final seconds = duration % 60;
          if (seconds == 0) {
            durationText = '${minutes}m';
          } else {
            durationText = '${minutes}m ${seconds}s';
          }
        }
      }

      final bool isOutgoing = initiatorId == _userId;
      final bool isMissed =
          !isOutgoing &&
          (userStatus == 'missed' ||
              userStatus == 'declined' ||
              userStatus == 'rejected' ||
              userStatus == 'invited');

      final String resolvedGroupId =
          (call['group_id'] is Map<String, dynamic>
              ? (call['group_id']['_id'] ?? call['group_id']['id'])?.toString()
              : call['group_id']?.toString()) ??
          callId;

      final List<String> groupMemberIds = [];
      final Map<String, dynamic> participantsMap =
          call['participants'] is Map<String, dynamic>
          ? call['participants'] as Map<String, dynamic>
          : {};
      participantsMap.keys.forEach((key) {
        if (key != _userId) {
          groupMemberIds.add(key);
        }
      });

      final String recipientIdVal = initiatorId == _userId
          ? (receiver != null
                ? (receiver['_id'] ?? receiver['id'] ?? '')?.toString() ?? ''
                : '')
          : initiatorId;

      parsedCalls.add({
        'id': callId,
        'name': name,
        'avatar': avatar,
        'time': DateHelper.formatCallLogDate(createdAt),
        'duration': durationText,
        'isMissed': isMissed,
        'isOutgoing': isOutgoing,
        'isVideoButton': callType == 'video',
        'isGroup': isGroup,
        'groupId': resolvedGroupId,
        'recipientId': recipientIdVal,
        'groupMemberIds': groupMemberIds,
        'rawGroupName': call['group_name']?.toString() ?? '',
        'show_profile_pic': showProfilePic,
        'show_last_seen': showLastSeen,
        'show_bio': showBio,
        'show_read_receipts': showReadReceipts,
        'show_typing_indicator': showTypingIndicator,
      });
    }

    _allCalls = parsedCalls;
    _callHistory = List.from(_allCalls);
    notifyListeners();
  }

  Future<void> fetchProfileImage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      debugPrint("HomeScreenController: sessionStr: $sessionStr");

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
        debugPrint("HomeScreenController: userId: $_userId");

        if (_userId != null) {
          final response = await ApiService().get(
            '/users/$_userId?currentUserId=$_userId',
          );
          debugPrint("HomeScreenController: API Response: ${response.data}");

          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json.containsKey('success') && json['success'] == true) {
            final data = json['data'];
            if (data != null) {
              _profileImage = data['avatar'];
            }
          }
        }
      } else {
        _profileImage = null;
      }
    } catch (e) {
      debugPrint("Error fetching profile image: $e");
      _profileImage = null;
    }
    notifyListeners();
  }

  void searchCalls(String query) {
    if (query.isEmpty) {
      _callHistory = List.from(_allCalls);
    } else {
      _callHistory = _allCalls
          .where(
            (call) => call["name"].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _connectedUsers = [];
  List<Map<String, dynamic>> get connectedUsers => _connectedUsers;

  bool _isLoadingConnected = false;
  bool get isLoadingConnected => _isLoadingConnected;

  Future<void> fetchConnectedUsers() async {
    if (_userId == null || _userId!.isEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
      }
    }

    if (_userId == null || _userId!.isEmpty) {
      debugPrint(
        "CallListController: userId is null, skipping connected users fetch",
      );
      return;
    }

    _isLoadingConnected = true;
    notifyListeners();

    try {
      final response = await ApiService().get('/connections/friends/$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _connectedUsers = data.map((item) {
          final Map<String, dynamic> friend = item as Map<String, dynamic>;
          final bool showBio = friend['show_bio'] as bool? ?? true;
          final String bio = showBio
              ? (friend['bio']?.toString() ?? "Hey there!")
              : "";
          return {
            "id": friend['user_id']?.toString() ?? "",
            "name": friend['name']?.toString() ?? "Unknown",
            "subtitle": friend['email']?.toString() ?? bio,
            "avatar": friend['avatar']?.toString() ?? "",
            "show_profile_pic": friend['show_profile_pic'] as bool? ?? true,
            "show_last_seen": friend['show_last_seen'] as bool? ?? true,
            "show_bio": showBio,
            "show_read_receipts": friend['show_read_receipts'] as bool? ?? true,
            "show_typing_indicator":
                friend['show_typing_indicator'] as bool? ?? true,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching connected users in CallListController: $e");
    } finally {
      _isLoadingConnected = false;
      notifyListeners();
    }
  }
}
