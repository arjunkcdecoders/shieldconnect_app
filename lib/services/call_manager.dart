import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart' as ck_event;
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
import 'package:shieldconnect_app/services/room_manager.dart';
import 'package:shieldconnect_app/main.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';
import 'package:shieldconnect_app/view/voice_call_receiving_screen.dart';
import 'package:shieldconnect_app/view/video_call_receiving_screen.dart';

import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:audioplayers/audioplayers.dart';

enum CallState { idle, dialing, ringing, connected }

class CallManager extends ChangeNotifier {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal() {
    _initCallKitListener();
    roomManager.addListener(notifyListeners);
  }

  final RoomManager roomManager = RoomManager();
  final ApiService _apiService = ApiService();

  CallState _state = CallState.idle;
  CallState get state => _state;

  String? _currentCallId;
  String? get currentCallId => _currentCallId;

  String? _currentRoomId;
  String? get currentRoomId => _currentRoomId;

  String? _callerId;
  String? get callerId => _callerId;

  String? _receiverId;
  String? get receiverId => _receiverId;

  String? _receiverName;
  String? get receiverName => _receiverName;

  final Map<String, bool> _mutedParticipants = {};
  Map<String, bool> get mutedParticipants => _mutedParticipants;

  String? _receiverAvatar;
  String? get receiverAvatar => _receiverAvatar;

  bool _isVideo = false;
  bool get isVideo => _isVideo;
  bool _isGroup = false;
  bool get isGroup => _isGroup;

  Timer? _durationTimer;
  int _secondsElapsed = 0;
  String _callDuration = "00:00";
  String get callDuration => _callDuration;
  int get secondsElapsed => _secondsElapsed;

  String? _myUserId;
  String? get myUserId => _myUserId;
  String? _myUserName;
  String? get myUserName => _myUserName;
  String? _myUserAvatar;
  String? get myUserAvatar => _myUserAvatar;
  int _incomingParticipantsCount = 0;
  int get incomingParticipantsCount => _incomingParticipantsCount;

  // Track global navigation pushing states
  bool _isCallScreenPushed = false;
  bool _isReceivingScreenPushed = false;
  bool _isHandlingCallAction = false;
  bool _isMinimized = false;
  bool get isMinimized => _isMinimized;

  AudioPlayer? _dialTonePlayer;
  AudioPlayer? _ringTonePlayer;

  void _startDialTone() async {
    try {
      if (_dialTonePlayer == null) {
        _dialTonePlayer = AudioPlayer();
        await _dialTonePlayer!.setReleaseMode(ReleaseMode.loop);
        await _dialTonePlayer!.play(AssetSource('audio/calling_tone.mp3'));
        dev.log(
          '📞 CallManager: Started playing dialing/calling tone loop.',
          name: 'CallManager',
        );
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error starting dial tone: $e',
        name: 'CallManager',
        error: e,
      );
    }
  }

  void _stopDialTone() async {
    try {
      if (_dialTonePlayer != null) {
        final player = _dialTonePlayer;
        _dialTonePlayer = null;
        await player!.stop();
        await player.dispose();
        dev.log(
          '📞 CallManager: Stopped dialing/calling tone.',
          name: 'CallManager',
        );
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error stopping dial tone: $e',
        name: 'CallManager',
        error: e,
      );
    }
  }

  void _startRingTone() async {
    try {
      if (_ringTonePlayer == null) {
        _ringTonePlayer = AudioPlayer();
        await _ringTonePlayer!.setReleaseMode(ReleaseMode.loop);
        await _ringTonePlayer!.play(AssetSource('audio/ringing_tone.mp3'));
        dev.log(
          '📞 CallManager: Started playing ringing tone loop.',
          name: 'CallManager',
        );
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error starting ring tone: $e',
        name: 'CallManager',
        error: e,
      );
    }
  }

  void _stopRingTone() async {
    try {
      if (_ringTonePlayer != null) {
        final player = _ringTonePlayer;
        _ringTonePlayer = null;
        await player!.stop();
        await player.dispose();
        dev.log('📞 CallManager: Stopped ringing tone.', name: 'CallManager');
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error stopping ring tone: $e',
        name: 'CallManager',
        error: e,
      );
    }
  }

  void setMinimized(bool val) {
    if (_isMinimized != val) {
      _isMinimized = val;
      if (val) {
        _isCallScreenPushed = false;
        _isReceivingScreenPushed = false;
      } else {
        _isCallScreenPushed = true;
      }
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _callHistory = [];
  List<Map<String, dynamic>> get callHistory => _callHistory;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  Map<String, Map<String, dynamic>> _activeGroupCalls = {};
  Map<String, Map<String, dynamic>> get activeGroupCalls => _activeGroupCalls;

  Timer? _activeCallsRefreshTimer;

  /// Initialize and register Socket.IO call signaling event listeners.
  /// Call this when the user is logged in.
  Future<void> init(
    String myUserId,
    String myUserName, {
    String? myUserAvatar,
  }) async {
    _myUserId = myUserId;
    _myUserName = myUserName;
    _myUserAvatar = myUserAvatar;

    // Clear old socket listeners first to avoid duplicates
    disposeListeners();

    // Register Socket.IO listeners
    final socketService = SocketService();

    socketService.on('incoming_call', _handleIncomingCallEvent);
    socketService.on('call_accepted', _handleCallAcceptedEvent);
    socketService.on('call_rejected', _handleCallRejectedEvent);
    socketService.on('call_ended', _handleCallEndedEvent);
    socketService.on('group_call_ended', _handleGroupCallEndedEvent);
    socketService.on('group_call_status_update', _handleGroupCallStatusUpdate);
    socketService.on('call_state_snapshot', _handleCallStateSnapshot);
    socketService.on('user_mute_status_update', _handleUserMuteStatusUpdate);

    // Initial history and active call pools fetch
    fetchCallHistory();
    fetchActiveGroupCalls();
    _startActiveCallsTimer();

    dev.log('📞 CallManager: Initialized for $myUserId', name: 'CallManager');
  }

  /// Clean up and remove signaling socket listeners.
  void disposeListeners() {
    final socketService = SocketService();
    socketService.off('incoming_call');
    socketService.off('call_accepted');
    socketService.off('call_rejected');
    socketService.off('call_ended');
    socketService.off('group_call_ended');
    socketService.off('group_call_status_update');
    socketService.off('call_state_snapshot');
    socketService.off('user_mute_status_update');
  }

  // ─── Callkit Actions Stream ───────────────────────────────────────────────

  void _initCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      dev.log(
        '📞 CallManager: Received CallKit Event: ${event.eventName}',
        name: 'CallManager',
      );

      switch (event) {
        case ck_event.CallEventActionCallAccept():
          final callId = event.id;
          var roomId = _currentRoomId;
          var callerId = _callerId;
          var isVideoCall = _isVideo;
          var callerName = _receiverName;
          var isGroupCall = _isGroup;
          var groupNameVal = _receiverName;
          var groupAvatarVal = _receiverAvatar;

          try {
            final activeCalls = await FlutterCallkitIncoming.activeCalls();
            for (final call in activeCalls) {
              if (call.id == callId) {
                roomId = call.extra?['roomId']?.toString() ?? roomId;
                callerId = call.extra?['callerId']?.toString() ?? callerId;
                isVideoCall =
                    call.extra?['isVideo'] == true ||
                    call.extra?['isVideo'] == 'true' ||
                    isVideoCall;
                isGroupCall =
                    call.extra?['isGroup'] == true ||
                    call.extra?['isGroup'] == 'true' ||
                    isGroupCall;
                groupNameVal =
                    call.extra?['groupName']?.toString() ?? groupNameVal;
                groupAvatarVal =
                    call.extra?['groupAvatar']?.toString() ?? groupAvatarVal;
                callerName = call.nameCaller ?? callerName;
                break;
              }
            }
          } catch (e) {
            dev.log(
              '📞 CallManager: Error fetching active calls: $e',
              name: 'CallManager',
              error: e,
            );
          }

          dev.log(
            '📞 CallManager: CallKit Accept for room: $roomId',
            name: 'CallManager',
          );
          if (roomId != null) {
            _currentCallId = callId;
            _currentRoomId = roomId;
            _callerId = callerId;
            _receiverId = _myUserId;
            _isGroup = isGroupCall;
            _receiverName = isGroupCall
                ? (groupNameVal ?? callerName)
                : callerName;
            _receiverAvatar = groupAvatarVal;
            _isVideo = isVideoCall;
            await acceptCall();
          }
          break;

        case ck_event.CallEventActionCallDecline():
          final callId = event.id;
          var roomId = _currentRoomId;

          if (_state == CallState.connected) {
            dev.log(
              '📞 CallManager: Ignoring CallKit Decline event because call is already connected.',
              name: 'CallManager',
            );
            break;
          }

          try {
            final activeCalls = await FlutterCallkitIncoming.activeCalls();
            for (final call in activeCalls) {
              if (call.id == callId) {
                roomId = call.extra?['roomId']?.toString() ?? roomId;
                break;
              }
            }
          } catch (e) {
            dev.log(
              '📞 CallManager: Error fetching active calls: $e',
              name: 'CallManager',
              error: e,
            );
          }

          dev.log(
            '📞 CallManager: CallKit Decline for room: $roomId',
            name: 'CallManager',
          );
          if (roomId != null) {
            _currentCallId = callId;
            _currentRoomId = roomId;
            await declineCall();
          }
          break;

        default:
          break;
      }
    });
  }

  // ─── Outgoing Call Flow ───────────────────────────────────────────────────

  /// Initiates an audio or video call with another user.
  Future<void> startCall(
    String recipientId,
    String recipientName, {
    bool isVideo = false,
    String? recipientAvatar,
    bool isGroup = false,
    List<String>? groupMemberIds,
  }) async {
    if (_myUserId == null) return;
    _isMinimized = false;

    // Load latest avatar/profile info from local storage cache
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userSession = prefs.getString('user_session');
      if (userSession != null) {
        final Map<String, dynamic> userMap = jsonDecode(userSession);
        _myUserAvatar = userMap['avatar']?.toString() ?? _myUserAvatar;
        _myUserName = userMap['name']?.toString() ?? _myUserName;
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error fetching session for startCall: $e',
        name: 'CallManager',
      );
    }

    // Request microphone permission at runtime before initiating a call
    final hasMicPermission = await _requestMicrophonePermission();
    if (!hasMicPermission) {
      dev.log(
        '⚠️ CallManager: Microphone permission denied. Cannot initiate call.',
        name: 'CallManager',
      );
      return;
    }

    _state = CallState.dialing;
    _callerId = _myUserId;
    _receiverId = recipientId;
    _receiverName = recipientName;
    _receiverAvatar = recipientAvatar;
    _isVideo = isVideo;
    _isGroup = isGroup;
    _currentRoomId =
        "room_${_myUserId}_${recipientId}_${DateTime.now().millisecondsSinceEpoch}";
    _currentCallId =
        "call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";
    notifyListeners();
    _startDialTone();

    try {
      dev.log(
        '📞 CallManager: Initiating call over REST...',
        name: 'CallManager',
      );

      final Map<String, dynamic> postData = {
        'initiator_id': _myUserId,
        'receiver_id': recipientId,
        'receiver_ids':
            (isGroup && groupMemberIds != null && groupMemberIds.isNotEmpty)
            ? groupMemberIds
            : [recipientId],
        'call_type': isVideo ? 'video' : 'audio',
      };

      if (isGroup) {
        postData['group_name'] = recipientName;
        postData['group_id'] = recipientId;
        postData['group_avatar'] = recipientAvatar ?? "";
        postData['is_group'] = true;
      }

      final response = await _apiService.post('/call/initiate', data: postData);

      String? serverCallId = _findCallIdInResponse(response.data);

      dev.log(
        '📞 CallManager: initiate response parsed serverCallId: $serverCallId from response: ${response.data}',
        name: 'CallManager',
      );

      if (serverCallId != null && serverCallId.isNotEmpty) {
        _currentCallId = serverCallId;
        _currentRoomId = serverCallId;
      }

      final List<String> pIds = [_myUserId ?? ''];
      final List<String> pNames = [_myUserName ?? 'User'];

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final List? receivers = data['receiver_ids'] ?? data['receivers'];
        if (receivers != null) {
          for (var r in receivers) {
            if (r != null) {
              final String rId = r.toString();
              if (rId.isNotEmpty && !pIds.contains(rId)) {
                pIds.add(rId);
              }
            }
          }
        }
        final List? participantsList = data['participants'];
        if (participantsList != null) {
          for (var p in participantsList) {
            if (p is Map) {
              final String? pId = (p['user_id'] ?? p['id'] ?? p['_id'])
                  ?.toString();
              final String? pName = (p['name'] ?? p['username'])?.toString();
              if (pId != null && pId.isNotEmpty && !pIds.contains(pId)) {
                pIds.add(pId);
              }
              if (pName != null &&
                  pName.isNotEmpty &&
                  !pNames.contains(pName)) {
                pNames.add(pName);
              }
            }
          }
        }
      }

      if (!isGroup) {
        if (!pIds.contains(recipientId)) {
          pIds.add(recipientId);
        }
        if (!pNames.contains(recipientName)) {
          pNames.add(recipientName);
        }
      } else if (groupMemberIds != null) {
        for (var id in groupMemberIds) {
          if (!pIds.contains(id)) {
            pIds.add(id);
          }
        }
      }

      dev.log(
        '📞 CallManager: Emitting call_user signaling socket event with callId: $_currentCallId, participantIds: $pIds, participantNames: $pNames, count: ${pIds.length}...',
        name: 'CallManager',
      );

      final Map<String, dynamic> socketData = {
        'callId': _currentCallId,
        'roomId': _currentRoomId,
        'callerId': _myUserId,
        'callerName': _myUserName,
        'callerAvatar': _myUserAvatar,
        'receiverId': recipientId,
        'receiverIds':
            (isGroup && groupMemberIds != null && groupMemberIds.isNotEmpty)
            ? groupMemberIds
            : [recipientId],
        'isVideo': isVideo,
        'isGroup': isGroup,
        'groupName': isGroup ? recipientName : "",
        'group_name': isGroup ? recipientName : "",
        'groupAvatar': isGroup ? recipientAvatar : "",
        'group_avatar': isGroup ? recipientAvatar : "",
        'participantIds': pIds,
        'participantNames': pNames,
        'participantsCount': pIds.length,
      };

      SocketService().emit('call_user', socketData);

      _isCallScreenPushed =
          true; // Mark call screen as pushed so we pop on hangup

      if (isVideo) {
        dev.log(
          '📞 CallManager: Starting local camera and connecting to LiveKit room immediately for caller camera preview during dialing.',
          name: 'CallManager',
        );
        roomManager.startLocalCamera();
        _connectLiveKitRoom();
      }

      // Start locally ringing/dialing timeout (e.g. 30 seconds wait)
      _startDialTimer();
    } catch (e) {
      dev.log(
        '🚨 CallManager: Failed to initiate call: $e',
        name: 'CallManager',
        error: e,
      );
      _cleanupCall();
    }
  }

  // ─── Incoming Call Flow ───────────────────────────────────────────────────

  /// Triggered via WebSocket signal
  void _handleIncomingCallEvent(dynamic data) async {
    dev.log(
      '📞 CallManager: Received incoming_call Socket event payload: $data',
      name: 'CallManager',
    );
    if (data == null || _state != CallState.idle) return;

    Map<dynamic, dynamic> map = {};
    if (data is Map) {
      map = data;
    } else if (data is List && data.isNotEmpty && data[0] is Map) {
      map = data[0] as Map;
    } else {
      try {
        final decoded = jsonDecode(data.toString());
        if (decoded is Map) {
          map = decoded;
        } else if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
          map = decoded[0] as Map;
        }
      } catch (e) {
        dev.log(
          '🚨 CallManager: Error decoding socket payload: $e',
          name: 'CallManager',
          error: e,
        );
      }
    }

    _callerId = map['callerId']?.toString();
    _isVideo = map['isVideo'] == true || map['isVideo'] == 'true';
    _isGroup =
        map['isGroup'] == true ||
        map['isGroup'] == 'true' ||
        map['is_group'] == true ||
        map['is_group'] == 'true' ||
        (map['groupName'] != null && map['groupName'].toString().isNotEmpty) ||
        (map['group_name'] != null &&
            map['group_name'].toString().isNotEmpty) ||
        (map['groupId'] != null && map['groupId'].toString().isNotEmpty) ||
        (map['group_id'] != null && map['group_id'].toString().isNotEmpty);
    _receiverName = _isGroup
        ? (map['groupName']?.toString() ??
              map['group_name']?.toString() ??
              map['callerName']?.toString())
        : map['callerName']?.toString();
    final String? callerAv = map['callerAvatar']?.toString();
    final String? groupAv =
        map['groupAvatar']?.toString() ?? map['group_avatar']?.toString();
    _receiverAvatar = _isGroup
        ? (groupAv == null ||
                  groupAv == 'null' ||
                  groupAv.isEmpty ||
                  groupAv == callerAv
              ? null
              : groupAv)
        : (callerAv ?? map['receiverAvatar']?.toString());
    _currentRoomId = map['roomId']?.toString();
    _currentCallId = map['callId']?.toString();
    _receiverId = _myUserId;
    int derivedCount = 0;
    List<String> participantIds = [];
    if (map['participantIds'] != null) {
      final pIds = map['participantIds'];
      if (pIds is List) {
        participantIds = pIds.map((e) => e.toString()).toList();
      } else if (pIds is String) {
        try {
          final decoded = jsonDecode(pIds);
          if (decoded is List) {
            participantIds = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }
    if (participantIds.isEmpty && map['receiverIds'] != null) {
      final rIds = map['receiverIds'];
      if (rIds is List) {
        participantIds = rIds.map((e) => e.toString()).toList();
      } else if (rIds is String) {
        try {
          final decoded = jsonDecode(rIds);
          if (decoded is List) {
            participantIds = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      final String? cId = map['callerId']?.toString();
      if (cId != null && cId.isNotEmpty && !participantIds.contains(cId)) {
        participantIds.insert(0, cId);
      }
    }

    if (participantIds.isNotEmpty) {
      // Exclude newly added user (ourselves) from the active count during incoming call
      if (_myUserId != null) {
        participantIds.removeWhere((id) => id == _myUserId);
      }
      derivedCount = participantIds.length;
    } else if (map['participantNames'] != null) {
      final pNames = map['participantNames'];
      List<String> names = [];
      if (pNames is List) {
        names = pNames.map((e) => e.toString()).toList();
      } else if (pNames is String) {
        try {
          final decoded = jsonDecode(pNames);
          if (decoded is List) {
            names = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      derivedCount = names.isNotEmpty ? names.length - 1 : 0;
    } else if (map['participantsCount'] != null) {
      final count = int.tryParse(map['participantsCount'].toString()) ?? 0;
      derivedCount = count > 0 ? count - 1 : 0;
    }

    _incomingParticipantsCount = derivedCount;
    dev.log(
      '📞 CallManager: Resolved incomingParticipantsCount: $_incomingParticipantsCount (excluding ourselves, from payload map: $map)',
      name: 'CallManager',
    );

    _state = CallState.ringing;
    notifyListeners();
    // _startRingTone();

    // Trigger System-level overlay CallKit if foreground
    _showCallKitNotification();

    // Push the beautiful foreground receiving screen
    final context = navigatorKey.currentContext;
    if (context != null) {
      _isReceivingScreenPushed = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _isVideo
              ? VideoCallReceivingScreen(
                  userName: _receiverName ?? 'User',
                  avatarUrl: _receiverAvatar,
                )
              : VoiceCallReceivingScreen(
                  userName: _receiverName ?? 'User',
                  avatarUrl: _receiverAvatar,
                ),
        ),
      );
    }
  }

  Future<void> _showCallKitNotification() async {
    final params = CallKitParams(
      id: _currentCallId ?? '',
      nameCaller: _receiverName ?? 'Incoming Call',
      appName: 'ShieldConnect',
      avatar: (_receiverAvatar != null && _receiverAvatar!.isNotEmpty)
          ? ApiService.getImageUrl(_receiverAvatar!)
          : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
      type: _isVideo ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'callerId': _callerId,
        'roomId': _currentRoomId,
        'isVideo': _isVideo,
        'isGroup': _isGroup,
        'groupName': _isGroup ? _receiverName : null,
        'groupAvatar': _isGroup ? _receiverAvatar : null,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        ringtonePath: 'ringing_tone',
        backgroundColor: '#121212',
        actionColor: '#25D366',
        incomingCallNotificationChannelName: 'Incoming Call v2',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        ringtonePath: 'ringing_tone.mp3',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // ─── Answers & Declines Flow ───────────────────────────────────────────────

  /// Accept/Answer incoming call.
  Future<void> acceptCall() async {
    // Load latest avatar/profile info from local storage cache
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userSession = prefs.getString('user_session');
      if (userSession != null) {
        final Map<String, dynamic> userMap = jsonDecode(userSession);
        _myUserId = userMap['_id'] ?? userMap['id'] ?? _myUserId;
        _myUserName = userMap['name']?.toString() ?? _myUserName ?? 'User';
        _myUserAvatar = userMap['avatar']?.toString() ?? _myUserAvatar;
        if (_receiverId == null) {
          _receiverId = _myUserId;
        }
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error restoring/updating user session in acceptCall: $e',
        name: 'CallManager',
      );
    }

    if (_currentCallId == null || _myUserId == null || _isHandlingCallAction) {
      dev.log(
        '🚨 CallManager: Cannot accept call. currentCallId: $_currentCallId, myUserId: $_myUserId, isHandling: $_isHandlingCallAction',
        name: 'CallManager',
      );
      return;
    }

    // Request microphone permission at runtime before accepting a call
    final hasMicPermission = await _requestMicrophonePermission();
    if (!hasMicPermission) {
      dev.log(
        '⚠️ CallManager: Microphone permission denied. Cannot accept call.',
        name: 'CallManager',
      );
      return;
    }

    try {
      _isHandlingCallAction = true;
      _isMinimized = false;
      dev.log(
        '📞 CallManager: Accepting call ID: $_currentCallId',
        name: 'CallManager',
      );
      _state = CallState.connected;
      // _stopRingTone();
      _stopDialTone();
      _startCallDurationTimer(); // Start call duration timer immediately
      notifyListeners();

      // Dismiss CallKit overlay
      await FlutterCallkitIncoming.endAllCalls();

      // Ensure socket is connected and user is registered before emitting accepted event
      final socketService = SocketService();
      if (!socketService.isConnected) {
        dev.log(
          '🔌 CallManager: Socket is not connected on call answer. Initializing connection...',
          name: 'CallManager',
        );
        socketService.connect(_myUserId!);

        // Wait up to 3 seconds for connection to establish
        int attempts = 0;
        while (!socketService.isConnected && attempts < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }

      // REST /call/answer endpoint
      await _apiService.post(
        '/call/answer',
        data: {'call_id': _currentCallId, 'user_id': _myUserId},
      );

      // Emit call_accepted socket event
      socketService.emit('call_accepted', {
        'to': _callerId,
        'roomId': _currentRoomId,
        'callId': _currentCallId,
        'callerId': _callerId,
        'receiverId': _myUserId,
      });

      // Connect WebRTC media streams
      await _connectLiveKitRoom();

      // If the foreground call receiving screen is currently pushed, pop it!
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        if (_isVideo) {
          if (!_isReceivingScreenPushed) {
            _isReceivingScreenPushed = true;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCallReceivingScreen(
                  userName: _receiverName ?? 'User',
                  avatarUrl: _receiverAvatar,
                ),
              ),
            );
          }
        } else {
          // For voice calls, we display all controls inside VoiceCallReceivingScreen.
          // If the screen isn't already pushed (e.g. from background wakeup), push it.
          if (!_isReceivingScreenPushed) {
            _isReceivingScreenPushed = true;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceCallReceivingScreen(
                  userName: _receiverName ?? 'User',
                  avatarUrl: _receiverAvatar,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error accepting call: $e',
        name: 'CallManager',
        error: e,
      );
      _cleanupCall();
    } finally {
      _isHandlingCallAction = false;
    }
  }

  /// Decline incoming call request.
  Future<void> declineCall() async {
    if (_currentCallId == null ||
        _myUserId == null ||
        _isHandlingCallAction ||
        _state == CallState.connected) {
      return;
    }

    try {
      _isHandlingCallAction = true;
      dev.log(
        '📞 CallManager: Rejects call ID: $_currentCallId',
        name: 'CallManager',
      );
      await FlutterCallkitIncoming.endAllCalls();

      // REST /call/decline endpoint
      await _apiService.post(
        '/call/decline',
        data: {'call_id': _currentCallId, 'user_id': _myUserId},
      );

      // Emit call_rejected socket event
      SocketService().emit('call_rejected', {
        'to': _callerId,
        'callId': _currentCallId,
        'roomId': _currentRoomId,
        'callerId': _callerId,
        'receiverId': _myUserId,
      });
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error rejecting call: $e',
        name: 'CallManager',
        error: e,
      );
    } finally {
      _isHandlingCallAction = false;
      _cleanupCall();
    }
  }

  /// Close current active call session.
  Future<void> endCall() async {
    if (_currentCallId == null || _isHandlingCallAction) {
      _cleanupCall();
      return;
    }

    // Resolve whether this is a multi-party call BEFORE the async gap to avoid build context warnings
    final context = navigatorKey.currentContext;
    bool hasMoreThanTwo = false;
    if (context != null) {
      try {
        final controller = Provider.of<CallController>(context, listen: false);
        hasMoreThanTwo = controller.participants.length > 2;
      } catch (_) {}
    }

    final String callId = _currentCallId!;
    final String? roomId = _currentRoomId;
    final String? callerId = _callerId;
    final String? receiverId = _receiverId;
    final int duration = _secondsElapsed;
    final bool isGroupCall = _isGroup;

    try {
      _isHandlingCallAction = true;
      dev.log(
        '📞 CallManager: Gracefully ending call session ID: $callId',
        name: 'CallManager',
      );
      
      // Clean up local call state and pop screens immediately
      _cleanupCall();

      // REST /call/end endpoint
      await _apiService.post(
        '/call/end',
        data: {
          'call_id': callId,
          'user_id': _myUserId,
          'duration': duration,
        },
      );

      if (!isGroupCall && !hasMoreThanTwo) {
        final targetId = (callerId == _myUserId) ? receiverId : callerId;
        SocketService().emit('call_ended', {
          'to': targetId,
          'callId': callId,
          'roomId': roomId,
          'callerId': callerId,
          'receiverId': receiverId,
        });
      } else {
        dev.log(
          '📞 CallManager: Multi-party or group call detected. Leaving call locally without emitting call_ended.',
          name: 'CallManager',
        );
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error ending call session: $e',
        name: 'CallManager',
        error: e,
      );
    } finally {
      _isHandlingCallAction = false;
    }
  }

  /// Helper to toggle local mic state and broadcast real-time state changes via Socket.IO
  Future<void> setMicrophoneEnabled(bool enabled) async {
    await roomManager.setMicrophoneEnabled(enabled);
    if (_currentCallId != null && _myUserId != null) {
      SocketService().emit('toggle_mute', {
        'callId': _currentCallId,
        'userId': _myUserId,
        'isMuted': !enabled,
        'groupId': _receiverId,
      });
    }
  }

  /// Helper to toggle local camera state and broadcast real-time state changes via Socket.IO
  Future<void> setCameraEnabled(bool enabled) async {
    await roomManager.setCameraEnabled(enabled);
    if (_currentCallId != null && _myUserId != null) {
      SocketService().emit('toggle_video', {
        'callId': _currentCallId,
        'userId': _myUserId,
        'isVideoEnabled': enabled,
        'groupId': _receiverId,
      });
    }
  }

  // ─── WebRTC Media Stream Connect ──────────────────────────────────────────

  Future<void> _connectLiveKitRoom() async {
    if (_currentRoomId == null || _myUserId == null) return;

    try {
      dev.log(
        '🎙️ CallManager: Fetching LiveKit Token for Identity: $_myUserId',
        name: 'CallManager',
      );
      final response = await _apiService.post(
        '/call/token',
        data: {
          'roomId': _currentCallId ?? _currentRoomId,
          'userId': _myUserId,
          'identity': _myUserId,
        },
      );

      final String? token =
          response.data['token']?.toString() ??
          response.data['data']?['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception("Failed to acquire valid LiveKit room join JWT token.");
      }

      // Connect LiveKit room
      await roomManager.connectRoom(
        'wss://livekit.roseshield.ai',
        token,
        isVideo: _isVideo,
      );
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error establishing WebRTC LiveKit channel: $e',
        name: 'CallManager',
        error: e,
      );
      // If WebRTC fails, hangup/disconnect call gracefully
      await endCall();
    }
  }

  // ─── Socket.IO Subscribed Callbacks ───────────────────────────────────────

  void _handleCallAcceptedEvent(dynamic data) async {
    dev.log(
      '📞 CallManager: Received call_accepted Socket event',
      name: 'CallManager',
    );
    if (_state != CallState.dialing) return;

    _state = CallState.connected;
    _stopDialTone();
    _startCallDurationTimer(); // Start call duration timer immediately
    notifyListeners();

    // Connect caller's WebRTC channels if not already connected
    if (!roomManager.isConnected) {
      await _connectLiveKitRoom();
    }
  }

  void _handleCallRejectedEvent(dynamic data) {
    dev.log(
      '📞 CallManager: Received call_rejected Socket event: $data',
      name: 'CallManager',
    );
    if (_isGroup) {
      dev.log(
        '📞 CallManager: Ignoring call_rejected because it is a group call.',
        name: 'CallManager',
      );
      return;
    }
    if (_state == CallState.connected) {
      dev.log(
        '📞 CallManager: Ignoring call_rejected because the call is already connected with existing participant(s).',
        name: 'CallManager',
      );
      return;
    }
    _cleanupCall();
  }

  void _handleCallEndedEvent(dynamic data) {
    dev.log(
      '📞 CallManager: Received call_ended Socket event',
      name: 'CallManager',
    );
    _cleanupCall();
  }

  // ─── Duration Timers & Formatting ────────────────────────────────────────

  void _startDialTimer() {
    Timer(const Duration(seconds: 40), () {
      if (_state == CallState.dialing) {
        dev.log(
          '📞 CallManager: Outgoing call unanswered. Timing out.',
          name: 'CallManager',
        );
        endCall();
      }
    });
  }

  void _startCallDurationTimer() {
    _durationTimer?.cancel();
    _secondsElapsed = 0;
    _callDuration = "00:00";

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
      final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
      _callDuration = "$minutes:$seconds";
      notifyListeners();
    });
  }

  void _cleanupCall() {
    _stopDialTone();
    // _stopRingTone();
    _durationTimer?.cancel();
    roomManager.disconnectRoom();
    FlutterCallkitIncoming.endAllCalls();

    // Globally pop call screen or receiving screen if active
    if ((_isCallScreenPushed || _isReceivingScreenPushed) && !_isMinimized) {
      try {
        navigatorKey.currentState?.pop();
      } catch (e) {
        dev.log(
          '📞 CallManager: Error popping calling screen: $e',
          name: 'CallManager',
          error: e,
        );
      }
    }
    _isCallScreenPushed = false;
    _isReceivingScreenPushed = false;
    _isMinimized = false;

    _state = CallState.idle;
    _incomingParticipantsCount = 0;
    _mutedParticipants.clear();
    _currentCallId = null;
    _currentRoomId = null;
    _callerId = null;
    _receiverId = null;
    _receiverName = null;
    _receiverAvatar = null;
    _secondsElapsed = 0;
    _callDuration = "00:00";
    _isGroup = false;

    notifyListeners();
  }

  void setVideoCallMode(bool isVideo) {
    if (_isVideo != isVideo) {
      _isVideo = isVideo;
      notifyListeners();
    }
  }

  // ─── Missing and Updated Logics from User Request ────────────────────────

  void initialize(String userId, {String? userName, String? userAvatar}) {
    init(userId, userName ?? 'User', myUserAvatar: userAvatar);
  }

  void reset() {
    stopActiveCallsTimer();
    _myUserId = null;
    _myUserName = null;
    _myUserAvatar = null;
    _callHistory = [];
    _activeGroupCalls = {};
    _cleanupCall();
    dev.log('📞 CallManager: Reset complete', name: 'CallManager');
  }

  Future<void> joinCall(
    String roomId,
    bool isVideo, {
    String? groupId,
    String? groupName,
    String? groupAvatar,
  }) async {
    if (_state != CallState.idle) {
      dev.log(
        '⚠️ CallManager: Already in a state ($_state), cleaning up to join new call.',
        name: 'CallManager',
      );
      await endCallLocally();
    }

    // Request microphone permission at runtime before joining a call
    final hasMicPermission = await _requestMicrophonePermission();
    if (!hasMicPermission) {
      dev.log(
        '⚠️ CallManager: Microphone permission denied. Cannot join call.',
        name: 'CallManager',
      );
      return;
    }

    _isMinimized = false;
    _currentRoomId = roomId;
    _isVideo = isVideo;
    _receiverId = groupId;
    _receiverName = groupName ?? 'Group';
    _receiverAvatar = groupAvatar;
    _isGroup = groupId != null && groupId.isNotEmpty;
    _state = CallState.connected;
    _startCallDurationTimer(); // Start call duration timer immediately
    notifyListeners();

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _isCallScreenPushed = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isVideo
              ? VideoCallingScreen(userName: groupName ?? 'Group')
              : VoiceCallingScreen(
                  userName: groupName ?? 'Group',
                  avatarUrl: groupAvatar,
                ),
        ),
      );
    }

    await _connectLiveKitRoom();
  }

  Future<void> endCallLocally() async {
    _cleanupCall();
  }

  Future<void> fetchCallHistory() async {
    if (_myUserId == null) return;

    try {
      _isLoadingHistory = true;
      notifyListeners();

      final response = await _apiService.get("/call/history/$_myUserId");
      if (response.data != null && response.data['success'] == true) {
        _callHistory = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
      }
    } catch (e) {
      dev.log('Error fetching call history: $e', name: 'CallManager');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveGroupCalls() async {
    if (_myUserId == null) return;

    try {
      final response = await _apiService.get("/call/active/$_myUserId");
      if (response.data != null && response.data['success'] == true) {
        final List calls = response.data['data'] ?? [];
        _activeGroupCalls = {
          for (var call in calls)
            if (call['group_id'] != null)
              call['group_id'].toString(): Map<String, dynamic>.from(call),
        };
        notifyListeners();
      }
    } catch (e) {
      dev.log('Error fetching active group calls: $e', name: 'CallManager');
    }
  }

  void _startActiveCallsTimer() {
    _activeCallsRefreshTimer?.cancel();
    _activeCallsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      fetchActiveGroupCalls();
    });
  }

  void stopActiveCallsTimer() {
    _activeCallsRefreshTimer?.cancel();
    _activeCallsRefreshTimer = null;
  }

  void _handleGroupCallEndedEvent(dynamic data) {
    dev.log(
      '🛑 Socket: Group call ended signal received: $data',
      name: 'CallManager',
    );
    if (data != null) {
      Map<dynamic, dynamic> map = {};
      if (data is Map) {
        map = data;
      } else if (data is List && data.isNotEmpty && data[0] is Map) {
        map = data[0] as Map;
      }
      final groupId = map['groupId'] ?? map['group_id'];
      if (groupId != null) {
        _activeGroupCalls.remove(groupId.toString());
        notifyListeners();
      }
    }
    fetchActiveGroupCalls();
    _cleanupCall();
  }

  void _handleGroupCallStatusUpdate(dynamic data) {
    dev.log(
      '🔌 Socket: Received group_call_status_update event broadcast. Payload: $data. Initiating instant REST active participants refresh for call: $_currentCallId',
      name: 'CallManager',
    );
    fetchActiveGroupCalls();
    if (_currentCallId != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          final controller = Provider.of<CallController>(
            context,
            listen: false,
          );
          controller.fetchParticipants(_currentCallId!);
        } catch (_) {}
      }
    }
  }

  void _handleUserMuteStatusUpdate(dynamic data) {
    dev.log(
      '📞 CallManager: Received user_mute_status_update Socket event payload: $data',
      name: 'CallManager',
    );
    if (data == null) return;
    try {
      final map = data is Map ? data : jsonDecode(data.toString());
      final String? userId = map['userId']?.toString();
      final bool isMuted = map['isMuted'] == true || map['isMuted'] == 'true';
      if (userId != null) {
        _mutedParticipants[userId] = isMuted;
        notifyListeners();
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error processing user_mute_status_update: $e',
        name: 'CallManager',
        error: e,
      );
    }
  }

  String? _findCallIdInResponse(dynamic responseData) {
    if (responseData == null) return null;

    // Convert string response to map if needed
    if (responseData is String) {
      try {
        responseData = jsonDecode(responseData);
      } catch (_) {}
    }

    if (responseData is! Map) return null;

    final dataMap = Map<String, dynamic>.from(responseData);

    // 1. Explicit lookup paths
    if (dataMap['data'] != null && dataMap['data'] is Map) {
      final sub = dataMap['data'];
      if (sub['_id'] != null) return sub['_id'].toString();
      if (sub['id'] != null) return sub['id'].toString();
      if (sub['call_id'] != null) return sub['call_id'].toString();
      if (sub['callId'] != null) return sub['callId'].toString();
    }
    if (dataMap['call'] != null && dataMap['call'] is Map) {
      final sub = dataMap['call'];
      if (sub['_id'] != null) return sub['_id'].toString();
      if (sub['id'] != null) return sub['id'].toString();
      if (sub['call_id'] != null) return sub['call_id'].toString();
      if (sub['callId'] != null) return sub['callId'].toString();
    }
    if (dataMap['_id'] != null) return dataMap['_id'].toString();
    if (dataMap['id'] != null) return dataMap['id'].toString();
    if (dataMap['callId'] != null) return dataMap['callId'].toString();
    if (dataMap['call_id'] != null) return dataMap['call_id'].toString();

    // 2. Recursive traversal lookup for a 24-character hexadecimal MongoDB ObjectId string
    final hexRegExp = RegExp(r'^[0-9a-fA-F]{24}$');
    String? foundId;

    void search(dynamic val, String key) {
      if (foundId != null) return;
      if (val is Map) {
        val.forEach((k, v) => search(v, k));
      } else if (val is List) {
        for (var item in val) {
          search(item, key);
        }
      } else if (val != null) {
        final str = val.toString();
        if (hexRegExp.hasMatch(str)) {
          final lowerKey = key.toLowerCase();
          if (lowerKey == '_id' ||
              lowerKey == 'id' ||
              lowerKey.contains('call') ||
              lowerKey.contains('room')) {
            foundId = str;
          }
        }
      }
    }

    search(dataMap, '');
    return foundId;
  }

  void _handleCallStateSnapshot(dynamic data) {
    dev.log(
      '📞 CallManager: Received call_state_snapshot Socket event: $data',
      name: 'CallManager',
    );
    if (data == null || _currentCallId == null) return;

    Map<dynamic, dynamic> map = {};
    if (data is Map) {
      map = data;
    } else {
      try {
        final decoded = jsonDecode(data.toString());
        if (decoded is Map) {
          map = decoded;
        }
      } catch (_) {}
    }

    final List? activeCallIds = map['activeCallIds'] as List?;
    if (activeCallIds != null) {
      final isCallActive = activeCallIds.any(
        (id) => id.toString() == _currentCallId,
      );
      if (!isCallActive) {
        dev.log(
          '🚨 CallManager: Active call ID $_currentCallId is not present in server active calls snapshot. Cleaning up zombie call.',
          name: 'CallManager',
        );
        _cleanupCall();
      }
    }
  }

  /// Helper to request microphone permission safely without leaving a native recorder active.
  Future<bool> _requestMicrophonePermission() async {
    final recorder = AudioRecorder();
    try {
      final hasMicPermission = await recorder.hasPermission();
      return hasMicPermission;
    } catch (e) {
      dev.log(
        '⚠️ CallManager: Error requesting microphone permission: $e',
        name: 'CallManager',
      );
      return false;
    } finally {
      await recorder.dispose();
    }
  }

  @override
  void dispose() {
    _activeCallsRefreshTimer?.cancel();
    super.dispose();
  }
}
