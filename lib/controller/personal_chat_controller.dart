import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/message_model.dart';
import 'package:shieldconnect_app/model/friend_model.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

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

  Future<void> init(
    String targetUserId, {
    bool isGroup = false,
    bool isRequest = false,
    bool isNewChat = false,
    bool isFavorite = false,
  }) async {
    _isLoading = true;
    _recipientId = targetUserId;
    _isRequest = isRequest;
    _isNewChat = isNewChat;
    _isFavorite = isFavorite;
    notifyListeners();

    // Fetch local user id from session
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      _userId = user.id;
      if (user.chatWallpaper != null && user.chatWallpaper!.isNotEmpty) {
        fetchSelectedWallpaper(user.chatWallpaper!);
      }
    }

    await fetchHeaderDetails(targetUserId, isGroup: isGroup);

    if (_userId != null) {
      await fetchChatHistory(targetUserId);
      if (_messages.isNotEmpty) {
        _isNewChat = false;
      }
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
      if (scrollController.hasClients) {
        if (immediate) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        } else {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      }
    });
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
                "membersCount": (g['members'] is List) ? (g['members'] as List).length : 0,
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
          _headerDetails = {
            "name": data['name'] ?? "Unknown",
            "status": "Online",
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

              if (msg['parent_message_id'] is Map) {
                replyTo = msg['parent_message_id']['content']?.toString();
                final dynamic pSender = msg['parent_message_id']['sender_id'];
                if (pSender is Map) {
                  replyToSender = pSender['name']?.toString();
                } else if (pSender?.toString() == _userId) {
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
                  replyTo = parentMsg['content']?.toString();
                  final pSender = parentMsg['sender_id'];
                  if (pSender is Map) {
                    replyToSender = pSender['name']?.toString();
                  } else if (pSender?.toString() == _userId) {
                    replyToSender = "You";
                  }
                }
              }

              return {
                "id": msg['_id'],
                "sender": isOutgoing ? "You" : senderName,
                "text": msg['content'] ?? '',
                "time": msg['created_at'] != null
                    ? DateHelper.formatTime(msg['created_at'])
                    : '',
                "createdAt":
                    msg['created_at'] ?? DateTime.now().toIso8601String(),
                "isOutgoing": isOutgoing,
                "type": msg['message_type'] ?? 'text',
                "file_name": msg['file_name']?.toString(),
                "url": msg['file_url'] != null
                    ? ApiService.getImageUrl(msg['file_url'])
                    : null,
                "avatar": senderAvatar ?? "",
                "moderation_status": msg['moderation_status'] ?? 'Approved',
                "parent_message_id": parentMessageId,
                "replyTo": replyTo,
                "replyToSender": replyToSender,
                "is_forwarded": msg['is_forwarded'] as bool? ?? false,
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
    final String? replyText = _selectedReplyMessage?["text"]?.toString();
    final String? replySender = _selectedReplyMessage?["sender"]?.toString();

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

        final bool isOutgoing = true;

        final newMsgMap = {
          "id": messageModel.id,
          "sender": "You",
          "text": messageModel.content ?? content,
          "time": messageModel.createdAt != null
              ? DateHelper.formatTime(messageModel.createdAt!.toIso8601String())
              : 'Now',
          "createdAt": messageModel.createdAt != null
              ? messageModel.createdAt!.toIso8601String()
              : DateTime.now().toIso8601String(),
          "isOutgoing": isOutgoing,
          "type": messageModel.messageType ?? 'text',
          "moderation_status": messageModel.moderationStatus ?? 'Pending',
          "parent_message_id": parentMsgId,
          "replyTo": replyText,
          "replyToSender": replySender,
        };

        _messages.add(newMsgMap);

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
    try {
      final formData = FormData.fromMap({
        "senderId": _userId,
        "recipientId": _recipientId,
        "content": content ?? "Shared a $messageType",
        "message_type": messageType,
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
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

        final newMsgMap = {
          "id": messageModel.id,
          "sender": "You",
          "text": messageModel.content ?? (content ?? "Shared a $messageType"),
          "time": messageModel.createdAt != null
              ? DateHelper.formatTime(messageModel.createdAt!.toIso8601String())
              : 'Now',
          "createdAt": messageModel.createdAt != null
              ? messageModel.createdAt!.toIso8601String()
              : DateTime.now().toIso8601String(),
          "isOutgoing": true,
          "type": messageModel.messageType ?? messageType,
          "message_type": messageModel.messageType ?? messageType,
          "file_name": messageModel.fileName ?? fileName,
          "url": messageModel.fileUrl != null
              ? ApiService.getImageUrl(messageModel.fileUrl!)
              : null,
          "moderation_status": messageModel.moderationStatus ?? 'Pending',
        };

        _messages.add(newMsgMap);
        if (_isNewChat) {
          _isNewChat = false;
        }
        notifyListeners();
        scrollToBottom();
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

        final newMsgMap = {
          "id": messageModel.id,
          "sender": "You",
          "text": messageModel.content ?? content,
          "time": messageModel.createdAt != null
              ? DateHelper.formatTime(messageModel.createdAt!.toIso8601String())
              : 'Now',
          "createdAt": messageModel.createdAt != null
              ? messageModel.createdAt!.toIso8601String()
              : DateTime.now().toIso8601String(),
          "isOutgoing": true,
          "type": "text",
          "moderation_status": messageModel.moderationStatus ?? 'Pending',
        };

        _messages.add(newMsgMap);
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
        data: {
          "userId": _userId,
          "recipientId": _recipientId,
        },
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

  Future<void> respondToConnectionRequest(String action) async {
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
        data: {
          "userId": _userId,
          "otherUserId": _recipientId,
        },
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
        data: {
          "userId": _userId,
          "otherUserId": _recipientId,
        },
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

        final newMsgMap = {
          "id": messageModel.id,
          "sender": "You",
          "text": messageModel.content ?? "Sticker",
          "time": messageModel.createdAt != null
              ? DateHelper.formatTime(messageModel.createdAt!.toIso8601String())
              : 'Now',
          "createdAt": messageModel.createdAt != null
              ? messageModel.createdAt!.toIso8601String()
              : DateTime.now().toIso8601String(),
          "isOutgoing": true,
          "type": messageModel.messageType ?? 'sticker',
          "url": messageModel.fileUrl != null
              ? ApiService.getImageUrl(messageModel.fileUrl!)
              : ApiService.getImageUrl(stickerPath),
          "moderation_status": messageModel.moderationStatus ?? 'Approved',
          "parent_message_id": parentMsgId,
          "replyTo": replyText,
          "replyToSender": replySender,
        };

        _messages.add(newMsgMap);
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

  @override
  void dispose() {
    _isDisposed = true;
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
