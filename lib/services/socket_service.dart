import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';

class SocketService {
  static const String socketUrl =
      "https://shield-connect-api-new-production.up.railway.app/";

  // Thread-safe Singleton Instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  sio.Socket? _socket;
  sio.Socket? get socket => _socket;

  bool? _showTypingIndicatorCache;
  bool? get showTypingIndicatorCache => _showTypingIndicatorCache;
  set showTypingIndicatorCache(bool? val) => _showTypingIndicatorCache = val;

  bool? _showReadReceiptsCache;
  bool? get showReadReceiptsCache => _showReadReceiptsCache;
  set showReadReceiptsCache(bool? val) => _showReadReceiptsCache = val;

  /// The ID of the currently active personal chat (recipientId) or group chat (groupId).
  String? activeChatId;

  /// True if the currently active chat is a group chat.
  bool isActiveChatGroup = false;

  // ─── Public Notifiers ────────────────────────────────────────────────────────

  /// True while the socket is connected.
  final ValueNotifier<bool> connectionNotifier = ValueNotifier(false);

  /// Fires once per incoming message. Listeners must drain the queue each tick.
  final ValueNotifier<List<Map<String, dynamic>>> messageQueueNotifier =
      ValueNotifier([]);

  /// Fires whenever a new message is received. Holds the last received message.
  final ValueNotifier<Map<String, dynamic>?> lastReceivedMessageNotifier =
      ValueNotifier(null);

  /// Fires whenever a user status changes (online/offline).
  final ValueNotifier<Map<String, dynamic>?> userStatusChangeNotifier =
      ValueNotifier(null);

  /// Fires when friends status sync payload is received.
  final ValueNotifier<List<dynamic>?> friendsStatusSyncNotifier = ValueNotifier(
    null,
  );

  /// Fires when messages are read in a chat.
  final ValueNotifier<Map<String, dynamic>?> messagesReadNotifier =
      ValueNotifier(null);

  /// Fires when messages are delivered in a chat.
  final ValueNotifier<Map<String, dynamic>?> messagesDeliveredNotifier =
      ValueNotifier(null);

  /// Fires when a user starts or stops typing.
  final ValueNotifier<Map<String, dynamic>?> typingIndicatorNotifier =
      ValueNotifier(null);

  /// Fires when a new connection request is received.
  final ValueNotifier<Map<String, dynamic>?> connectionRequestNotifier =
      ValueNotifier(null);

  /// Fires when a new system/support notification is received.
  final ValueNotifier<Map<String, dynamic>?> newNotificationNotifier =
      ValueNotifier(null);

  /// Fires when a moderation violation is received.
  final ValueNotifier<Map<String, dynamic>?> moderationViolationNotifier =
      ValueNotifier(null);

  // ─── Getters ─────────────────────────────────────────────────────────────────
  bool get isConnected => _socket?.connected ?? false;

  // ─── Connect ─────────────────────────────────────────────────────────────────

  /// Call this as soon as the user logs in (or app resumes).
  void connect(String userId) {
    if (_socket != null && _socket!.connected) {
      dev.log('🔌 SOCKET: already connected for $userId');
      return;
    }

    // If the socket object exists but is disconnected, just reconnect it.
    if (_socket != null) {
      dev.log('🔌 SOCKET: reconnecting existing socket for $userId');
      _socket!.connect();
      return;
    }

    dev.log('🔌 SOCKET: creating new socket for $userId');

    final Map<String, dynamic> socketOptions = sio.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(double.infinity)
        .setReconnectionDelay(1000)
        .setQuery({'userId': userId})
        .build();

    // Custom configuration parameters to align with backend infrastructure
    socketOptions['reconnectionDelayMax'] = 5000;
    socketOptions['timeout'] = 20000;

    _socket = sio.io(socketUrl, socketOptions);

    // Update connectionNotifier state
    _socket!.onConnect((_) async {
      connectionNotifier.value = true;
      dev.log('🔌 SOCKET: Connected successfully. Socket ID: ${_socket?.id}');

      String? realFcmToken;
      try {
        realFcmToken = await FirebaseMessaging.instance.getToken();
        dev.log(
          '🔌 SOCKET: Successfully fetched real FCM token: $realFcmToken',
        );
      } catch (e) {
        dev.log(
          '⚠️ SOCKET: Error or Firebase not initialized while fetching FCM token: $e',
        );
      }

      // Register user on connect with their real FCM token
      _socket!.emit('register', {
        'userId': userId,
        'fcmToken': realFcmToken ?? 'default_fcm_token',
      });
      dev.log(
        '🔌 SOCKET: Emitted register event for user: $userId with fcmToken: ${realFcmToken ?? "default_fcm_token"}',
      );
    });

    _socket!.onDisconnect((_) {
      connectionNotifier.value = false;
      dev.log('🔌 SOCKET: Disconnected');
    });

    _socket!.onConnectError((data) {
      connectionNotifier.value = false;
      dev.log('🔌 SOCKET: Connection error: $data');
    });

    _socket!.onError((data) {
      dev.log('🔌 SOCKET: Socket error: $data');
    });

    // ── Incoming message ──────────────────────────────────────────────────────
    void handleIncomingMessage(dynamic data, String eventName) {
      try {
        dev.log('📩 SOCKET $eventName raw payload: $data');
        if (data == null) {
          dev.log('⚠️ SOCKET $eventName: data is null');
          return;
        }

        Map<String, dynamic> msg;
        if (data is String) {
          msg = Map<String, dynamic>.from(json.decode(data) as Map);
        } else if (data is Map) {
          msg = Map<String, dynamic>.from(data);
        } else {
          dev.log('⚠️ SOCKET $eventName unknown type: ${data.runtimeType}');
          return;
        }

        dev.log('📩 SOCKET $eventName parsed successfully: $msg');

        // Notify global/independent listeners immediately without queue clear conflicts
        lastReceivedMessageNotifier.value = msg;

        // Append to queue — ChatController drains it.
        messageQueueNotifier.value = [...messageQueueNotifier.value, msg];
      } catch (e, stack) {
        dev.log('🚨 SOCKET $eventName error: $e\n$stack');
      }
    }

    _socket!.on('new-message', (data) {
      dynamic payload = data;
      dynamic ack;

      if (data is List && data.isNotEmpty) {
        payload = data[0];
        if (data.length > 1) {
          ack = data[1];
        }
      }

      handleIncomingMessage(payload, 'new-message');

      if (ack != null && ack is Function) {
        try {
          ack({'status': 'ok'});
          dev.log('🔌 SOCKET: Sent ACK status: ok for new-message');
        } catch (e) {
          dev.log('🚨 SOCKET new-message ACK error: $e');
        }
      }
    });
    _socket!.on(
      'receive-message',
      (data) => handleIncomingMessage(data, 'receive-message'),
    );

    _socket!.on('user-status-change', (data) {
      dev.log('🔌 SOCKET: user-status-change event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        userStatusChangeNotifier.value = Map<String, dynamic>.from(payload);
      }
    });

    _socket!.on('friends_status_sync', (data) {
      dev.log('🔌 SOCKET: friends_status_sync event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is List) {
        friendsStatusSyncNotifier.value = List<dynamic>.from(payload);
      } else if (payload is Map) {
        friendsStatusSyncNotifier.value = [payload];
      }
    });

    _socket!.on('messages-read', (data) {
      dev.log('🔌 SOCKET: messages-read event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        messagesReadNotifier.value = Map<String, dynamic>.from(payload);
      }
    });

    _socket!.on('messages-delivered', (data) {
      dev.log('🔌 SOCKET: messages-delivered event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        messagesDeliveredNotifier.value = Map<String, dynamic>.from(payload);
      }
    });

    _socket!.on('typing', (data) {
      dev.log('🔌 SOCKET: typing event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        map['isTyping'] = true;
        typingIndicatorNotifier.value = map;
      }
    });

    _socket!.on('stop-typing', (data) {
      dev.log('🔌 SOCKET: stop-typing event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        map['isTyping'] = false;
        typingIndicatorNotifier.value = map;
      }
    });

    _socket!.on('connection-request', (data) {
      dev.log('🔌 SOCKET: connection-request event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        connectionRequestNotifier.value = Map<String, dynamic>.from(payload);
      }
    });

    _socket!.on('new-notification', (data) {
      dev.log('🔌 SOCKET: new-notification event: $data');
      dynamic payload = data;
      if (data is List && data.isNotEmpty) {
        payload = data[0];
      }
      if (payload is Map) {
        newNotificationNotifier.value = Map<String, dynamic>.from(payload);
      }
    });

    _socket!.on('moderation_violation', (data) {
      dev.log('🔌 SOCKET: moderation_violation event: $data');
      try {
        dynamic payload = data;
        if (data is List && data.isNotEmpty) {
          payload = data[0];
        }
        if (payload is Map) {
          moderationViolationNotifier.value = Map<String, dynamic>.from(
            payload,
          );
        }
      } catch (e) {
        dev.log('🚨 SOCKET moderation_violation error: $e');
      }
    });
  }

  /// Listen to a custom event from the server.
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      dev.log(
        "SocketService: Cannot listen to '$event'. Socket is not initialized.",
        name: "SocketService",
      );
      return;
    }
    dev.log(
      "SocketService: Registering listener for event '$event'",
      name: "SocketService",
    );
    _socket!.on(event, callback);
  }

  /// Stop listening to a custom event from the server.
  void off(String event) {
    if (_socket == null) {
      dev.log(
        "SocketService: Cannot remove listener for '$event'. Socket is not initialized.",
        name: "SocketService",
      );
      return;
    }
    dev.log(
      "SocketService: Removing listener for event '$event'",
      name: "SocketService",
    );
    _socket!.off(event);
  }

  /// Emit an event with dynamic payload to the server.
  void emit(String event, [dynamic data]) {
    if (_socket == null) {
      dev.log(
        "SocketService: Cannot emit '$event'. Socket is not initialized.",
        name: "SocketService",
      );
      return;
    }
    if (!_socket!.connected) {
      dev.log(
        "SocketService: Warning: Emitting '$event' while socket is not connected.",
        name: "SocketService",
      );
    }
    dev.log(
      "SocketService: Emitting event '$event' with data: $data",
      name: "SocketService",
    );
    _socket!.emit(event, data);
  }

  /// Emit the 'mark-as-read' socket event if read receipts are enabled in privacy settings.
  Future<void> markAsRead({
    required String chatId,
    required String userId,
    required String otherId,
    required bool isGroup,
  }) async {
    bool showReadReceipts = true;
    if (_showReadReceiptsCache != null) {
      showReadReceipts = _showReadReceiptsCache!;
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(sessionStr);
          final UserModel user = UserModel.fromJson(userMap);
          final String? uId = user.id;
          if (uId != null && uId.isNotEmpty) {
            final response = await ApiService().get('/users/$uId?currentUserId=$uId');
            final dynamic responseData = response.data;
            final Map<String, dynamic> json = responseData is String
                ? jsonDecode(responseData)
                : responseData as Map<String, dynamic>;
            if (json['success'] == true && json['data'] != null) {
              final val = json['data']['show_read_receipts'] as bool? ?? true;
              _showReadReceiptsCache = val;
              showReadReceipts = val;
            }
          }
        } catch (e) {
          dev.log('Error fetching user profile for read receipts: $e');
        }
      }
    }

    if (showReadReceipts == false) {
      dev.log(
        '🔌 SOCKET: Suppression of mark-as-read since show_read_receipts is false',
      );
      return;
    }

    emit('mark-as-read', {
      'chatId': chatId,
      'userId': userId,
      'otherId': otherId,
      'isGroup': isGroup,
    });
    dev.log('🔌 SOCKET: Emitted mark-as-read for chatId: $chatId');
  }

  /// Fetch user setting to see if typing indicators are enabled
  Future<bool> getShowTypingIndicatorSetting() async {
    if (_showTypingIndicatorCache != null) {
      return _showTypingIndicatorCache!;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        final String? userId = user.id;
        if (userId != null && userId.isNotEmpty) {
          final response = await ApiService().get(
            '/users/$userId?currentUserId=$userId',
          );
          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;
          if (json['success'] == true && json['data'] != null) {
            final val = json['data']['show_typing_indicator'] as bool? ?? true;
            _showTypingIndicatorCache = val;
            return val;
          }
        }
      } catch (e) {
        dev.log('Error fetching user profile for typing indicator: $e');
      }
    }
    return true;
  }

  /// Emit the 'typing' or 'stop-typing' event if typing indicators are enabled.
  Future<void> emitTypingStatus({
    required String chatId,
    required String userId,
    required String userName,
    required bool isGroup,
    required bool isTyping,
  }) async {
    final bool showTyping = await getShowTypingIndicatorSetting();
    if (!showTyping) {
      dev.log(
        '🔌 SOCKET: Suppression of typing indicator emission since show_typing_indicator is false',
      );
      return;
    }

    final String eventName = isTyping ? 'typing' : 'stop-typing';
    emit(eventName, {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'isGroup': isGroup,
    });
    dev.log('🔌 SOCKET: Emitted $eventName for chatId: $chatId');
  }

  /// Disconnects the socket and disposes resources.
  void disconnect() {
    _showTypingIndicatorCache = null;
    _showReadReceiptsCache = null;
    if (_socket == null) return;
    dev.log("SocketService: Disconnecting socket...", name: "SocketService");
    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
    connectionNotifier.value = false;
    userStatusChangeNotifier.value = null;
    friendsStatusSyncNotifier.value = null;
    messagesReadNotifier.value = null;
    messagesDeliveredNotifier.value = null;
    typingIndicatorNotifier.value = null;
    connectionRequestNotifier.value = null;
    newNotificationNotifier.value = null;
    moderationViolationNotifier.value = null;
    dev.log(
      "SocketService: Socket disconnected and cleaned up.",
      name: "SocketService",
    );
  }
}
