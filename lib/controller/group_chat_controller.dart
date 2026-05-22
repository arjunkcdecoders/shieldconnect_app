import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

class GroupChatController extends ChangeNotifier {
  bool _isDisposed = false;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  Map<String, dynamic>? _selectedMessageForOptions;
  Map<String, dynamic>? get selectedMessageForOptions =>
      _selectedMessageForOptions;

  void selectMessageForOptions(Map<String, dynamic>? message) {
    _selectedMessageForOptions = message;
    notifyListeners();
  }

  String? _highlightedMessageId;
  String? get highlightedMessageId => _highlightedMessageId;

  void highlightMessage(String msgId) {
    _highlightedMessageId = msgId;
    notifyListeners();
    // Re-verify and clear after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_highlightedMessageId == msgId) {
        _highlightedMessageId = null;
        notifyListeners();
      }
    });
  }

  Map<String, dynamic>? _groupDetails;
  Map<String, dynamic>? get groupDetails => _groupDetails;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  bool _hasLeftGroup = false;
  bool get hasLeftGroup => _hasLeftGroup;

  String? _wallpaperUrl;
  String? get wallpaperUrl => _wallpaperUrl;

  String? _removingMemberId;
  String? get removingMemberId => _removingMemberId;

  String? _failedMemberId;
  String? get failedMemberId => _failedMemberId;

  String? _makingAdminMemberId;
  String? get makingAdminMemberId => _makingAdminMemberId;

  String? _successAdminMemberId;
  String? get successAdminMemberId => _successAdminMemberId;

  String? _failedAdminMemberId;
  String? get failedAdminMemberId => _failedAdminMemberId;

  String? _demotingAdminMemberId;
  String? get demotingAdminMemberId => _demotingAdminMemberId;

  String? _successDemoteMemberId;
  String? get successDemoteMemberId => _successDemoteMemberId;

  String? _failedDemoteMemberId;
  String? get failedDemoteMemberId => _failedDemoteMemberId;

  String? _groupId;
  String? get groupId => _groupId;

  String? _userId;
  String? get userId => _userId;

  String? _userName;
  String? get userName => _userName;

  bool get isUserMemberOfGroup {
    if (_userId == null) return false;
    if (_hasLeftGroup) return false;
    if (_groupDetails == null || _groupDetails!['members'] == null) {
      return true;
    }
    return _checkIsUserMemberOfGroup();
  }

  bool _checkIsUserMemberOfGroup() {
    if (_userId == null) return false;
    if (_groupDetails == null || _groupDetails!['members'] == null) {
      return false;
    }
    final dynamic groupMembers = _groupDetails!['members'];
    if (groupMembers is List) {
      for (final dynamic memberItem in groupMembers) {
        if (memberItem is Map) {
          final dynamic userVal = memberItem['user_id'];
          String memberId = "";
          if (userVal is Map) {
            memberId = (userVal['_id'] ?? userVal['id'] ?? "").toString();
          } else if (userVal != null) {
            memberId = userVal.toString();
          }
          if (memberId == _userId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Map<String, dynamic>? _selectedReplyMessage;
  Map<String, dynamic>? get selectedReplyMessage => _selectedReplyMessage;

  void selectReplyMessage(Map<String, dynamic>? message) {
    _selectedReplyMessage = message;
    notifyListeners();
  }

  void scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScroll(immediate, 0);
    });
  }

  void _performScroll(bool immediate, int retryCount) {
    if (_isDisposed) return;
    if (!scrollController.hasClients) {
      if (retryCount < 10) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _performScroll(immediate, retryCount + 1);
        });
      }
      return;
    }

    try {
      if (immediate) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
      } else {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
  }

  Future<void> init(String groupId, {bool isFavorite = false}) async {
    _groupId = groupId;
    _isFavorite = isFavorite;
    _hasLeftGroup = false;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
        _userName = user.name;
        if (user.chatWallpaper != null && user.chatWallpaper!.isNotEmpty) {
          fetchSelectedWallpaper(user.chatWallpaper!);
        }
      }
    } catch (_) {}

    _isLoading = true;
    notifyListeners();

    await fetchGroupDetails(groupId);
    await fetchChatHistory(groupId);

    _isLoading = false;
    notifyListeners();
    scrollToBottom(immediate: true);

    // Setup periodic polling for real-time updates when other users leave or new messages arrive
    _refreshTimer?.cancel();
    int tickCount = 0;
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed ||
          _groupId == null ||
          _hasLeftGroup ||
          !_checkIsUserMemberOfGroup()) {
        timer.cancel();
        return;
      }
      tickCount++;
      // Poll chat history every 5 seconds, but poll group details only every 30 seconds (every 6th tick)
      if (tickCount % 6 == 0) {
        fetchGroupDetails(_groupId!, silent: true);
      }
      fetchChatHistory(_groupId!, silent: true);
    });
  }

  Future<void> fetchSelectedWallpaper(String id) async {
    try {
      final response = await ApiService().get('/admin/wallpapers/$id');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];
        _wallpaperUrl = data['wallpaper_image'] as String?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching selected wallpaper: $e");
    }
  }

  Future<void> fetchGroupDetails(String groupId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final response = await ApiService().get('/groups/$groupId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final Map<String, dynamic> data = json['data'] ?? {};
        _groupDetails = data;
        _hasLeftGroup = _hasLeftGroup || !_checkIsUserMemberOfGroup();
      } else {
        _hasLeftGroup = true;
      }
    } catch (e) {
      debugPrint("Error fetching group details: $e");
      _hasLeftGroup = true;
    }

    // Fallback/Default template if _groupDetails is null or missing members
    if (_groupDetails == null || _groupDetails!['members'] == null) {
      _groupDetails ??= {};
      _groupDetails!['name'] ??= "Project Shield";
      _groupDetails!['description'] ??=
          "Collaborative space for the Project Shield design and development team. 🛡️";
      _groupDetails!['avatar'] ??=
          "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200";
      _groupDetails!['admin'] ??= "You";
      _groupDetails!['memberCount'] ??= 5;
      _groupDetails!['onlineCount'] ??= 3;
      _groupDetails!['members'] ??= [
        {
          "name": "You",
          "role": "Admin",
          "avatar": "assets/images/user_avatar.png",
        },
        {
          "name": "Alice Johnson",
          "role": "Member",
          "avatar": "assets/images/obchild1.png",
        },
        {
          "name": "Bob Wilson",
          "role": "Member",
          "avatar": "assets/images/obchild2.png",
        },
        {
          "name": "Charlie Day",
          "role": "Member",
          "avatar": "assets/images/maisie_avatar.png",
        },
        {
          "name": "Dave Smith",
          "role": "Member",
          "avatar": "assets/images/obchild1.png",
        },
      ];
      _groupDetails!['medias'] ??= [
        "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
        "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
        "https://images.unsplash.com/photo-1518770660439-4636190af475?w=200",
      ];
    }
    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _connectedUsers = [];
  List<Map<String, dynamic>> get connectedUsers => _connectedUsers;

  Future<void> fetchConnectedUsers() async {
    if (_userId == null) return;
    _isLoading = true;
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
          return {
            "id": friend['user_id']?.toString() ?? "",
            "name": friend['name']?.toString() ?? "Unknown",
            "subtitle":
                friend['email']?.toString() ??
                (friend['bio']?.toString() ?? "Hey there!"),
            "avatar": friend['avatar']?.toString() ?? "",
            "isSelected": false,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching connected users: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGroupMembers(
    String groupId,
    String requesterId,
    List<String> userIds,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService().post(
        '/groups/$groupId/members',
        data: {"requesterId": requesterId, "userIds": userIds},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchGroupDetails(groupId);
        await fetchChatHistory(groupId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding group members: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMember(String userId) async {
    // Mock add member
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<bool> removeMember(String targetUserId) async {
    if (_groupId == null || _userId == null) return false;
    _removingMemberId = targetUserId;
    _failedMemberId = null;
    notifyListeners();

    bool success = false;
    try {
      // Find target name before delete succeeds and member is removed from the roster
      final String targetName =
          (_groupDetails?['members'] as List?)
              ?.firstWhere(
                (m) =>
                    (m['user_id'] is Map ? m['user_id']['_id'] : m['user_id'])
                        ?.toString() ==
                    targetUserId,
                orElse: () => null,
              )?['name']
              ?.toString() ??
          "A member";

      final response = await ApiService().delete(
        '/groups/$_groupId/members/$targetUserId',
        data: {"requesterId": _userId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        // Send a system message about member being removed
        try {
          await ApiService().post(
            '/chat/send',
            data: {
              "senderId": _userId,
              "groupId": _groupId,
              "content": "system_member_removed:$targetUserId:$targetName",
              "message_type": "system",
            },
          );
        } catch (e) {
          debugPrint("Error sending system removal message: $e");
        }
        await fetchGroupDetails(_groupId!);
        await fetchChatHistory(_groupId!);
        success = true;
      }
    } catch (e) {
      debugPrint("Error removing member: $e");
    } finally {
      _removingMemberId = null;
      if (!success) {
        _failedMemberId = targetUserId;
        Future.delayed(const Duration(seconds: 3), () {
          if (_failedMemberId == targetUserId) {
            _failedMemberId = null;
            notifyListeners();
          }
        });
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> makeMemberAdmin(String targetUserId) async {
    if (_groupId == null || _userId == null) return false;
    _makingAdminMemberId = targetUserId;
    _successAdminMemberId = null;
    _failedAdminMemberId = null;
    notifyListeners();

    bool success = false;
    try {
      final response = await ApiService().put(
        '/groups/$_groupId/members/$targetUserId/role',
        data: {"requesterId": _userId, "role": "admin"},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _makingAdminMemberId = null;
        _successAdminMemberId = targetUserId;
        notifyListeners();

        await fetchGroupDetails(_groupId!);
        await fetchChatHistory(_groupId!);
        success = true;
      }
    } catch (e) {
      debugPrint("Error making member admin: $e");
    } finally {
      _makingAdminMemberId = null;
      if (success) {
        _successAdminMemberId = targetUserId;
        Future.delayed(const Duration(seconds: 2), () {
          if (_successAdminMemberId == targetUserId) {
            _successAdminMemberId = null;
            notifyListeners();
          }
        });
      } else {
        _failedAdminMemberId = targetUserId;
        Future.delayed(const Duration(seconds: 3), () {
          if (_failedAdminMemberId == targetUserId) {
            _failedAdminMemberId = null;
            notifyListeners();
          }
        });
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> demoteAdminToMember(String targetUserId) async {
    if (_groupId == null || _userId == null) return false;
    _demotingAdminMemberId = targetUserId;
    _successDemoteMemberId = null;
    _failedDemoteMemberId = null;
    notifyListeners();

    bool success = false;
    try {
      final response = await ApiService().put(
        '/groups/$_groupId/members/$targetUserId/role',
        data: {"requesterId": _userId, "role": "member"},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _demotingAdminMemberId = null;
        _successDemoteMemberId = targetUserId;
        notifyListeners();

        await fetchGroupDetails(_groupId!);
        await fetchChatHistory(_groupId!);
        success = true;
      }
    } catch (e) {
      debugPrint("Error demoting admin to member: $e");
    } finally {
      _demotingAdminMemberId = null;
      if (success) {
        _successDemoteMemberId = targetUserId;
        Future.delayed(const Duration(seconds: 3), () {
          if (_successDemoteMemberId == targetUserId) {
            _successDemoteMemberId = null;
            notifyListeners();
          }
        });
      } else {
        _failedDemoteMemberId = targetUserId;
        Future.delayed(const Duration(seconds: 3), () {
          if (_failedDemoteMemberId == targetUserId) {
            _failedDemoteMemberId = null;
            notifyListeners();
          }
        });
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> editGroup({
    required String name,
    required String description,
    String? imagePath,
  }) async {
    if (_groupId == null || _userId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> fields = {
        "requesterId": _userId,
        "name": name,
        "description": description,
      };

      final FormData formData = FormData.fromMap(fields);

      if (imagePath != null && imagePath.isNotEmpty) {
        final String filename = imagePath.split('/').last;
        formData.files.add(
          MapEntry(
            "group_image",
            await MultipartFile.fromFile(imagePath, filename: filename),
          ),
        );
      }

      final response = await ApiService().put(
        '/groups/$_groupId',
        data: formData,
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchGroupDetails(_groupId!);
        await fetchChatHistory(_groupId!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error editing group: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    if (_userId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Post a system message for leaving the group before executing the delete
      try {
        final String leavingName =
            _userName ??
            (_groupDetails?['members'] as List?)
                ?.firstWhere(
                  (m) =>
                      (m['user_id'] is Map ? m['user_id']['_id'] : m['user_id'])
                          ?.toString() ==
                      _userId,
                  orElse: () => null,
                )?['name']
                ?.toString() ??
            "A member";

        await ApiService().post(
          '/chat/send',
          data: {
            "senderId": _userId,
            "groupId": groupId,
            "content": "system_member_left:$_userId:$leavingName",
            "message_type": "system",
          },
        );
      } catch (e) {
        debugPrint("Error sending system leave message: $e");
      }

      // 2. Call the leave group API
      final response = await ApiService().delete(
        '/groups/$groupId/leave',
        data: {"userId": _userId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _hasLeftGroup = true;
        if (_groupDetails != null && _groupDetails!['members'] is List) {
          final List membersList = List.from(_groupDetails!['members']);
          membersList.removeWhere((memberItem) {
            if (memberItem is Map) {
              final dynamic userVal = memberItem['user_id'];
              String memberId = "";
              if (userVal is Map) {
                memberId = (userVal['_id'] ?? userVal['id'] ?? "").toString();
              } else if (userVal != null) {
                memberId = userVal.toString();
              }
              return memberId == _userId;
            }
            return false;
          });
          _groupDetails!['members'] = membersList;
        }
        await fetchGroupDetails(groupId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error leaving group: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    if (_userId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().delete(
        '/groups/$groupId',
        data: {"requesterId": _userId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _hasLeftGroup = true;
        _groupDetails = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting group: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChatHistory(String groupId, {bool silent = false}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) return;

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? userId = user.id;
      if (userId == null) return;

      final response = await ApiService().get(
        '/chat/history?group_id=$groupId&requesterId=$userId&page=1&limit=20',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _messages = data
            .map((item) {
              final Map<String, dynamic> msgMap = item as Map<String, dynamic>;
              final dynamic senderObj = msgMap['sender_id'];
              String senderName = "Unknown";
              String? senderAvatar;
              String senderIdVal = "";

              if (senderObj is Map<String, dynamic>) {
                senderName = senderObj['name']?.toString() ?? "Unknown";
                senderAvatar = senderObj['avatar']?.toString();
                senderIdVal =
                    senderObj['_id']?.toString() ??
                    senderObj['id']?.toString() ??
                    "";
              } else if (senderObj is String) {
                senderIdVal = senderObj;
                if (senderIdVal == userId) {
                  senderName = "You";
                }
              }

              final bool isOutgoing = senderIdVal == userId;

              // Convert backend date to dynamic time string e.g. "10:00 am"
              String timeStr = "";
              if (msgMap['created_at'] != null) {
                try {
                  final DateTime dt = DateTime.parse(
                    msgMap['created_at'].toString(),
                  ).toLocal();
                  final int hour = dt.hour > 12
                      ? dt.hour - 12
                      : (dt.hour == 0 ? 12 : dt.hour);
                  final String ampm = dt.hour >= 12 ? "pm" : "am";
                  final String minuteStr = dt.minute < 10
                      ? "0${dt.minute}"
                      : "${dt.minute}";
                  timeStr = "$hour:$minuteStr $ampm";
                } catch (_) {}
              }

              final String? parentMessageId = msgMap['parent_message_id'] is Map
                  ? msgMap['parent_message_id']['_id']?.toString()
                  : msgMap['parent_message_id']?.toString();
              String? replyTo;
              String? replyToSender;

              if (msgMap['parent_message_id'] is Map) {
                replyTo = msgMap['parent_message_id']['content']?.toString();
                final dynamic pSender =
                    msgMap['parent_message_id']['sender_id'];
                if (pSender is Map) {
                  replyToSender = pSender['name']?.toString();
                } else if (pSender?.toString() == userId) {
                  replyToSender = "You";
                }
              }

              if (parentMessageId != null && replyTo == null) {
                // Self-healing lookup in current list of messages
                final parentMsg = data.firstWhere(
                  (item) =>
                      (item['_id']?.toString() ?? item['id']?.toString()) ==
                      parentMessageId,
                  orElse: () => null,
                );
                if (parentMsg != null) {
                  replyTo =
                      parentMsg['content']?.toString() ??
                      parentMsg['text']?.toString();
                  final pSender = parentMsg['sender_id'];
                  if (pSender is Map) {
                    replyToSender = pSender['name']?.toString();
                  } else if (pSender?.toString() == userId) {
                    replyToSender = "You";
                  }
                }
              }

              return {
                "id":
                    msgMap['_id']?.toString() ?? msgMap['id']?.toString() ?? "",
                "sender": isOutgoing ? "You" : senderName,
                "text": msgMap['content']?.toString() ?? "",
                "time": timeStr,
                "isOutgoing": isOutgoing,
                "type": msgMap['message_type']?.toString() ?? "text",
                "file_name": msgMap['file_name']?.toString(),
                "url": msgMap['file_url'] != null
                    ? ApiService.getImageUrl(msgMap['file_url'].toString())
                    : null,
                "avatar": senderAvatar ?? "",
                "moderation_status":
                    msgMap['moderation_status']?.toString() ?? "Approved",
                "createdAt": msgMap['created_at']?.toString(),
                "parent_message_id": parentMessageId,
                "replyTo": replyTo,
                "replyToSender": replyToSender,
                "is_forwarded": msgMap['is_forwarded'] as bool? ?? false,
              };
            })
            .toList()
            .reversed
            .toList();

        // Synthesize missing system_member_added messages for other members
        if (_groupDetails != null && _groupDetails!['members'] != null) {
          final dynamic groupMembers = _groupDetails!['members'];
          if (groupMembers is List) {
            final dynamic adminVal = _groupDetails!['admin_id'];
            final String? adminIdStr = adminVal is Map
                ? (adminVal['_id']?.toString() ?? adminVal['id']?.toString())
                : adminVal?.toString();

            for (final dynamic memberItem in groupMembers) {
              if (memberItem is Map) {
                final String role =
                    memberItem['role']?.toString().toLowerCase() ?? "member";
                // Skip creator/admin who created the group (they didn't get "added" later)
                if (role == 'creator') continue;

                final dynamic userVal = memberItem['user_id'];
                String memberId = "";
                String memberName = "A member";

                if (userVal is Map) {
                  memberId =
                      userVal['_id']?.toString() ??
                      userVal['id']?.toString() ??
                      "";
                  memberName = userVal['name']?.toString() ?? "A member";
                } else if (userVal is String) {
                  memberId = userVal;
                  memberName = memberItem['name']?.toString() ?? "A member";
                }

                if (memberId.isEmpty) continue;
                // Also skip creator based on admin_id comparison
                if (adminIdStr != null && memberId == adminIdStr) continue;

                // Check if we already have a system_member_added message in the list
                bool alreadyHasMessage = false;
                for (final msg in _messages) {
                  final String msgType = msg['type']?.toString() ?? "";
                  final String msgText = msg['text']?.toString() ?? "";
                  if ((msgType == 'system' || msgType == 'status') &&
                      msgText.startsWith("system_member_added:") &&
                      (msgText.contains(memberId) ||
                          msgText.contains(memberName))) {
                    alreadyHasMessage = true;
                    break;
                  }
                }

                if (!alreadyHasMessage) {
                  final String? joinedAtStr =
                      memberItem['joined_at']?.toString() ??
                      memberItem['joinedAt']?.toString();
                  if (joinedAtStr != null) {
                    try {
                      final DateTime joinedAtDt = DateTime.parse(
                        joinedAtStr,
                      ).toLocal();
                      final int hour = joinedAtDt.hour > 12
                          ? joinedAtDt.hour - 12
                          : (joinedAtDt.hour == 0 ? 12 : joinedAtDt.hour);
                      final String ampm = joinedAtDt.hour >= 12 ? "pm" : "am";
                      final String minuteStr = joinedAtDt.minute < 10
                          ? "0${joinedAtDt.minute}"
                          : "${joinedAtDt.minute}";
                      final String timeStr = "$hour:$minuteStr $ampm";

                      _messages.add({
                        "id": "virtual_added_$memberId",
                        "sender": "System",
                        "text": "system_member_added:$memberId:$memberName",
                        "time": timeStr,
                        "isOutgoing": false,
                        "type": "system",
                        "avatar": "",
                        "moderation_status": "Approved",
                        "createdAt": joinedAtStr,
                        "parent_message_id": null,
                        "replyTo": null,
                        "replyToSender": null,
                        "is_forwarded": false,
                      });
                    } catch (_) {}
                  }
                }
              }
            }
          }

          // Sort all messages chronologically by createdAt
          _messages.sort((a, b) {
            final String? ca = a['createdAt'];
            final String? cb = b['createdAt'];
            if (ca == null && cb == null) return 0;
            if (ca == null) return -1;
            if (cb == null) return 1;
            return ca.compareTo(cb);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching group chat history: $e");
    }
    notifyListeners();
    if (!silent) {
      scrollToBottom(immediate: true);
    } else {
      if (scrollController.hasClients) {
        final double maxScroll = scrollController.position.maxScrollExtent;
        final double currentScroll = scrollController.position.pixels;
        if (maxScroll - currentScroll < 100) {
          scrollToBottom();
        }
      }
    }
  }

  Future<void> sendMessage() async {
    final String content = messageController.text.trim();
    if (content.isEmpty) return;
    if (_userId == null || _groupId == null) return;

    final String? parentMsgId = _selectedReplyMessage?["id"]?.toString();
    _selectedReplyMessage = null;

    messageController.clear();
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/chat/send',
        data: {
          "senderId": _userId,
          "groupId": _groupId,
          "content": content,
          if (parentMsgId != null) "parentMessageId": parentMsgId,
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchChatHistory(_groupId!);
      }
    } catch (e) {
      debugPrint("Error sending group message: $e");
    }
    notifyListeners();
    scrollToBottom();
  }

  Future<void> sendMediaMessage(
    String filePath,
    String fileName,
    String messageType, {
    String? content,
  }) async {
    if (_userId == null || _groupId == null) return;
    try {
      final formData = FormData.fromMap({
        "senderId": _userId,
        "groupId": _groupId,
        "content": content ?? "Shared a $messageType",
        "message_type": messageType,
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await ApiService().post('/chat/send', data: formData);
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      debugPrint("sendMediaMessage group API response: $json");

      if (json['success'] == true ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        await fetchChatHistory(_groupId!);
      } else {
        debugPrint(
          "sendMediaMessage group failed with status code ${response.statusCode}: $json",
        );
      }
    } catch (e) {
      debugPrint("Error sending group media message: $e");
    }
  }

  Future<File> compressFileIfNeeded(File file, String extension) async {
    final extLower = extension.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extLower);
    if (isImage) {
      try {
        final bytes = await file.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 800,
        );
        final ui.FrameInfo fi = await codec.getNextFrame();
        final ui.Image uiImage = fi.image;
        final byteData = await uiImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          final compressedBytes = byteData.buffer.asUint8List();
          final String newPath =
              '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final compressedFile = File(newPath);
          await compressedFile.writeAsBytes(compressedBytes);
          debugPrint(
            "Compressed group image from ${bytes.length} to ${compressedBytes.length} bytes",
          );
          return compressedFile;
        }
      } catch (e) {
        debugPrint("Error compressing group image: $e");
      }
    }
    return file;
  }

  Future<void> pickMedia() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? media = await picker.pickMedia();
      if (media != null) {
        String path = media.path;
        final String name = media.name;
        final String extension = path.split('.').last.toLowerCase();

        String messageType = 'image';
        String content = '';
        if (['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(extension)) {
          messageType = 'video';
          content = '';
        } else {
          final File originalFile = File(path);
          final File compressedFile = await compressFileIfNeeded(
            originalFile,
            extension,
          );
          path = compressedFile.path;
        }

        await sendMediaMessage(path, name, messageType, content: content);
      }
    } catch (e) {
      debugPrint("Error picking group media: $e");
    }
  }

  Future<void> pickCameraMedia({required BuildContext context}) async {
    try {
      final ImagePicker picker = ImagePicker();

      final String? choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColor(context).grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Capture Media",
                style: fontStyle.clashDisplayBold18.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'photo'),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: appColor(
                              context,
                            ).secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: appColor(context).secondary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Take Photo",
                          style: fontStyle.clashDisplayMedium14.textColor(
                            appColor(context).black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'video'),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: appColor(
                              context,
                            ).secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.videocam_rounded,
                            color: appColor(context).secondary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Record Video",
                          style: fontStyle.clashDisplayMedium14.textColor(
                            appColor(context).black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (choice == null) return;

      XFile? capturedFile;
      if (choice == 'photo') {
        capturedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
      } else if (choice == 'video') {
        capturedFile = await picker.pickVideo(source: ImageSource.camera);
      }

      if (capturedFile != null) {
        String path = capturedFile.path;
        final String name = capturedFile.name;
        final String extension = path.split('.').last.toLowerCase();

        String messageType = 'image';
        String content = '';
        if (choice == 'video') {
          messageType = 'video';
        } else {
          final File originalFile = File(path);
          final File compressedFile = await compressFileIfNeeded(
            originalFile,
            extension,
          );
          path = compressedFile.path;
        }

        await sendMediaMessage(path, name, messageType, content: content);
      }
    } catch (e) {
      debugPrint("Error capturing camera media: $e");
    }
  }

  Future<void> pickDocument({BuildContext? context}) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        final String name = result.files.single.name;
        final String extension = path.split('.').last.toLowerCase();

        final File originalFile = File(path);
        final File compressedFile = await compressFileIfNeeded(
          originalFile,
          extension,
        );
        path = compressedFile.path;

        await sendMediaMessage(
          path,
          name,
          "file",
          content: "Shared a document: $name",
        );
      }
    } catch (e) {
      debugPrint("Error picking group document: $e");
      if (context != null && context.mounted) {
        // ToastHelper.showToast(
        //   context,
        //   "Plugin not initialized. Please rebuild the app (full restart/run).",
        // );
      }
    }
  }

  Future<void> recordAudio() async {
    try {
      final tempFile = File(
        '${Directory.systemTemp.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await tempFile.writeAsBytes(List.generate(100, (i) => i));
      await sendMediaMessage(
        tempFile.path,
        "voice_message.mp3",
        "audio",
        content: "Voice Message",
      );
    } catch (e) {
      debugPrint("Error recording group audio: $e");
    }
  }

  Future<void> sendLocation() async {
    final String content = "Location: Lat 34.0522, Lng -118.2437";
    if (_userId == null || _groupId == null) return;
    try {
      final response = await ApiService().post(
        '/chat/send',
        data: {
          "senderId": _userId,
          "groupId": _groupId,
          "content": content,
          "message_type": "text",
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchChatHistory(_groupId!);
      }
    } catch (e) {
      debugPrint("Error sending group location: $e");
    }
    notifyListeners();
    scrollToBottom();
  }

  void editMessage(int index, String newText) {
    if (index >= 0 && index < _messages.length) {
      _messages[index]["text"] = newText;
      _messages[index]["isEdited"] = true;
      notifyListeners();
    }
  }

  void deleteForMe(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }

  void deleteForEveryone(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages[index]["text"] = "This message was deleted";
      _messages[index]["isDeleted"] = true;
      _messages[index]["type"] = "text";
      notifyListeners();
    }
  }

  Future<void> deleteForMeApi(BuildContext context, String messageId) async {
    if (_userId == null) return;
    try {
      final response = await ApiService().put(
        '/chat/message/$messageId/delete-me',
        data: {"userId": _userId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _messages.removeWhere((msg) => msg['id'] == messageId);
        if (context.mounted) {
          ToastHelper.showToast(context, "Message deleted for you");
        }
        notifyListeners();
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context,
            json['message']?.toString() ?? "Failed to delete message",
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting message for me: $e");
      if (context.mounted) {
        ToastHelper.showToast(context, "Error: $e");
      }
    }
  }

  Future<void> deleteForEveryoneApi(
    BuildContext context,
    String messageId,
  ) async {
    if (_userId == null) return;
    try {
      final response = await ApiService().put(
        '/chat/message/$messageId/delete-everyone',
        data: {"userId": _userId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        for (var msg in _messages) {
          if (msg['id'] == messageId) {
            msg["text"] = "This message was deleted";
            msg["isDeleted"] = true;
            msg["type"] = "text";
            break;
          }
        }
        if (context.mounted) {
          ToastHelper.showToast(context, "Message deleted for everyone");
        }
        notifyListeners();
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context,
            json['message']?.toString() ?? "Failed to delete message",
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting message for everyone: $e");
      if (context.mounted) {
        ToastHelper.showToast(context, "Error: $e");
      }
    }
  }

  Future<void> editMessageApi(
    BuildContext context,
    String messageId,
    String newText,
  ) async {
    if (_userId == null) return;
    try {
      final response = await ApiService().put(
        '/chat/message/$messageId/edit',
        data: {"userId": _userId, "content": newText},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        for (var msg in _messages) {
          if (msg['id'] == messageId) {
            msg["text"] = newText;
            msg["isEdited"] = true;
            break;
          }
        }
        if (context.mounted) {
          ToastHelper.showToast(context, "Message edited successfully");
        }
        notifyListeners();
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context,
            json['message']?.toString() ?? "Failed to edit message",
          );
        }
      }
    } catch (e) {
      debugPrint("Error editing message: $e");
      if (context.mounted) {
        ToastHelper.showToast(context, "Error: $e");
      }
    }
  }

  void replyToMessage(int index, String replyText) {
    if (index >= 0 && index < _messages.length) {
      final replyMessage = {
        "sender": "You",
        "text": replyText,
        "time": "Now",
        "isOutgoing": true,
        "type": "text",
        "replyTo": _messages[index]["text"],
        "replyToSender": _messages[index]["sender"],
      };
      _messages.add(replyMessage);
      notifyListeners();
      scrollToBottom();
    }
  }

  Future<void> forwardMessage(int index, List<String> targetGroupIds) async {
    // Mock forwarding
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  Future<bool> clearChat() async {
    if (_userId == null || _groupId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/clear',
        data: {"userId": _userId, "groupId": _groupId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          json['success'] == true) {
        _messages.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error clearing group chat: $e");
      return false;
    }
  }

  Future<bool> deleteChat() async {
    if (_userId == null || _groupId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/delete',
        data: {"userId": _userId, "recipientId": _groupId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        _messages.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting group chat: $e");
      return false;
    }
  }

  Future<void> reportGroup(String groupId, String reason) async {
    // Mock report
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Map<String, dynamic> getMessageInfo(int index) {
    if (index >= 0 && index < _messages.length) {
      return {
        "sentAt": "09:50 AM",
        "deliveredTo": ["Alice", "Bob", "Charlie"],
        "readBy": ["Alice", "Bob"],
      };
    }
    return {};
  }

  List<String> getMockEmojis() {
    return [
      "🔥",
      "🚀",
      "💡",
      "✅",
      "🎉",
      "👍",
      "🙌",
      "💯",
      "🎯",
      "✨",
      "🎈",
      "🌟",
    ];
  }

  List<dynamic> _stickers = [];
  List<dynamic> get stickers => _stickers;

  bool _isLoadingStickers = false;
  bool get isLoadingStickers => _isLoadingStickers;

  Future<void> fetchStickers() async {
    if (_stickers.isNotEmpty) return;
    _isLoadingStickers = true;
    notifyListeners();

    try {
      final response = await ApiService().get(
        '/admin/stickers?status=Active&page=1&limit=20',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        if (json['data'] != null && json['data'] is List) {
          _stickers = List<dynamic>.from(json['data']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching stickers: $e");
    } finally {
      _isLoadingStickers = false;
      notifyListeners();
    }
  }

  Future<void> sendStickerMessage(String stickerPath) async {
    if (_userId == null || _groupId == null) return;
    final String? parentMsgId = _selectedReplyMessage?["id"]?.toString();
    _selectedReplyMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/chat/send',
        data: {
          "senderId": _userId,
          "message_type": "sticker",
          "file_url": stickerPath,
          "groupId": _groupId,
          if (parentMsgId != null) "parentMessageId": parentMsgId,
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        await fetchChatHistory(_groupId!);
      }
    } catch (e) {
      debugPrint("Error sending group sticker message: $e");
    }
    notifyListeners();
    scrollToBottom();
  }

  Future<bool> toggleFavorite(bool isFavorite) async {
    if (_userId == null || _groupId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/favorite',
        data: {"userId": _userId, "chatId": _groupId, "isFavorite": isFavorite},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _isFavorite = isFavorite;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error toggling favorite group chat: $e");
      return false;
    }
  }

  Future<bool> archiveChat() async {
    if (_userId == null || _groupId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/archive',
        data: {"userId": _userId, "chatId": _groupId, "type": "group"},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint("Error archiving group chat: $e");
      return false;
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
