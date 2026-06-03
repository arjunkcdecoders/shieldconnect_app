import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/message_model.dart';
import 'package:shieldconnect_app/model/friend_model.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/settings_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/view/media_caption_screen.dart';
import 'package:record/record.dart';

class PersonalChatController extends ChangeNotifier {
  bool _isDisposed = false;

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

  Map<String, dynamic>? _personalDetails;
  Map<String, dynamic>? get personalDetails => _personalDetails;

  Map<String, dynamic>? _headerDetails;
  Map<String, dynamic>? get headerDetails => _headerDetails;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isContactInfoLoading = false;
  bool get isContactInfoLoading => _isContactInfoLoading;

  String? _wallpaperUrl;
  String? get wallpaperUrl => _wallpaperUrl;

  String? _userName;
  String? get userName => _userName;

  bool _isRecipientTyping = false;
  bool get isRecipientTyping => _isRecipientTyping;

  DateTime? _lastTypingEmit;
  Timer? _stopTypingTimer;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? _userId;
  String? get userId => _userId;

  String? _recipientId;
  String? get recipientId => _recipientId;

  bool _isRequest = false;
  bool get isRequest => _isRequest;

  bool _isNewChat = false;
  bool get isNewChat => _isNewChat;

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  String? _relationshipStatus;
  String? get relationshipStatus => _relationshipStatus;

  String? _requestedBy;
  String? get requestedBy => _requestedBy;

  List<String> _blockedBy = [];
  List<String> get blockedBy => _blockedBy;

  bool _isResponding = false;
  bool get isResponding => _isResponding;

  String? _respondingAction;
  String? get respondingAction => _respondingAction;

  String? _unblockError;
  String? get unblockError => _unblockError;

  Map<String, dynamic>? _selectedReplyMessage;
  Map<String, dynamic>? get selectedReplyMessage => _selectedReplyMessage;

  void selectReplyMessage(Map<String, dynamic>? message) {
    _selectedReplyMessage = message;
    notifyListeners();
  }

  bool _isAttachmentOpen = false;
  bool get isAttachmentOpen => _isAttachmentOpen;

  void setAttachmentOpen(bool open) {
    _isAttachmentOpen = open;
    notifyListeners();
  }

  void toggleAttachmentOpen() {
    _isAttachmentOpen = !_isAttachmentOpen;
    notifyListeners();
  }

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  VoidCallback? onCancelRecording;

  void setRecordingState(bool recording) {
    _isRecording = recording;
    notifyListeners();
  }

  set isRecording(bool val) {
    _isRecording = val;
    notifyListeners();
  }

  bool isRecordingPaused = false;
  int recordingSeconds = 0;
  int recordingTicks = 0;
  Timer? recordingTimer;
  AudioRecorder? audioRecorder;
  String? recordedFilePath;

  bool _isSearchActive = false;
  bool get isSearchActive => _isSearchActive;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  List<String> _searchMatchMessageIds = [];
  List<String> get searchMatchMessageIds => _searchMatchMessageIds;

  int _currentSearchMatchIndex = -1;
  int get currentSearchMatchIndex => _currentSearchMatchIndex;

  String? get currentMatchedMessageId {
    if (_currentSearchMatchIndex >= 0 &&
        _currentSearchMatchIndex < _searchMatchMessageIds.length) {
      return _searchMatchMessageIds[_currentSearchMatchIndex];
    }
    return null;
  }

  void toggleSearchActive(bool active) {
    _isSearchActive = active;
    if (!active) {
      _searchQuery = "";
      _searchMatchMessageIds.clear();
      _currentSearchMatchIndex = -1;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchMatchMessageIds.clear();
    _currentSearchMatchIndex = -1;

    if (query.isNotEmpty) {
      for (final msg in _messages) {
        final String text = msg['text']?.toString() ?? "";
        final String type = msg['type']?.toString() ?? "text";
        final String modStatus = msg['moderation_status'] ?? 'Approved';
        final bool isDeleted = msg['isDeleted'] == true;
        if (type != 'system' &&
            type != 'status' &&
            !isDeleted &&
            modStatus == 'Approved' &&
            text.toLowerCase().contains(query.toLowerCase())) {
          final String? idStr = msg['id']?.toString();
          if (idStr != null && idStr.isNotEmpty) {
            _searchMatchMessageIds.add(idStr);
          }
        }
      }

      if (_searchMatchMessageIds.isNotEmpty) {
        _currentSearchMatchIndex = _searchMatchMessageIds.length - 1;
      }
    }
    notifyListeners();
  }

  void nextSearchMatch() {
    if (_searchMatchMessageIds.isEmpty) return;
    if (_currentSearchMatchIndex < _searchMatchMessageIds.length - 1) {
      _currentSearchMatchIndex++;
    } else {
      _currentSearchMatchIndex = 0;
    }
    notifyListeners();
  }

  void prevSearchMatch() {
    if (_searchMatchMessageIds.isEmpty) return;
    if (_currentSearchMatchIndex > 0) {
      _currentSearchMatchIndex--;
    } else {
      _currentSearchMatchIndex = _searchMatchMessageIds.length - 1;
    }
    notifyListeners();
  }

  Map<String, dynamic> _unwrapMessagePayload(Map<String, dynamic> rawMsg) {
    if (rawMsg['message'] != null && rawMsg['message'] is Map) {
      return Map<String, dynamic>.from(rawMsg['message'] as Map);
    } else if (rawMsg['data'] != null && rawMsg['data'] is Map) {
      final dataMap = rawMsg['data'] as Map;
      if (dataMap['message'] != null && dataMap['message'] is Map) {
        return Map<String, dynamic>.from(dataMap['message'] as Map);
      } else {
        return Map<String, dynamic>.from(dataMap);
      }
    }
    return rawMsg;
  }

  void _onMessageQueueChanged() {
    if (_isDisposed) return;
    final queue = SocketService().messageQueueNotifier.value;
    if (queue.isEmpty) return;

    final toProcess = List<Map<String, dynamic>>.from(queue);
    // Drain/clear the queue
    SocketService().messageQueueNotifier.value = [];

    debugPrint(
      "PersonalChatController: received real-time messages: $toProcess",
    );

    bool hasNewMsg = false;
    for (final rawMsg in toProcess) {
      final unwrapped = _unwrapMessagePayload(rawMsg);
      final messageModel = MessageModel.fromJson(unwrapped);

      final msgSenderId = messageModel.senderId;
      final msgRecipientId = messageModel.recipientId;

      if ((msgSenderId == _recipientId && msgRecipientId == _userId) ||
          (msgSenderId == _userId && msgRecipientId == _recipientId)) {
        final bool isOutgoing = msgSenderId == _userId;
        final String senderName = isOutgoing
            ? "You"
            : (_headerDetails?["name"] ?? "Sender");

        final String? parentMessageId = messageModel.parentMessageId;
        String? replyTo;
        String? replyToSender;
        String? replyToType;
        String? replyToUrl;

        if (messageModel.parentMessage != null) {
          replyTo = messageModel.parentMessage!.content;
          replyToSender = messageModel.parentMessage!.senderId == _userId
              ? "You"
              : (_headerDetails?["name"] ?? "Sender");
          replyToType = messageModel.parentMessage!.messageType;
          replyToUrl = messageModel.parentMessage!.fileUrl != null
              ? ApiService.getImageUrl(messageModel.parentMessage!.fileUrl!)
              : null;
        } else if (parentMessageId != null) {
          final parentMsg = _messages.firstWhere(
            (item) =>
                (item['id']?.toString() ?? item['_id']?.toString()) ==
                parentMessageId,
            orElse: () => <String, dynamic>{},
          );
          if (parentMsg.isNotEmpty) {
            replyTo = parentMsg['text']?.toString() ?? parentMsg['content']?.toString();
            replyToType = parentMsg['type']?.toString() ?? parentMsg['message_type']?.toString();
            replyToUrl = parentMsg['url']?.toString() ?? parentMsg['file_url']?.toString();
            replyToSender = parentMsg['sender']?.toString();
          }
        }

        final bool isDeleted = messageModel.isDeletedForEveryone ?? false;
        final newMsgMap = {
          "id": messageModel.id,
          "sender": senderName,
          "text": isDeleted ? "This message was deleted" : (messageModel.content ?? ''),
          "time": messageModel.createdAt != null
              ? DateHelper.formatTime(messageModel.createdAt!.toIso8601String())
              : 'Now',
          "createdAt": messageModel.createdAt != null
              ? messageModel.createdAt!.toIso8601String()
              : DateTime.now().toIso8601String(),
          "isOutgoing": isOutgoing,
          "type": isDeleted ? "text" : (messageModel.messageType ?? 'text'),
          "file_name": isDeleted ? null : messageModel.fileName,
          "url": (isDeleted || messageModel.fileUrl == null)
              ? null
              : ApiService.getImageUrl(messageModel.fileUrl!),
          "avatar": isOutgoing ? "" : (_headerDetails?["avatar"] ?? ""),
          "moderation_status": messageModel.moderationStatus ?? 'Approved',
          "moderated_by": messageModel.moderatedBy,
          "parent_message_id": parentMessageId,
          "replyTo": replyTo,
          "replyToSender": replyToSender,
          "replyToType": replyToType,
          "replyToUrl": replyToUrl,
          "is_forwarded": messageModel.isForwarded ?? false,
          "status": messageModel.status ?? 'sent',
          "isDeleted": isDeleted,
          "isEdited": messageModel.isEdited ?? false,
        };

        // Avoid duplicate messages if already in list, or update existing message state
        final existingIndex = _messages.indexWhere(
          (item) =>
              (item['id']?.toString() ?? '') ==
              (newMsgMap['id']?.toString() ?? ''),
        );
        if (existingIndex != -1) {
          _messages[existingIndex] = {
            ..._messages[existingIndex],
            ...newMsgMap,
          };
          hasNewMsg = true;
        } else {
          _messages.add(newMsgMap);
          hasNewMsg = true;
        }
      }
    }

    if (hasNewMsg) {
      notifyListeners();
      scrollToBottom();

      // Auto-acknowledge / mark-as-read since the chat is currently open!
      if (_recipientId != null && _userId != null) {
        SocketService().markAsRead(
          chatId: _recipientId!,
          userId: _userId!,
          otherId: _recipientId!,
          isGroup: false,
        );
      }
    }
  }

  Future<void> init(
    String targetUserId, {
    bool isGroup = false,
    bool isRequest = false,
    bool isNewChat = false,
    bool isFavorite = false,
  }) async {
    SocketService().messageQueueNotifier.removeListener(_onMessageQueueChanged);
    SocketService().messageQueueNotifier.addListener(_onMessageQueueChanged);

    SocketService().userStatusChangeNotifier.removeListener(
      _onUserStatusChange,
    );
    SocketService().userStatusChangeNotifier.addListener(_onUserStatusChange);

    SocketService().messagesReadNotifier.removeListener(_onMessagesRead);
    SocketService().messagesReadNotifier.addListener(_onMessagesRead);

    SocketService().messagesDeliveredNotifier.removeListener(_onMessagesDelivered);
    SocketService().messagesDeliveredNotifier.addListener(_onMessagesDelivered);

    SocketService().typingIndicatorNotifier.removeListener(
      _onTypingIndicatorChanged,
    );
    SocketService().typingIndicatorNotifier.addListener(
      _onTypingIndicatorChanged,
    );

    _isLoading = true;
    _recipientId = targetUserId;
    _isRequest = isRequest;
    _isNewChat = isNewChat;
    _isFavorite = isFavorite;
    _isRecipientTyping = false; // Reset status on init
    _isSearchActive = false;
    _searchQuery = "";
    _searchMatchMessageIds = [];
    _currentSearchMatchIndex = -1;

    // Set active chat ID globally
    SocketService().activeChatId = targetUserId;
    SocketService().isActiveChatGroup = false;

    notifyListeners();

    // Fetch local user id from session
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      _userId = user.id;
      _userName = user.name;
    }

    if (_userId != null) {
      // Fetch current user details from API directly to read the live chat_wallpaper field with wallpaperid
      try {
        final userRes = await ApiService().get('/users/$_userId?currentUserId=$_userId');
        final dynamic userResData = userRes.data;
        final Map<String, dynamic> userJson = userResData is String
            ? jsonDecode(userResData)
            : userResData as Map<String, dynamic>;
        if (userJson['success'] == true && userJson['data'] != null) {
          final userData = userJson['data'];
          final String? wallpaperId = userData['chat_wallpaper']?.toString();
          if (wallpaperId != null && wallpaperId.isNotEmpty) {
            await fetchSelectedWallpaper(wallpaperId);
          } else {
            _wallpaperUrl = null;
          }
        }
      } catch (e) {
        debugPrint("Error fetching current user details for wallpaper: $e");
      }
    }

    await fetchHeaderDetails(targetUserId, isGroup: isGroup);

    if (_userId != null) {
      await fetchChatHistory(targetUserId);
      if (_messages.isNotEmpty) {
        _isNewChat = false;
      }

      // Mark as read immediately on open
      SocketService().markAsRead(
        chatId: targetUserId,
        userId: _userId!,
        otherId: targetUserId,
        isGroup: false,
      );
    } else {
      _messages = [];
    }

    if (!isGroup && _userId != null) {
      await fetchPersonalChatDetails(targetUserId);
    }

    _isLoading = false;
    notifyListeners();
    scrollToBottom(immediate: true);
  }

  void _onUserStatusChange() {
    if (_isDisposed || _recipientId == null) return;

    final data = SocketService().userStatusChangeNotifier.value;
    if (data == null) return;

    final String? userId = data['userId']?.toString();
    final String? status = data['status']?.toString();
    final String? lastSeen = data['lastSeen']?.toString();

    if (userId == _recipientId && _headerDetails != null) {
      final bool isOnline = (status == 'online');
      _headerDetails!['status'] = isOnline
          ? "Online"
          : DateHelper.formatLastSeen(lastSeen);
      notifyListeners();
    }
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

  void scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScroll(immediate, 0);
    });
  }

  void _performScroll(bool immediate, int retryCount) {
    if (_isDisposed) return;
    if (!scrollController.hasClients) {
      if (retryCount < 10) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _performScroll(immediate, retryCount + 1);
        });
      }
      return;
    }

    try {
      if (immediate) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!_isDisposed && scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
        Future.delayed(const Duration(milliseconds: 300), () {
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

  Future<void> fetchPersonalChatDetails(String userId) async {
    _isContactInfoLoading = true;
    _personalDetails = null;
    notifyListeners();

    try {
      final response = await ApiService().get(
        '/users/$userId?currentUserId=$_userId',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final data = json['data'] ?? {};
        final rel = data['relationship'];
        if (rel != null) {
          _relationshipStatus = rel['status']?.toString();
          _requestedBy = rel['requested_by']?.toString();
          final dynamic blockedByData = rel['blocked_by'];
          if (blockedByData is List) {
            _blockedBy = blockedByData.map((e) => e.toString()).toList();
          } else {
            _blockedBy = [];
          }
        } else {
          _relationshipStatus = null;
          _requestedBy = null;
          _blockedBy = [];
        }

        final List<String> parsedMedias = [];
        final dynamic sharedMediaData = data['shared_media'];
        if (sharedMediaData is List) {
          for (var m in sharedMediaData) {
            if (m is String) {
              parsedMedias.add(m);
            } else if (m is Map) {
              final url = m['file_url'] ?? m['url'] ?? m['file'];
              if (url != null) {
                parsedMedias.add(url.toString());
              }
            }
          }
        }

        final List<Map<String, dynamic>> parsedGroups = [];
        final dynamic groupsInCommonData = data['groups_in_common'];
        if (groupsInCommonData is List) {
          for (var g in groupsInCommonData) {
            if (g is Map) {
              parsedGroups.add({
                "id": g['_id']?.toString() ?? "",
                "name": g['name']?.toString() ?? "Group",
                "group_image": g['group_image']?.toString() ?? "",
                "membersCount": (g['members'] is List)
                    ? (g['members'] as List).length
                    : 0,
              });
            }
          }
        }

        _personalDetails = {
          "name": data['name'] ?? "Unknown",
          "bio": data['bio'] ?? "Hey there! I am using ShieldConnect.",
          "phoneNumber": data['phone'] ?? "+1 234 567 890",
          "avatar": data['avatar'] ?? "",
          "medias": parsedMedias,
          "groupsInCommon": parsedGroups,
        };
      }
    } catch (e) {
      debugPrint("Error fetching personal chat details: $e");
    } finally {
      _isContactInfoLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHeaderDetails(String chatId, {bool isGroup = false}) async {
    if (isGroup) {
      _headerDetails = {
        "name": "Design Team",
        "members": "Alice, Bob, Charlie, You",
        "avatar":
            "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
        "isGroup": true,
      };
    } else {
      try {
        final response = await ApiService().get(
          '/users/$chatId?currentUserId=$_userId',
        );
        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true) {
          final data = json['data'] ?? {};
          final rel = data['relationship'];
          if (rel != null) {
            _relationshipStatus = rel['status']?.toString();
            _requestedBy = rel['requested_by']?.toString();
            final dynamic blockedByData = rel['blocked_by'];
            if (blockedByData is List) {
              _blockedBy = blockedByData.map((e) => e.toString()).toList();
            } else {
              _blockedBy = [];
            }
          } else {
            _relationshipStatus = null;
            _requestedBy = null;
            _blockedBy = [];
          }
          final bool isOnline = data['is_online'] ?? false;
          final String? lastSeen = data['last_seen']?.toString();
          _headerDetails = {
            "name": data['name'] ?? "Unknown",
            "status": isOnline ? "Online" : DateHelper.formatLastSeen(lastSeen),
            "avatar": data['avatar'] ?? "",
            "isGroup": false,
          };
        }
      } catch (e) {
        debugPrint("Error fetching header details: $e");
        _headerDetails = {
          "name": "Unknown",
          "status": "Offline",
          "avatar": "",
          "isGroup": false,
        };
      }
    }
    notifyListeners();
  }

  Future<void> fetchChatHistory(String targetUserId) async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get(
        '/chat/history?user1=$_userId&user2=$targetUserId&page=1&limit=50',
      );
      debugPrint("fetchChatHistory response: ${response.data}");

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _messages = data
            .map<Map<String, dynamic>>((msg) {
              final sender = msg['sender_id'];
              final String senderName = sender is Map
                  ? (sender['name'] ?? '')
                  : '';
              final String? senderAvatar = sender is Map
                  ? sender['avatar']?.toString()
                  : null;
              final String senderIdStr = sender is Map
                  ? (sender['_id'] ?? '')
                  : (sender ?? '');
              final bool isOutgoing = senderIdStr == _userId;

              final String? parentMessageId = msg['parent_message_id'] is Map
                  ? msg['parent_message_id']['_id']?.toString()
                  : msg['parent_message_id']?.toString();
              String? replyTo;
              String? replyToSender;
              String? replyToType;
              String? replyToUrl;

              if (msg['parent_message_id'] is Map) {
                replyTo = msg['parent_message_id']['content']?.toString();
                replyToType = msg['parent_message_id']['message_type']?.toString();
                replyToUrl = msg['parent_message_id']['file_url'] != null
                    ? ApiService.getImageUrl(msg['parent_message_id']['file_url'].toString())
                    : null;
                final dynamic pSender = msg['parent_message_id']['sender_id'];
                if (pSender is Map) {
                  replyToSender = pSender['name']?.toString();
                } else if (pSender?.toString() == _userId) {
                  replyToSender = "You";
                } else if (pSender != null) {
                  replyToSender = _headerDetails?['name']?.toString() ?? "Sender";
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
                  replyTo = parentMsg['content']?.toString();
                  replyToType = parentMsg['message_type']?.toString() ?? parentMsg['type']?.toString();
                  replyToUrl = parentMsg['file_url'] != null
                      ? ApiService.getImageUrl(parentMsg['file_url'].toString())
                      : (parentMsg['url'] != null ? parentMsg['url']?.toString() : null);
                  final pSender = parentMsg['sender_id'];
                  if (pSender is Map) {
                    replyToSender = pSender['name']?.toString();
                  } else if (pSender?.toString() == _userId) {
                    replyToSender = "You";
                  } else if (pSender != null) {
                    replyToSender = _headerDetails?['name']?.toString() ?? "Sender";
                  }
                }
              }

              final bool isDeleted = msg['is_deleted_for_everyone'] as bool? ?? false;
              return {
                "id": msg['_id'],
                "sender": isOutgoing ? "You" : senderName,
                "text": isDeleted ? "This message was deleted" : (msg['content'] ?? ''),
                "time": msg['created_at'] != null
                    ? DateHelper.formatTime(msg['created_at'])
                    : '',
                "createdAt":
                    msg['created_at'] ?? DateTime.now().toIso8601String(),
                "isOutgoing": isOutgoing,
                "type": isDeleted ? "text" : (msg['message_type'] ?? 'text'),
                "file_name": isDeleted ? null : msg['file_name']?.toString(),
                "url": (isDeleted || msg['file_url'] == null)
                    ? null
                    : ApiService.getImageUrl(msg['file_url']),
                "avatar": senderAvatar ?? "",
                "moderation_status": msg['moderation_status'] ?? 'Approved',
                "moderated_by": msg['moderated_by'],
                "parent_message_id": parentMessageId,
                "replyTo": replyTo,
                "replyToSender": replyToSender,
                "replyToType": replyToType,
                "replyToUrl": replyToUrl,
                "is_forwarded": msg['is_forwarded'] as bool? ?? false,
                "status": msg['status'] ?? 'sent',
                "isDeleted": isDeleted,
                "isEdited": msg['is_edited'] as bool? ?? false,
              };
            })
            .toList()
            .reversed
            .toList();
      } else {
        _messages = [];
      }
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
      _messages = [];
    }
    notifyListeners();
    scrollToBottom(immediate: true);
  }

  Future<void> sendMessage() async {
    final String content = messageController.text.trim();
    if (content.isEmpty) return;
    if (_userId == null || _recipientId == null) return;

    final String? parentMsgId = _selectedReplyMessage?["id"]?.toString();

    _selectedReplyMessage = null;
    messageController.clear();
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/chat/send',
        data: {
          "senderId": _userId,
          "recipientId": _recipientId,
          "content": content,
          if (parentMsgId != null) "parentMessageId": parentMsgId,
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final msgData = json['data']?['message'] ?? json['data'] ?? {};

        // Parse raw message data using MessageModel
        final messageModel = MessageModel.fromJson(msgData);

        // Add developer logging for the sent message model
        developer.log(
          "Sent message model: ${jsonEncode(messageModel.toJson())}",
        );

        // Emit through socket for real-time messaging
        final socketPayload = {
          "senderId": _userId,
          "recipientId": _recipientId,
          "content": content,
          "message_type": messageModel.messageType ?? "text",
          "parentMessageId": parentMsgId,
          "_id": messageModel.id,
          "createdAt": messageModel.createdAt?.toIso8601String(),
        };
        developer.log(
          "🔌 SOCKET: Emitting new-message via socket: $socketPayload",
        );
        SocketService().emit('send-message', socketPayload);

        // Fetch latest history to display the message with correct DB schema and IDs
        await fetchChatHistory(_recipientId!);

        // If it was a brand-new chat screen, it is now no longer a blank/new chat!
        if (_isNewChat) {
          _isNewChat = false;
        }
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
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
    if (_userId == null || _recipientId == null) return;
    final String? parentMsgId = _selectedReplyMessage?["id"]?.toString();

    _selectedReplyMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        "senderId": _userId,
        "recipientId": _recipientId,
        "content": content ?? "Shared a $messageType",
        "message_type": messageType,
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
        if (parentMsgId != null) "parentMessageId": parentMsgId,
      });

      final response = await ApiService().post('/chat/send', data: formData);
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      debugPrint("sendMediaMessage API response: $json");

      if (json['success'] == true ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        final msgData = json['data']?['message'] ?? json['data'] ?? {};
        final messageModel = MessageModel.fromJson(msgData);

        // Emit through socket for real-time messaging
        final socketPayload = {
          "senderId": _userId,
          "recipientId": _recipientId,
          "content":
              messageModel.content ?? (content ?? "Shared a $messageType"),
          "message_type": messageModel.messageType ?? messageType,
          "file_url": messageModel.fileUrl,
          "file_name": messageModel.fileName ?? fileName,
          "_id": messageModel.id,
          "parentMessageId": parentMsgId,
          "createdAt": messageModel.createdAt?.toIso8601String(),
        };
        developer.log(
          "🔌 SOCKET: Emitting media new-message via socket: $socketPayload",
        );
        SocketService().emit('send-message', socketPayload);

        // Fetch latest history to display the message with correct DB schema and IDs
        await fetchChatHistory(_recipientId!);

        if (_isNewChat) {
          _isNewChat = false;
        }
      } else {
        debugPrint(
          "sendMediaMessage failed with status code ${response.statusCode}: $json",
        );
      }
    } catch (e) {
      debugPrint("Error sending media message: $e");
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
            "Compressed image from ${bytes.length} to ${compressedBytes.length} bytes",
          );
          return compressedFile;
        }
      } catch (e) {
        debugPrint("Error compressing image: $e");
      }
    }
    return file;
  }

  Future<String?> _showCaptionScreen(
    BuildContext context,
    String filePath,
    String messageType, {
    String? fileName,
  }) async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaCaptionScreen(
          filePath: filePath,
          messageType: messageType,
          fileName: fileName,
        ),
      ),
    );
  }

  Future<void> pickMedia(BuildContext context) async {
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
                "Select Gallery Media",
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
                            color: appColor(context)
                                .secondary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: appColor(context).secondary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose Photo",
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
                            color: appColor(context)
                                .secondary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.video_library_rounded,
                            color: appColor(context).secondary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose Video",
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

      final XFile? media = choice == 'photo'
          ? await picker.pickImage(source: ImageSource.gallery, imageQuality: 85)
          : await picker.pickVideo(source: ImageSource.gallery);

      if (media != null) {
        String path = media.path;
        final String name = media.name;
        final String extension = path.split('.').last.toLowerCase();

        String messageType = 'image';
        if (['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(extension)) {
          messageType = 'video';
        } else {
          final File originalFile = File(path);
          final File compressedFile = await compressFileIfNeeded(
            originalFile,
            extension,
          );
          path = compressedFile.path;
        }

        final settings = await SettingsModel.loadActiveSettings();
        final int fileSize = await File(path).length();
        if (messageType == 'video') {
          final int limit = settings.getVideoLimitBytes();
          if (fileSize > limit) {
            if (!context.mounted) return;
            ToastHelper.showWarningDialog(
              context,
              "Video Too Large",
              "Videos cannot exceed ${settings.videoLimit ?? '100MB'}. Your selected video is ${SettingsModel.formatBytes(fileSize)}."
            );
            return;
          }
        } else {
          final int limit = settings.getImageLimitBytes();
          if (fileSize > limit) {
            if (!context.mounted) return;
            ToastHelper.showWarningDialog(
              context,
              "Image Too Large",
              "Images cannot exceed ${settings.imageLimit ?? '10MB'}. Your selected image is ${SettingsModel.formatBytes(fileSize)}."
            );
            return;
          }
        }

        if (!context.mounted) return;
        final String? caption = await _showCaptionScreen(context, path, messageType);
        if (caption == null) return;

        await sendMediaMessage(path, name, messageType, content: caption);
      }
    } catch (e) {
      debugPrint("Error picking media: $e");
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

        final settings = await SettingsModel.loadActiveSettings();
        final int fileSize = await File(path).length();
        if (messageType == 'video') {
          final int limit = settings.getVideoLimitBytes();
          if (fileSize > limit) {
            if (!context.mounted) return;
            ToastHelper.showWarningDialog(
              context,
              "Video Too Large",
              "Videos cannot exceed ${settings.videoLimit ?? '100MB'}. Your captured video is ${SettingsModel.formatBytes(fileSize)}."
            );
            return;
          }
        } else {
          final int limit = settings.getImageLimitBytes();
          if (fileSize > limit) {
            if (!context.mounted) return;
            ToastHelper.showWarningDialog(
              context,
              "Image Too Large",
              "Images cannot exceed ${settings.imageLimit ?? '10MB'}. Your captured image is ${SettingsModel.formatBytes(fileSize)}."
            );
            return;
          }
        }

        if (!context.mounted) return;
        final String? caption = await _showCaptionScreen(context, path, messageType);
        if (caption == null) return;

        await sendMediaMessage(path, name, messageType, content: caption);
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

        final settings = await SettingsModel.loadActiveSettings();
        final int fileSize = await File(path).length();
        final int limit = settings.getDocLimitBytes();
        if (fileSize > limit) {
          if (context != null && context.mounted) {
            ToastHelper.showWarningDialog(
              context,
              "Document Too Large",
              "Documents cannot exceed ${settings.docLimit ?? '20MB'}. Your selected document is ${SettingsModel.formatBytes(fileSize)}."
            );
          }
          return;
        }

        if (context != null && context.mounted) {
          final String? caption = await _showCaptionScreen(context, path, "file", fileName: name);
          if (caption == null) return;
          await sendMediaMessage(
            path,
            name,
            "file",
            content: caption.isNotEmpty ? caption : "Shared a document: $name",
          );
        } else {
          await sendMediaMessage(
            path,
            name,
            "file",
            content: "Shared a document: $name",
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
      if (context != null && context.mounted) {
        ToastHelper.showToast(
          context,
          "Plugin not initialized. Please rebuild the app (full restart/run).",
        );
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
      debugPrint("Error recording audio: $e");
    }
  }

  Future<void> sendLocation() async {
    final String content = "Location: Lat 34.0522, Lng -118.2437";
    if (_userId == null || _recipientId == null) return;
    try {
      final response = await ApiService().post(
        '/chat/send',
        data: {
          "senderId": _userId,
          "recipientId": _recipientId,
          "content": content,
          "message_type": "text",
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final msgData = json['data']?['message'] ?? json['data'] ?? {};
        final messageModel = MessageModel.fromJson(msgData);

        // Emit through socket for real-time messaging
        final socketPayload = {
          "senderId": _userId,
          "recipientId": _recipientId,
          "content": content,
          "message_type": "text",
          "_id": messageModel.id,
          "createdAt": messageModel.createdAt?.toIso8601String(),
        };
        developer.log(
          "🔌 SOCKET: Emitting location new-message via socket: $socketPayload",
        );
        SocketService().emit('send-message', socketPayload);

        // Fetch latest history to display the message with correct DB schema and IDs
        await fetchChatHistory(_recipientId!);

        if (_isNewChat) {
          _isNewChat = false;
        }
      }
    } catch (e) {
      debugPrint("Error sending location: $e");
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
          //ToastHelper.showToast(context, "Message deleted for everyone");
        }
        notifyListeners();
      } else {
        if (context.mounted) {
          //  ToastHelper.showToast(context, json['message']?.toString() ?? "Failed to delete message");
        }
      }
    } catch (e) {
      debugPrint("Error deleting message for everyone: $e");
      if (context.mounted) {
        //ToastHelper.showToast(context, "Error: $e");
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

  Future<void> appealMessageApi(BuildContext context, String messageId) async {
    if (_userId == null) return;
    
    // Set appealing state
    int msgIndex = _messages.indexWhere((msg) => msg['id'] == messageId);
    if (msgIndex != -1) {
      _messages[msgIndex]["isAppealing"] = true;
      _messages[msgIndex]["appealFailed"] = false;
      notifyListeners();
    }

    try {
      final response = await ApiService().put(
        '/chat/message/$messageId/appeal',
        data: {"userId": _userId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      msgIndex = _messages.indexWhere((msg) => msg['id'] == messageId);
      if (msgIndex != -1) {
        _messages[msgIndex]["isAppealing"] = false;
        if (json['success'] == true) {
          _messages[msgIndex]["moderation_status"] = "Moderation";
          _messages[msgIndex]["appealFailed"] = false;
        } else {
          _messages[msgIndex]["appealFailed"] = true;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error appealing message: $e");
      msgIndex = _messages.indexWhere((msg) => msg['id'] == messageId);
      if (msgIndex != -1) {
        _messages[msgIndex]["isAppealing"] = false;
        _messages[msgIndex]["appealFailed"] = true;
        notifyListeners();
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
        "replyToType": _messages[index]["type"],
        "replyToUrl": _messages[index]["fileUrl"],
      };
      _messages.add(replyMessage);
      notifyListeners();
    }
  }

  Future<void> forwardMessage(int index, List<String> targetChatIds) async {
    // Mock forwarding
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  Future<bool> clearChat() async {
    if (_userId == null || _recipientId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/clear',
        data: {"userId": _userId, "recipientId": _recipientId},
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
      debugPrint("Error clearing personal chat: $e");
      return false;
    }
  }

  Future<bool> deleteChat() async {
    if (_userId == null || _recipientId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/delete',
        data: {"userId": _userId, "recipientId": _recipientId},
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
      debugPrint("Error deleting personal chat: $e");
      return false;
    }
  }

  Future<void> respondToConnectionRequest(String action, {BuildContext? context}) async {
    if (_userId == null || _recipientId == null) return;
    _isResponding = true;
    _respondingAction = action;
    notifyListeners();

    try {
      final response = await ApiService().put(
        '/connections/respond',
        data: {
          "userId": _userId,
          "otherUserId": _recipientId,
          "action": action,
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final data = json['data'] ?? {};
        _relationshipStatus = data['status']?.toString();
        _requestedBy = data['requested_by']?.toString();

        final dynamic blockedByData = data['blocked_by'];
        if (blockedByData is List) {
          _blockedBy = blockedByData.map((e) => e.toString()).toList();
        } else {
          _blockedBy = [];
        }

        if (action == 'accepted') {
          _isRequest = false;
          _isNewChat = false;
          await fetchChatHistory(_recipientId!);
        } else if (action == 'rejected') {
          _isRequest = false;
          _isNewChat = true;
          _messages = [];
        } else if (action == 'blocked') {
          _isRequest = false;
        }

        if (context != null && context.mounted) {
          context.read<NotificationController>().init();
          context.read<HomeScreenController>().fetchRecentChats(updateLoadingState: false);
        }
      }
    } catch (e) {
      debugPrint("Error responding to connection request: $e");
    }

    _isResponding = false;
    _respondingAction = null;
    notifyListeners();
  }

  Future<void> unblockUser() async {
    if (_userId == null || _recipientId == null) return;
    _isResponding = true;
    _respondingAction = 'unblock';
    _unblockError = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/connections/unblock',
        data: {"userId": _userId, "otherUserId": _recipientId},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final friend = FriendModel.fromJson(json['data']);
        _relationshipStatus = friend.status;
        _requestedBy = friend.requestedBy;
        _blockedBy = friend.blockedBy ?? [];
      } else {
        _unblockError = "Failed to unblock contact";
      }
    } catch (e) {
      debugPrint("Error unblocking user: $e");
      _unblockError = "Failed to unblock contact";
    }

    _isResponding = false;
    _respondingAction = null;
    notifyListeners();
  }

  Future<void> blockUser(String userId) async {
    if (_userId == null || _recipientId == null) return;
    _isResponding = true;
    _respondingAction = 'blocked';
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/connections/block',
        data: {"userId": _userId, "otherUserId": _recipientId},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final friend = FriendModel.fromJson(json['data']);
        _relationshipStatus = friend.status;
        _requestedBy = friend.requestedBy;
        _blockedBy = friend.blockedBy ?? [];
      }
    } catch (e) {
      debugPrint("Error blocking user: $e");
    }

    _isResponding = false;
    _respondingAction = null;
    notifyListeners();
  }

  Map<String, dynamic> getMessageInfo(int index) {
    if (index >= 0 && index < _messages.length) {
      return {
        "sentAt": "10:00 AM",
        "deliveredAt": "10:01 AM",
        "readAt": "10:05 AM",
      };
    }
    return {};
  }

  List<String> getMockEmojis() {
    return [
      "😊",
      "🥰",
      "🚀",
      "🔥",
      "🌈",
      "🎈",
      "🍕",
      "🎸",
      "🐱",
      "🐶",
      "🐻",
      "🐼",
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
    if (_userId == null || _recipientId == null) return;
    final String? parentMsgId = _selectedReplyMessage?["id"]?.toString();
    final String? replyText = _selectedReplyMessage?["text"]?.toString();
    final String? replySender = _selectedReplyMessage?["sender"]?.toString();
    final String? replyToType = _selectedReplyMessage?["type"]?.toString();
    final String? replyToUrl = _selectedReplyMessage?["url"]?.toString();

    _selectedReplyMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        '/chat/send',
        data: {
          "senderId": _userId,
          "message_type": "sticker",
          "file_url": stickerPath,
          "recipientId": _recipientId,
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
        final msgData = json['data']?['message'] ?? json['data'] ?? {};
        final messageModel = MessageModel.fromJson(msgData);

        // Emit through socket for real-time messaging
        final socketPayload = {
          "senderId": _userId,
          "recipientId": _recipientId,
          "content": messageModel.content ?? "Sticker",
          "message_type": messageModel.messageType ?? "sticker",
          "file_url": messageModel.fileUrl,
          "parentMessageId": parentMsgId,
          "_id": messageModel.id,
          "createdAt": messageModel.createdAt?.toIso8601String(),
        };
        developer.log(
          "🔌 SOCKET: Emitting sticker new-message via socket: $socketPayload",
        );
        SocketService().emit('send-message', socketPayload);

        // Fetch latest history to display the message with correct DB schema and IDs
        await fetchChatHistory(_recipientId!);

        if (_isNewChat) {
          _isNewChat = false;
        }
      }
    } catch (e) {
      debugPrint("Error sending sticker message: $e");
    }
    notifyListeners();
    scrollToBottom();
  }

  Future<bool> toggleFavorite(bool isFavorite) async {
    if (_userId == null || _recipientId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/favorite',
        data: {
          "userId": _userId,
          "chatId": _recipientId,
          "isFavorite": isFavorite,
        },
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
      debugPrint("Error toggling favorite personal chat: $e");
      return false;
    }
  }

  Future<bool> archiveChat() async {
    if (_userId == null || _recipientId == null) return false;
    try {
      final response = await ApiService().put(
        '/chat/archive',
        data: {"userId": _userId, "chatId": _recipientId, "type": "user"},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint("Error archiving personal chat: $e");
      return false;
    }
  }

  Future<bool> reportUser({
    required String reason,
    required String description,
  }) async {
    if (_userId == null || _recipientId == null) return false;
    try {
      final response = await ApiService().post(
        '/reports',
        data: {
          "reporterId": _userId,
          "reportedUserId": _recipientId,
          "reason": reason,
          "description": description,
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint("Error submitting report: $e");
      return false;
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _onMessagesRead() {
    if (_isDisposed || _recipientId == null) return;
    final data = SocketService().messagesReadNotifier.value;
    if (data == null) return;

    final String? eventChatId = data['chatId']?.toString();
    final String? readerId = data['readerId']?.toString() ?? data['userId']?.toString();
    if (eventChatId == null) return;

    final bool isMyChat = (eventChatId == _recipientId ||
        eventChatId == _userId ||
        readerId == _recipientId ||
        readerId == _userId);

    if (isMyChat) {
      if (readerId == _recipientId) {
        developer.log(
          "PersonalChatController: messages-read real-time event for chatId=$eventChatId, readerId=$readerId. Recipient read our messages. Updating all outgoing messages to 'read' status.",
        );

        bool updated = false;
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i]['isOutgoing'] == true &&
              _messages[i]['status'] != 'read') {
            _messages[i]['status'] = 'read';
            updated = true;
          }
        }
        if (updated) {
          notifyListeners();
        }
      }
    }
  }

  void _onMessagesDelivered() {
    if (_isDisposed || _recipientId == null) return;
    final data = SocketService().messagesDeliveredNotifier.value;
    if (data == null) return;

    final String? eventRecipientId = data['recipientId']?.toString();
    if (eventRecipientId == null) return;

    if (eventRecipientId == _recipientId) {
      developer.log(
        "PersonalChatController: messages-delivered real-time event for recipientId=$eventRecipientId. Updating sent outgoing messages to 'delivered' status.",
      );

      bool updated = false;
      for (int i = 0; i < _messages.length; i++) {
        final currentStatus = _messages[i]['status'];
        if (_messages[i]['isOutgoing'] == true &&
            (currentStatus == null || currentStatus == 'sent')) {
          _messages[i]['status'] = 'delivered';
          updated = true;
        }
      }
      if (updated) {
        notifyListeners();
      }
    }
  }

  void handleTyping() {
    if (_userId == null || _recipientId == null) return;

    final String myId = _userId!;
    final String myName = _userName ?? "User";

    final now = DateTime.now();
    if (_lastTypingEmit == null ||
        now.difference(_lastTypingEmit!) > const Duration(seconds: 1)) {
      _lastTypingEmit = now;
      SocketService().emitTypingStatus(
        chatId: _recipientId!,
        userId: myId,
        userName: myName,
        isGroup: false,
        isTyping: true,
      );
    }

    _stopTypingTimer?.cancel();
    _stopTypingTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      SocketService().emitTypingStatus(
        chatId: _recipientId!,
        userId: myId,
        userName: myName,
        isGroup: false,
        isTyping: false,
      );
      _lastTypingEmit = null;
    });
  }

  void _onTypingIndicatorChanged() async {
    if (_isDisposed || _recipientId == null) return;

    final data = SocketService().typingIndicatorNotifier.value;
    if (data == null) return;

    // Enforce reciprocal privacy: if local user disabled typing indicators, ignore incoming typing statuses
    final bool showTyping = await SocketService()
        .getShowTypingIndicatorSetting();
    if (!showTyping) {
      if (_isRecipientTyping) {
        _isRecipientTyping = false;
        notifyListeners();
      }
      return;
    }

    final String? chatId = data['chatId']?.toString();
    final String? userId = data['userId']?.toString();
    final bool? isTyping = data['isTyping'] as bool?;

    if (chatId == null || userId == null || isTyping == null) return;

    // In 1:1 chat, chatId from server could be our userId or recipientId.
    if (chatId == _userId || chatId == _recipientId) {
      if (userId == _recipientId) {
        if (_isRecipientTyping != isTyping) {
          _isRecipientTyping = isTyping;
          notifyListeners();
          if (isTyping) {
            scrollToBottom();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTypingTimer?.cancel();
    SocketService().messageQueueNotifier.removeListener(_onMessageQueueChanged);
    SocketService().userStatusChangeNotifier.removeListener(
      _onUserStatusChange,
    );
    SocketService().messagesReadNotifier.removeListener(_onMessagesRead);
    SocketService().messagesDeliveredNotifier.removeListener(_onMessagesDelivered);
    SocketService().typingIndicatorNotifier.removeListener(
      _onTypingIndicatorChanged,
    );
    if (SocketService().activeChatId == _recipientId) {
      SocketService().activeChatId = null;
    }
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
