import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
import 'package:shieldconnect_app/services/local_db_service.dart';
import 'package:shieldconnect_app/model/conversation_model.dart';

class HomeScreenController extends ChangeNotifier {
  HomeScreenController() {
    init();
  }

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  void setSearching(bool val) {
    if (_isSearching == val) return;
    _isSearching = val;
    if (!val) {
      _searchQuery = "";
      searchController.clear();
    }
    notifyListeners();
  }

  void setSearchQuery(String val) {
    _searchQuery = val;
    notifyListeners();
  }

  List<dynamic> _recentChats = [];
  
  // In-memory caches for unread counts and online status (omitted from local SQLite db per requirements)
  final Map<String, int> _inMemoryUnreadCounts = {};
  final Map<String, bool> _inMemoryOnlineStatus = {};

  void _updateInMemoryCache(List<dynamic> chats) {
    for (final chat in chats) {
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '').toString();
          if (cid.isNotEmpty) {
            _inMemoryUnreadCounts[cid] = chat['unread_count'] as int? ?? 0;
            _inMemoryOnlineStatus[cid] = conversation['is_online'] as bool? ?? false;
          }
        }
      }
    }
  }

  List<dynamic> get recentChats {
    // Inject dynamic unread counts and online status from in-memory caches
    List<dynamic> chats = _recentChats.map((chat) {
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '').toString();
          
          final Map<String, dynamic> updatedConversation = Map<String, dynamic>.from(conversation);
          updatedConversation['is_online'] = _inMemoryOnlineStatus[cid] ?? conversation['is_online'] ?? false;
          
          final Map<String, dynamic> updatedChat = Map<String, dynamic>.from(chat);
          updatedChat['conversation'] = updatedConversation;
          updatedChat['unread_count'] = _inMemoryUnreadCounts[cid] ?? chat['unread_count'] ?? 0;
          
          return updatedChat;
        }
      }
      return chat;
    }).toList();

    if (_userId != null) {
      chats = chats.where((chat) {
        if (chat is Map) {
          final relationship = chat['relationship'];
          final String relStatus = relationship != null
              ? (relationship['status']?.toString() ?? '')
              : '';
          final String? requestedBy = chat['requested_by']?.toString() ?? 
                                      relationship?['requested_by']?.toString();

          // If the connection is pending and was initiated by us, hide it from our chat list
          if (relStatus == 'pending' && requestedBy == _userId) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // Filter based on active tab locally
    if (_activeTab == 'Unread') {
      chats = chats.where((chat) {
        if (chat is Map) {
          final int unread = chat['unread_count'] ?? 0;
          return unread > 0;
        }
        return false;
      }).toList();
    } else if (_activeTab == 'Groups') {
      chats = chats.where((chat) {
        if (chat is Map) {
          final conversation = chat['conversation'];
          return conversation is Map && conversation['type'] == 'group';
        }
        return false;
      }).toList();
    } else if (_activeTab == 'Favourite') {
      chats = chats.where((chat) {
        if (chat is Map) {
          return chat['is_favorite'] == true;
        }
        return false;
      }).toList();
    } else if (_activeTab == 'Requests') {
      chats = chats.where((chat) {
        if (chat is Map) {
          final relationship = chat['relationship'];
          final String relStatus = relationship != null
              ? (relationship['status']?.toString() ?? '')
              : '';
          return relStatus == 'pending';
        }
        return false;
      }).toList();
    } else if (_activeTab == 'All') {
      chats = chats.where((chat) {
        if (chat is Map) {
          final relationship = chat['relationship'];
          final String relStatus = relationship != null
              ? (relationship['status']?.toString() ?? '')
              : '';
          return relStatus != 'pending';
        }
        return false;
      }).toList();
    }

    if (_isSearching && _searchQuery.isNotEmpty) {
      chats = chats.where((chat) {
        if (chat is Map) {
          final conversation = chat['conversation'] ?? {};
          final String name = (conversation['name'] ?? 'Unknown').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }
        return false;
      }).toList();
    }

    return chats;
  }

  int get totalUnreadCount {
    int total = 0;
    _inMemoryUnreadCounts.forEach((chatKey, unread) {
      if (unread > 0) {
        total++;
      }
    });
    return total;
  }

  String? _profileImage;
  String? get profileImage => _profileImage;

  bool _showTypingIndicator = true;
  bool get showTypingIndicator => _showTypingIndicator;

  final Map<String, Set<String>> _typingUsers = {};
  Map<String, Set<String>> get typingUsers => _typingUsers;
  final Map<String, String> _userIdToName = {};

  String? _adminAnnouncement;
  String? get adminAnnouncement => _adminAnnouncement;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  int _requestCount = 0;
  int get requestCount => _requestCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _selectedChatId;
  String? get selectedChatId => _selectedChatId;

  void setSelectedChatId(String? chatId) {
    if (_selectedChatId == chatId) return;
    _selectedChatId = chatId;
    notifyListeners();
  }

  String _activeTab = 'All';
  String get activeTab => _activeTab;

  void setActiveTab(String tab) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    
    // Load cached recent chats first so we have the full list
    final List<ConversationModel> cached = await LocalDbService().getConversations();
    if (cached.isNotEmpty) {
      _recentChats = cached.map((m) => m.toJson()).toList();
    }
    notifyListeners();
    
    // Fetch from API in background. Never show loader.
    fetchRecentChats(tab: tab, updateLoadingState: false);
  }

  Future<void> init() async {
    // Resolve userId first to make sure UI filtering is correct
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      _userId = user.id;
    }

    // Load cached recent chats from SQLite
    await loadCachedRecentChats();

    // Show app icon loader if cache is empty (e.g. on first login/launch)
    if (_recentChats.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    // Setup global real-time listener to refresh recent chats list
    SocketService().lastReceivedMessageNotifier.removeListener(
      _onGlobalMessageReceived,
    );
    SocketService().lastReceivedMessageNotifier.addListener(
      _onGlobalMessageReceived,
    );

    SocketService().userStatusChangeNotifier.removeListener(
      _onUserStatusChange,
    );
    SocketService().userStatusChangeNotifier.addListener(_onUserStatusChange);

    SocketService().friendsStatusSyncNotifier.removeListener(
      _onFriendsStatusSync,
    );
    SocketService().friendsStatusSyncNotifier.addListener(_onFriendsStatusSync);

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

    // Trigger API updates in background concurrently with a minimum 500ms duration
    Future.wait([
      fetchRequestCount(),
      fetchProfileImage(),
      fetchAdminAnnouncement(),
      fetchNotificationCount(),
      fetchRecentChats(updateLoadingState: false),
      Future.delayed(const Duration(milliseconds: 500)),
    ]).then((_) {
      _isLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint("Error during background sync: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadCachedRecentChats() async {
    final List<ConversationModel> cached = await LocalDbService().getConversations();
    if (cached.isNotEmpty) {
      _recentChats = cached.map((m) => m.toJson()).toList();
    }
    notifyListeners();
  }

  Future<void> fetchRequestCount() async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get(
        '/chat/recent/$_userId?tab=Requests',
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      if (json['success'] == true) {
        final List<dynamic> requests = json['data'] ?? [];
        _requestCount = requests.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching request count: $e");
    }
  }

  Future<void> fetchRecentChats({
    String? tab,
    bool updateLoadingState = false,
  }) async {
    try {
      if (updateLoadingState) {
        _isLoading = true;
        notifyListeners();
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
      } else {
        _userId = null;
        _recentChats = [];
      }

      if (_userId != null) {
        String endpoint = '/chat/recent/$_userId';
        String currentTab = tab ?? _activeTab;
        if (currentTab.isNotEmpty && currentTab != 'All') {
          endpoint += '?tab=$currentTab';
        }

        final response = await ApiService().get(endpoint);
        debugPrint(
          "HomeScreenController fetchRecentChats: API Response: ${response.data}",
        );

        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true) {
          final List<dynamic> data = json['data'] ?? [];
          
          // Map dynamic list to ConversationModel list
          final List<ConversationModel> models = data.map((item) => ConversationModel.fromJson(item as Map<String, dynamic>)).toList();

          // Update in-memory status and unread counts
          _updateInMemoryCache(data);

          // Save recent chats to SQLite local cache using models
          await LocalDbService().saveConversations(models);
          unawaited(_preFetchChatsHistory(models));

          if (currentTab == _activeTab) {
            _recentChats = data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          }
        } else {
          if (currentTab == _activeTab) {
            _recentChats = [];
          }
        }

        await fetchRequestCount();
      }
    } catch (e) {
      debugPrint("Error fetching recent chats: $e");
      // Do not clear the existing cache if we already have it populated
      if (tab == _activeTab && _recentChats.isEmpty) {
        _recentChats = [];
      }
    } finally {
      if (updateLoadingState) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  String? _userId;
  String? get userId => _userId;

  Future<void> fetchProfileImage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      debugPrint("HomeScreenController: sessionStr: $sessionStr");

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
        _showTypingIndicator = user.showTypingIndicator ?? true;
        debugPrint(
          "HomeScreenController: userId: $_userId, showTypingIndicator: $_showTypingIndicator",
        );

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

  Future<void> fetchAdminAnnouncement() async {
    // Mock fetching admin announcement
    await Future.delayed(const Duration(milliseconds: 400));
    _adminAnnouncement = 'Maintenance scheduled for tonight at 12 AM.';
    notifyListeners();
  }

  Future<void> fetchNotificationCount() async {
    // Mock fetching notification count
    await Future.delayed(const Duration(milliseconds: 200));
    _notificationCount = 5;
    notifyListeners();
  }

  Map<String, dynamic> _unwrapMessage(Map<String, dynamic> rawMsg) {
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

  void _onGlobalMessageReceived() {
    final rawMsg = SocketService().lastReceivedMessageNotifier.value;
    if (rawMsg == null) return; // Ignore null updates

    debugPrint(
      "HomeScreenController: Global message received. Processing real-time unread/message tracking...",
    );

    try {
      final unwrapped = _unwrapMessage(rawMsg);
      final String? senderId =
          unwrapped['sender_id']?.toString() ?? unwrapped['sender']?.toString();
      final String? recipientId =
          unwrapped['recipient_id']?.toString() ??
          unwrapped['recipient']?.toString();
      final String? groupId = unwrapped['group_id']?.toString();

      if (senderId == null) return;

      // Determine chat/conversation ID
      final String chatKey = (groupId != null && groupId.isNotEmpty)
          ? groupId
          : (senderId == _userId ? (recipientId ?? "") : senderId);

      if (chatKey.isEmpty) return;

      final bool isOpen = (SocketService().activeChatId == chatKey);

      // Find the chat in _recentChats
      final int chatIndex = _recentChats.indexWhere((chat) {
        if (chat is Map) {
          final conversation = chat['conversation'];
          if (conversation is Map) {
            final String cid = (conversation['id'] ?? conversation['_id'] ?? '')
                .toString();
            return cid == chatKey;
          }
        }
        return false;
      });

      if (chatIndex != -1) {
        final Map<String, dynamic> chatItem = Map<String, dynamic>.from(
          _recentChats[chatIndex] as Map,
        );

        // Update last message preview
        chatItem['last_message'] = {
          '_id': unwrapped['_id'] ?? unwrapped['id'],
          'content': unwrapped['content'] ?? unwrapped['text'] ?? '',
          'message_type':
              unwrapped['message_type'] ?? unwrapped['type'] ?? 'text',
          'sender_id': senderId,
          'recipient_id': recipientId,
          'group_id': groupId,
          'status': unwrapped['status'] ?? 'sent',
          'created_at':
              unwrapped['created_at'] ??
              unwrapped['createdAt'] ??
              DateTime.now().toIso8601String(),
        };

        // Increment unread count locally if not open
        if (!isOpen) {
          final int newUnread = (_inMemoryUnreadCounts[chatKey] ?? 0) + 1;
          _inMemoryUnreadCounts[chatKey] = newUnread;
          chatItem['unread_count'] = newUnread;
          debugPrint(
            "HomeScreenController: Chat is closed. Incremented unread_count locally to: $newUnread",
          );
        } else {
          _inMemoryUnreadCounts[chatKey] = 0;
          chatItem['unread_count'] = 0;
          debugPrint(
            "HomeScreenController: Chat is open. Kept unread_count at 0.",
          );
        }

        // Move to the top of the list
        _recentChats.removeAt(chatIndex);
        _recentChats.insert(0, chatItem);

        // Save updated conversation details (except unread_count/is_online) in SQLite database cache
        final updatedModel = ConversationModel.fromJson(chatItem);
        LocalDbService().saveSingleConversation(updatedModel);

        notifyListeners();
      } else {
        // Chat not found in local list (new contact/message), reload from server
        debugPrint(
          "HomeScreenController: Chat $chatKey not found in list. Reloading recent chats from server.",
        );
        fetchRecentChats(updateLoadingState: false);
      }
    } catch (e, stack) {
      debugPrint(
        "HomeScreenController: Error processing real-time unread/message tracking: $e\n$stack",
      );
      // Fallback: reload entire list
      fetchRecentChats(updateLoadingState: false);
    }
  }

  void markChatAsReadLocally(String chatId) {
    bool updated = false;
    _inMemoryUnreadCounts[chatId] = 0;
    for (int i = 0; i < _recentChats.length; i++) {
      final chat = _recentChats[i];
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '')
              .toString();
          if (cid == chatId) {
            if (chat['unread_count'] != 0) {
              chat['unread_count'] = 0;
              updated = true;
            }
          }
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void _onUserStatusChange() {
    final data = SocketService().userStatusChangeNotifier.value;
    if (data == null) return;

    final String? userId = data['userId']?.toString();
    final String? status = data['status']?.toString();
    final String? lastSeen = data['lastSeen']?.toString();
    if (userId == null) return;

    _inMemoryOnlineStatus[userId] = (status == 'online');

    debugPrint(
      "HomeScreenController: user-status-change real-time event for $userId: status=$status",
    );

    bool updated = false;
    for (int i = 0; i < _recentChats.length; i++) {
      final chat = _recentChats[i];
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '')
              .toString();
          if (cid == userId) {
            conversation['is_online'] = (status == 'online');
            if (lastSeen != null) {
              conversation['last_seen'] = lastSeen;
            }
            updated = true;
          }
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void _onFriendsStatusSync() {
    final list = SocketService().friendsStatusSyncNotifier.value;
    if (list == null || list.isEmpty) return;

    debugPrint(
      "HomeScreenController: friends_status_sync real-time event with ${list.length} users",
    );

    bool updated = false;
    for (final item in list) {
      if (item is Map) {
        final String? userId = item['userId']?.toString();
        final String? status = item['status']?.toString();
        final String? lastSeen = item['lastSeen']?.toString();
        if (userId == null) continue;

        _inMemoryOnlineStatus[userId] = (status == 'online');

        for (int i = 0; i < _recentChats.length; i++) {
          final chat = _recentChats[i];
          if (chat is Map) {
            final conversation = chat['conversation'];
            if (conversation is Map) {
              final String cid =
                  (conversation['id'] ?? conversation['_id'] ?? '').toString();
              if (cid == userId) {
                conversation['is_online'] = (status == 'online');
                if (lastSeen != null) {
                  conversation['last_seen'] = lastSeen;
                }
                updated = true;
              }
            }
          }
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void _onMessagesRead() {
    final data = SocketService().messagesReadNotifier.value;
    if (data == null) return;

    final String? eventChatId = data['chatId']?.toString();
    if (eventChatId == null) return;

    final String? readerId = data['readerId']?.toString() ?? data['userId']?.toString();
    final String? myUserId = _userId;

    debugPrint(
      "HomeScreenController: messages-read real-time event for chatId=$eventChatId, readerId=$readerId, myUserId=$myUserId.",
    );

    bool updated = false;
    for (int i = 0; i < _recentChats.length; i++) {
      final chat = _recentChats[i];
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '')
              .toString();
          if (cid == eventChatId || cid == readerId) {
            final updatedChat = Map<String, dynamic>.from(chat);
            bool chatUpdated = false;

            // 1. Clear unread count ONLY if the reader was the user themselves
            if (readerId == myUserId) {
              _inMemoryUnreadCounts[eventChatId] = 0;
              if (updatedChat['unread_count'] != 0) {
                updatedChat['unread_count'] = 0;
                chatUpdated = true;
              }
            }

            // 2. Update last message status if it was sent by us and the reader is the recipient
            if (readerId != myUserId && readerId == cid) {
              final lastMsg = updatedChat['last_message'];
              if (lastMsg is Map) {
                final String? senderId =
                    lastMsg['sender_id']?.toString() ??
                    lastMsg['sender']?.toString();
                if (senderId == _userId && lastMsg['status'] != 'read') {
                  final updatedLastMsg = Map<String, dynamic>.from(lastMsg);
                  updatedLastMsg['status'] = 'read';
                  updatedChat['last_message'] = updatedLastMsg;
                  chatUpdated = true;
                }
              }
            }

            if (chatUpdated) {
              _recentChats[i] = updatedChat;
              // Save updated preview to SQLite cache using model
              final updatedModel = ConversationModel.fromJson(updatedChat);
              LocalDbService().saveSingleConversation(updatedModel);
              updated = true;
            }
          }
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void _onMessagesDelivered() {
    final data = SocketService().messagesDeliveredNotifier.value;
    if (data == null) return;

    final String? eventRecipientId = data['recipientId']?.toString();
    if (eventRecipientId == null) return;

    debugPrint(
      "HomeScreenController: messages-delivered real-time event for recipientId=$eventRecipientId. Updating last message status to 'delivered'.",
    );

    bool updated = false;
    for (int i = 0; i < _recentChats.length; i++) {
      final chat = _recentChats[i];
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '')
              .toString();
          if (cid == eventRecipientId) {
            final updatedChat = Map<String, dynamic>.from(chat);
            bool chatUpdated = false;

            // Update last message status if it was sent by us and is 'sent'
            final lastMsg = updatedChat['last_message'];
            if (lastMsg is Map) {
              final String? senderId =
                  lastMsg['sender_id']?.toString() ??
                  lastMsg['sender']?.toString();
              final currentStatus = lastMsg['status'];
              if (senderId == _userId && (currentStatus == null || currentStatus == 'sent')) {
                final updatedLastMsg = Map<String, dynamic>.from(lastMsg);
                updatedLastMsg['status'] = 'delivered';
                updatedChat['last_message'] = updatedLastMsg;
                chatUpdated = true;
              }
            }

            if (chatUpdated) {
              _recentChats[i] = updatedChat;
              // Save updated preview to SQLite cache using model
              final updatedModel = ConversationModel.fromJson(updatedChat);
              LocalDbService().saveSingleConversation(updatedModel);
              updated = true;
            }
          }
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  String? getTypingIndicatorText(String chatId) {
    final users = _typingUsers[chatId];
    if (users == null || users.isEmpty) return null;

    // Find the chat in recent chats to see if it is a group chat
    bool isGroup = false;
    for (final chat in _recentChats) {
      if (chat is Map) {
        final conversation = chat['conversation'];
        if (conversation is Map) {
          final String cid = (conversation['id'] ?? conversation['_id'] ?? '')
              .toString();
          if (cid == chatId) {
            isGroup = conversation['type'] == 'group';
            break;
          }
        }
      }
    }

    if (!isGroup) {
      // For personal chats, just show "typing" as requested by user
      return "typing...";
    } else {
      // For group chats, show the user's name
      if (users.length == 1) {
        return "${users.first} is typing...";
      } else {
        return "${users.first} and ${users.length - 1} others are typing...";
      }
    }
  }

  void _onTypingIndicatorChanged() async {
    final data = SocketService().typingIndicatorNotifier.value;
    if (data == null) return;



    final String? chatId = data['chatId']?.toString();
    final String? eventUserId = data['userId']?.toString();
    final bool? isTyping = data['isTyping'] as bool?;
    String? userName = data['userName']?.toString();

    if (chatId == null || eventUserId == null || isTyping == null) return;

    // Don't show typing status for our own actions
    if (eventUserId == _userId) return;

    // Cache or resolve userName
    if (userName != null && userName.isNotEmpty) {
      _userIdToName[eventUserId] = userName;
    } else {
      userName = _userIdToName[eventUserId];
    }

    if (userName == null || userName.isEmpty) {
      // Robust lookup: Search in recent chats conversation names
      for (final chat in _recentChats) {
        if (chat is Map) {
          final conversation = chat['conversation'];
          if (conversation is Map) {
            final String cid = (conversation['id'] ?? conversation['_id'] ?? '').toString();
            if (cid == eventUserId) {
              userName = conversation['name']?.toString();
              break;
            }
          }
        }
      }
    }

    if (userName == null || userName.isEmpty) {
      userName = "Someone";
    }

    if (isTyping) {
      _typingUsers.putIfAbsent(chatId, () => {}).add(userName);
    } else {
      _typingUsers[chatId]?.remove(userName);
      if (_typingUsers[chatId]?.isEmpty == true) {
        _typingUsers.remove(chatId);
      }
    }
    notifyListeners();
  }

  Future<void> _preFetchChatsHistory(List<ConversationModel> conversations) async {
    final String? currentUserId = _userId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    for (final chat in conversations) {
      final String chatId = (chat.conversation?.id).toString();
      if (chatId.isEmpty || chatId == 'null') continue;

      try {
        // Only pre-fetch if we don't already have cached messages in the local SQLite DB
        final List<Map<String, dynamic>> localMessages = await LocalDbService().getMessages(
          chatId,
          limit: 1,
          offset: 0,
        );

        if (localMessages.isEmpty) {
          final String chatType = chat.conversation?.type?.toString() ?? 'personal';
          
          if (chatType == 'group') {
            final response = await ApiService().get(
              '/chat/history?group_id=$chatId&requesterId=$currentUserId&page=1&limit=20',
            );
            final dynamic responseData = response.data;
            final Map<String, dynamic> json = responseData is String
                ? jsonDecode(responseData)
                : responseData as Map<String, dynamic>;

            if (json['success'] == true) {
              final List<dynamic> data = json['data'] ?? [];
              await LocalDbService().saveMessages(chatId, data);
            }
          } else {
            final response = await ApiService().get(
              '/chat/history?user1=$currentUserId&user2=$chatId&page=1&limit=50',
            );
            final dynamic responseData = response.data;
            final Map<String, dynamic> json = responseData is String
                ? jsonDecode(responseData)
                : responseData as Map<String, dynamic>;

            if (json['success'] == true) {
              final List<dynamic> data = json['data'] ?? [];
              await LocalDbService().saveMessages(chatId, data);
            }
          }
        }
      } catch (e) {
        debugPrint("Error pre-fetching history for chat $chatId: $e");
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    SocketService().lastReceivedMessageNotifier.removeListener(
      _onGlobalMessageReceived,
    );
    SocketService().userStatusChangeNotifier.removeListener(
      _onUserStatusChange,
    );
    SocketService().friendsStatusSyncNotifier.removeListener(
      _onFriendsStatusSync,
    );
    SocketService().messagesReadNotifier.removeListener(_onMessagesRead);
    SocketService().messagesDeliveredNotifier.removeListener(_onMessagesDelivered);
    SocketService().typingIndicatorNotifier.removeListener(
      _onTypingIndicatorChanged,
    );
    super.dispose();
  }
}
