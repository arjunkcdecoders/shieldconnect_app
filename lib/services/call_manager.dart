import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:shieldconnect_app/model/settings_model.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

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
    SocketService().connectionNotifier.addListener(notifyListeners);
    _initConnectivityListener();
  }

  BuildContext? _moderationDialogContext;
  bool _isModerationDialogDelayed = false;
  final List<Map<dynamic, dynamic>> _pendingModerationWarnings = [];

  final RoomManager roomManager = RoomManager();
  final ApiService _apiService = ApiService();

  CallState _state = CallState.idle;
  CallState get state => _state;

  String? _statusText;
  String? get statusText => _statusText;

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

  Map<String, dynamic>? _incomingWaitingCall;
  Map<String, dynamic>? get incomingWaitingCall => _incomingWaitingCall;

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

  bool _isConnectingAudio = false;
  bool get isConnectingAudio => _isConnectingAudio;
  Timer? _audioConnectTimer;

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
    socketService.moderationViolationNotifier.addListener(
      _onModerationViolationNotified,
    );

    // Initial history and active call pools fetch
    fetchCallHistory();
    fetchActiveGroupCalls();
    _startActiveCallsTimer();

    // Attempt session-level recovery/reconnection
    attemptReconnect();

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
    socketService.moderationViolationNotifier.removeListener(
      _onModerationViolationNotified,
    );
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
          if (_incomingWaitingCall != null &&
              _incomingWaitingCall!['callId'] == callId) {
            await acceptWaitingCall();
            break;
          }
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
          if (_incomingWaitingCall != null &&
              _incomingWaitingCall!['callId'] == callId) {
            await declineWaitingCall();
            break;
          }
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
    if (data == null) return;

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

    if (_state != CallState.idle) {
      dev.log(
        '📞 CallManager: Received incoming_call while in an active call. Handling as Call Waiting.',
        name: 'CallManager',
      );
      final callerIdVal = map['callerId']?.toString();
      final isVideoVal = map['isVideo'] == true || map['isVideo'] == 'true';
      final isGroupVal =
          map['isGroup'] == true ||
          map['isGroup'] == 'true' ||
          map['is_group'] == true ||
          map['is_group'] == 'true' ||
          (map['groupName'] != null &&
              map['groupName'].toString().isNotEmpty) ||
          (map['group_name'] != null &&
              map['group_name'].toString().isNotEmpty);
      final receiverNameVal = isGroupVal
          ? (map['groupName']?.toString() ??
                map['group_name']?.toString() ??
                map['callerName']?.toString())
          : map['callerName']?.toString();
      final String? callerAvVal = map['callerAvatar']?.toString();
      final String? groupAvVal =
          map['groupAvatar']?.toString() ?? map['group_avatar']?.toString();
      final receiverAvatarVal = isGroupVal
          ? (groupAvVal == null ||
                    groupAvVal == 'null' ||
                    groupAvVal.isEmpty ||
                    groupAvVal == callerAvVal
                ? null
                : groupAvVal)
          : (callerAvVal ?? map['receiverAvatar']?.toString());

      _incomingWaitingCall = {
        'callId': map['callId']?.toString(),
        'roomId': map['roomId']?.toString(),
        'callerId': callerIdVal,
        'isVideo': isVideoVal,
        'isGroup': isGroupVal,
        'receiverName': receiverNameVal,
        'receiverAvatar': receiverAvatarVal,
        'map': map,
      };
      notifyListeners();
      _showWaitingCallKitNotification();
      return;
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
      _startCallConnectedFlow();
      unawaited(_cacheCallSession());
      unawaited(_checkCurrentConnectivity());
      _startConnectivityPolling();
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

  Future<void> _showWaitingCallKitNotification() async {
    if (_incomingWaitingCall == null) return;
    final waiting = _incomingWaitingCall!;
    final params = CallKitParams(
      id: waiting['callId'] ?? '',
      nameCaller: waiting['receiverName'] ?? 'Incoming Call',
      appName: 'ShieldConnect',
      avatar:
          (waiting['receiverAvatar'] != null &&
              waiting['receiverAvatar']!.isNotEmpty)
          ? ApiService.getImageUrl(waiting['receiverAvatar']!)
          : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
      type: waiting['isVideo'] == true ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'callerId': waiting['callerId'],
        'roomId': waiting['roomId'],
        'isVideo': waiting['isVideo'],
        'isGroup': waiting['isGroup'],
        'isWaitingCall': true,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        ringtonePath: 'ringing_tone',
        backgroundColor: '#121212',
        actionColor: '#25D366',
        incomingCallNotificationChannelName: 'Incoming Call Waiting',
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

  Future<void> declineWaitingCall() async {
    if (_incomingWaitingCall == null) return;
    final waiting = _incomingWaitingCall!;
    _incomingWaitingCall = null;
    notifyListeners();

    final String? callId = waiting['callId'];
    final String? callerId = waiting['callerId'];
    final String? roomId = waiting['roomId'];

    try {
      if (callId != null) {
        await FlutterCallkitIncoming.endCall(callId);
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }

      if (callId != null && _myUserId != null) {
        await _apiService.post(
          '/call/decline',
          data: {'call_id': callId, 'user_id': _myUserId},
        );
      }

      if (callId != null) {
        SocketService().emit('call_rejected', {
          'to': callerId,
          'callId': callId,
          'roomId': roomId,
          'callerId': callerId,
          'receiverId': _myUserId,
        });
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error declining waiting call: $e',
        name: 'CallManager',
      );
    }
  }

  Future<void> acceptWaitingCall() async {
    if (_incomingWaitingCall == null) return;
    final waiting = _incomingWaitingCall!;
    _incomingWaitingCall = null;
    notifyListeners();

    // Request microphone permission at runtime before accepting the waiting call
    final hasMicPermission = await _requestMicrophonePermission();
    if (!hasMicPermission) {
      dev.log(
        '⚠️ CallManager: Microphone permission denied. Cannot accept waiting call.',
        name: 'CallManager',
      );
      return;
    }

    final String? oldCallId = _currentCallId;
    final String? oldRoomId = _currentRoomId;
    final String? oldCallerId = _callerId;
    final String? oldReceiverId = _receiverId;
    final int oldDuration = _secondsElapsed;
    final bool oldIsGroup = _isGroup;

    try {
      dev.log(
        '📞 CallManager: Transitioning to waiting call session ID: ${waiting['callId']} immediately.',
        name: 'CallManager',
      );

      // 1. Immediately end/cleanup the current active call locally (timers, dialing tone)
      _dismissModerationDialog();
      _stopDialTone();
      _durationTimer?.cancel();
      _audioConnectTimer?.cancel();
      _isConnectingAudio = false;

      final bool wasCallScreenPushed = _isCallScreenPushed;
      final bool wasReceivingScreenPushed = _isReceivingScreenPushed;

      // 2. Set new call parameters immediately so that the pushed screen builds with new metadata
      _currentCallId = waiting['callId'];
      _currentRoomId = waiting['roomId'];
      _callerId = waiting['callerId'];
      _receiverId = _myUserId;
      _isGroup = waiting['isGroup'] == true;
      _receiverName = waiting['receiverName'];
      _receiverAvatar = waiting['receiverAvatar'];
      _isVideo = waiting['isVideo'] == true;
      _state = CallState.connected;
      _incomingParticipantsCount = 0;
      _secondsElapsed = 0;
      _callDuration = "00:00";
      _mutedParticipants.clear();

      _startCallConnectedFlow();
      notifyListeners();

      // 3. Navigate to the correct screen (Voice or Video) immediately
      final currentContext = navigatorKey.currentContext;
      if (wasCallScreenPushed && currentContext != null && !_isMinimized) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => _isVideo
                ? VideoCallingScreen(userName: _receiverName ?? 'User')
                : VoiceCallingScreen(
                    userName: _receiverName ?? 'User',
                    avatarUrl: _receiverAvatar,
                  ),
          ),
        );
      } else {
        if (wasReceivingScreenPushed &&
            currentContext != null &&
            !_isMinimized) {
          try {
            navigatorKey.currentState?.pop();
          } catch (_) {}
        }
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => _isVideo
                ? VideoCallingScreen(userName: _receiverName ?? 'User')
                : VoiceCallingScreen(
                    userName: _receiverName ?? 'User',
                    avatarUrl: _receiverAvatar,
                  ),
          ),
        );
      }
      _isCallScreenPushed = true;
      _isReceivingScreenPushed = false;
      _isMinimized = false;

      // 4. Perform the rest of the connection and termination logic asynchronously in the background
      unawaited(() async {
        try {
          // A. Disconnect LiveKit room of the old call
          await roomManager.disconnectRoom();

          // B. Emit call_ended socket event and call /call/end REST endpoint for the old call
          if (oldCallId != null) {
            try {
              // REST /call/end endpoint
              await _apiService.post(
                '/call/end',
                data: {
                  'call_id': oldCallId,
                  'user_id': _myUserId,
                  'duration': oldDuration,
                },
              );

              // Determine if there are more than two participants
              bool hasMoreThanTwo = false;
              if (currentContext != null) {
                try {
                  final controller = Provider.of<CallController>(
                    currentContext,
                    listen: false,
                  );
                  hasMoreThanTwo = controller.participants.length > 2;
                } catch (_) {}
              }

              if (!oldIsGroup && !hasMoreThanTwo) {
                final targetId = (oldCallerId == _myUserId)
                    ? oldReceiverId
                    : oldCallerId;
                SocketService().emit('call_ended', {
                  'to': targetId,
                  'callId': oldCallId,
                  'roomId': oldRoomId,
                  'callerId': oldCallerId,
                  'receiverId': oldReceiverId,
                });
              }
            } catch (e) {
              dev.log(
                '🚨 CallManager: Error ending old call in background: $e',
              );
            }
          }

          // C. REST /call/answer endpoint for the new call (awaited to ensure backend is active)
          if (_currentCallId != null && _myUserId != null) {
            await _apiService.post(
              '/call/answer',
              data: {'call_id': _currentCallId, 'user_id': _myUserId},
            );
          }

          // D. Emit call_accepted socket event for the new call
          if (_currentCallId != null) {
            SocketService().emit('call_accepted', {
              'to': _callerId,
              'roomId': _currentRoomId,
              'callId': _currentCallId,
              'callerId': _callerId,
              'receiverId': _myUserId,
            });
          }

          // E. Connect to LiveKit room for the new call (awaited to ensure connection is ready)
          await _connectLiveKitRoom();
        } catch (e) {
          dev.log(
            '🚨 CallManager: Error completing connection for waiting call: $e',
            name: 'CallManager',
          );
          _cleanupCall();
        }
      }());
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error accepting waiting call: $e',
        name: 'CallManager',
      );
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

      // Stop dialing and duration timer immediately
      _stopDialTone();
      _durationTimer?.cancel();
      _audioConnectTimer?.cancel();
      _isConnectingAudio = false;

      // Disconnect WebRTC room immediately
      roomManager.disconnectRoom();

      // Show "Call Ending..." status text
      _statusText = "Call Ending...";
      notifyListeners();

      // REST /call/end endpoint
      await _apiService.post(
        '/call/end',
        data: {'call_id': callId, 'user_id': _myUserId, 'duration': duration},
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

      // Show Call Ending.. text to the user for 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      _cleanupCall();
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error ending call session: $e',
        name: 'CallManager',
        error: e,
      );
      _cleanupCall();
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

  String? _parseCallIdFromSocketData(dynamic data) {
    if (data == null) return null;
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
      } catch (_) {}
    }
    return map['callId']?.toString() ??
        map['call_id']?.toString() ??
        map['roomId']?.toString() ??
        map['room_id']?.toString();
  }

  void _handleCallAcceptedEvent(dynamic data) async {
    dev.log(
      '📞 CallManager: Received call_accepted Socket event: $data',
      name: 'CallManager',
    );
    final String? eventCallId = _parseCallIdFromSocketData(data);
    if (eventCallId != null &&
        eventCallId != _currentCallId &&
        eventCallId != _currentRoomId) {
      dev.log(
        '📞 CallManager: Ignoring call_accepted because eventCallId $eventCallId does not match currentCallId $_currentCallId or currentRoomId $_currentRoomId',
        name: 'CallManager',
      );
      return;
    }
    if (_state != CallState.dialing) return;

    _state = CallState.connected;
    _stopDialTone();
    _startCallConnectedFlow();
    unawaited(_cacheCallSession());
    unawaited(_checkCurrentConnectivity());
    _startConnectivityPolling();
    notifyListeners();

    // Connect caller's WebRTC channels if not already connected
    if (!roomManager.isConnected) {
      await _connectLiveKitRoom();
    }
  }

  void _handleCallRejectedEvent(dynamic data) async {
    dev.log(
      '📞 CallManager: Received call_rejected Socket event: $data',
      name: 'CallManager',
    );
    final String? eventCallId = _parseCallIdFromSocketData(data);
    if (_incomingWaitingCall != null &&
        (eventCallId == _incomingWaitingCall!['callId'] ||
            eventCallId == _incomingWaitingCall!['roomId'])) {
      dev.log(
        '📞 CallManager: Received call_rejected for the waiting call. Clearing waiting call.',
        name: 'CallManager',
      );
      final waitingId = _incomingWaitingCall!['callId'];
      _incomingWaitingCall = null;
      notifyListeners();
      if (waitingId != null) {
        FlutterCallkitIncoming.endCall(waitingId);
      }
      return;
    }

    if (eventCallId != null &&
        eventCallId != _currentCallId &&
        eventCallId != _currentRoomId) {
      dev.log(
        '📞 CallManager: Ignoring call_rejected because eventCallId $eventCallId does not match currentCallId $_currentCallId or currentRoomId $_currentRoomId',
        name: 'CallManager',
      );
      return;
    }

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
    _statusText = "Call Declined..";
    _stopDialTone();
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    if (_state != CallState.idle) {
      _cleanupCall();
    }
  }

  void _handleCallEndedEvent(dynamic data) async {
    dev.log(
      '📞 CallManager: Received call_ended Socket event: $data',
      name: 'CallManager',
    );
    final String? eventCallId = _parseCallIdFromSocketData(data);
    if (_incomingWaitingCall != null &&
        (eventCallId == _incomingWaitingCall!['callId'] ||
            eventCallId == _incomingWaitingCall!['roomId'])) {
      dev.log(
        '📞 CallManager: Received call_ended for the waiting call. Clearing waiting call.',
        name: 'CallManager',
      );
      final waitingId = _incomingWaitingCall!['callId'];
      _incomingWaitingCall = null;
      notifyListeners();
      if (waitingId != null) {
        FlutterCallkitIncoming.endCall(waitingId);
      }
      return;
    }

    if (eventCallId != null &&
        eventCallId != _currentCallId &&
        eventCallId != _currentRoomId) {
      dev.log(
        '📞 CallManager: Ignoring call_ended because eventCallId $eventCallId does not match currentCallId $_currentCallId or currentRoomId $_currentRoomId',
        name: 'CallManager',
      );
      return;
    }

    if (_state != CallState.idle) {
      _stopDialTone();
      _durationTimer?.cancel();
      _audioConnectTimer?.cancel();
      _isConnectingAudio = false;
      roomManager.disconnectRoom();

      _statusText = "Call Ending...";
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));
      if (_state != CallState.idle) {
        _cleanupCall();
      }
    }
  }

  // ─── Duration Timers & Formatting ────────────────────────────────────────

  void _startDialTimer() async {
    int timeoutSecs = 30;
    try {
      final settings = await SettingsModel.loadActiveSettings();
      if (settings.callTimeout != null && settings.callTimeout! > 0) {
        timeoutSecs = settings.callTimeout!;
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error loading callTimeout settings: $e',
        name: 'CallManager',
      );
    }

    Timer(Duration(seconds: timeoutSecs), () async {
      if (_state == CallState.dialing) {
        dev.log(
          '📞 CallManager: Outgoing call unanswered. Timing out in $timeoutSecs seconds.',
          name: 'CallManager',
        );
        if (!_isGroup) {
          _statusText = "Unanswered Call..";
          _stopDialTone();
          notifyListeners();
          await Future.delayed(const Duration(seconds: 2));
        }
        if (_state == CallState.dialing) {
          endCall();
        }
      }
    });
  }

  void _startCallConnectedFlow() {
    _durationTimer?.cancel();
    _audioConnectTimer?.cancel();

    if (!_isVideo) {
      _isConnectingAudio = true;
      _secondsElapsed = 0;
      _callDuration = "Connecting to audio...";
      notifyListeners();

      _audioConnectTimer = Timer(const Duration(seconds: 6), () {
        _isConnectingAudio = false;
        _startCallDurationTimer();
      });
    } else {
      _isConnectingAudio = false;
      _startCallDurationTimer();
    }
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
    _dismissModerationDialog();
    _isModerationDialogDelayed = false;
    _pendingModerationWarnings.clear();
    _stopDialTone();
    // _stopRingTone();
    _durationTimer?.cancel();
    _audioConnectTimer?.cancel();
    _isConnectingAudio = false;
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
    _statusText = null;
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

    unawaited(_clearCallSessionCache());
    _connectivityPollingTimer?.cancel();
    _connectivityPollingTimer = null;
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
    String? callerId,
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
    _currentCallId = roomId;
    _isVideo = isVideo;
    _receiverId = groupId;
    _receiverName = groupName ?? 'Group';
    _receiverAvatar = groupAvatar;
    _callerId = callerId;
    _isGroup = groupId != null && groupId.isNotEmpty;
    _state = CallState.connected;
    _startCallConnectedFlow();
    unawaited(_cacheCallSession());
    unawaited(_checkCurrentConnectivity());
    _startConnectivityPolling();
    notifyListeners();

    // 1. Post to REST /call/answer in background to add this user as active participant
    if (_myUserId != null) {
      unawaited(() async {
        try {
          await _apiService.post(
            '/call/answer',
            data: {'call_id': roomId, 'user_id': _myUserId},
          );
        } catch (e) {
          dev.log(
            '🚨 CallManager: Error answering call REST inside joinCall: $e',
            name: 'CallManager',
          );
        }
      }());
    }

    // 2. Emit call_accepted socket event
    if (_myUserId != null) {
      SocketService().emit('call_accepted', {
        'to': callerId,
        'roomId': roomId,
        'callId': roomId,
        'callerId': callerId,
        'receiverId': _myUserId,
      });
    }

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
        final Map<String, Map<String, dynamic>> temp = {};
        for (var call in calls) {
          if (call['group_id'] != null) {
            String? gid;
            if (call['group_id'] is Map) {
              gid = (call['group_id']['_id'] ?? call['group_id']['id'])
                  ?.toString();
            } else {
              gid = call['group_id'].toString();
            }
            if (gid != null) {
              temp[gid] = Map<String, dynamic>.from(call);
            }
          }
        }
        _activeGroupCalls = temp;
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

  void _handleGroupCallEndedEvent(dynamic data) async {
    dev.log(
      '🛑 Socket: Group call ended signal received: $data',
      name: 'CallManager',
    );
    String? eventCallId;
    String? eventGroupId;
    if (data != null) {
      Map<dynamic, dynamic> map = {};
      if (data is Map) {
        map = data;
      } else if (data is List && data.isNotEmpty && data[0] is Map) {
        map = data[0] as Map;
      }
      eventGroupId = (map['groupId'] ?? map['group_id'])?.toString();
      eventCallId =
          (map['callId'] ?? map['call_id'] ?? map['roomId'] ?? map['room_id'])
              ?.toString();
      if (eventGroupId != null) {
        _activeGroupCalls.remove(eventGroupId);
        notifyListeners();
      }
    }
    fetchActiveGroupCalls();

    if (_incomingWaitingCall != null &&
        (eventCallId == _incomingWaitingCall!['callId'] ||
            eventCallId == _incomingWaitingCall!['roomId'])) {
      dev.log(
        '📞 CallManager: Received group_call_ended for the waiting call. Clearing waiting call.',
        name: 'CallManager',
      );
      final waitingId = _incomingWaitingCall!['callId'];
      _incomingWaitingCall = null;
      notifyListeners();
      if (waitingId != null) {
        FlutterCallkitIncoming.endCall(waitingId);
      }
      return;
    }

    if (eventCallId != null &&
        eventCallId != _currentCallId &&
        eventCallId != _currentRoomId) {
      dev.log(
        '📞 CallManager: Ignoring group_call_ended because eventCallId $eventCallId does not match currentCallId $_currentCallId or currentRoomId $_currentRoomId',
        name: 'CallManager',
      );
      return;
    }
    if (eventGroupId != null && eventGroupId != _receiverId && _isGroup) {
      dev.log(
        '📞 CallManager: Ignoring group_call_ended because eventGroupId $eventGroupId does not match group recipient ID $_receiverId',
        name: 'CallManager',
      );
      return;
    }

    if (_state != CallState.idle) {
      _stopDialTone();
      _durationTimer?.cancel();
      _audioConnectTimer?.cancel();
      _isConnectingAudio = false;
      roomManager.disconnectRoom();

      _statusText = "Call Ending..";
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));
      if (_state != CallState.idle) {
        _cleanupCall();
      }
    }
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

  void _dismissModerationDialog() {
    if (_moderationDialogContext != null) {
      try {
        Navigator.of(_moderationDialogContext!).pop();
      } catch (_) {}
      _moderationDialogContext = null;
    }
  }

  void _onModerationViolationNotified() {
    final payload = SocketService().moderationViolationNotifier.value;
    if (payload != null) {
      _handleModerationViolationEvent(payload);
    }
  }

  void handleModerationViolationEvent(dynamic data) {
    _handleModerationViolationEvent(data);
  }

  void _handleModerationViolationEvent(dynamic data) {
    if (_state != CallState.connected) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // 1. Normalize data into a manageable Map structure
    Map<dynamic, dynamic> payload = {};
    if (data is Map) {
      payload = data;
    } else if (data != null) {
      try {
        final decoded = jsonDecode(data.toString());
        if (decoded is Map) payload = decoded;
      } catch (_) {}
    }

    // Queue the warning event
    _pendingModerationWarnings.add(payload);
    _tryShowNextModerationWarning(context);
  }

  void _tryShowNextModerationWarning(BuildContext context) {
    if (_moderationDialogContext != null ||
        _isModerationDialogDelayed ||
        _pendingModerationWarnings.isEmpty) {
      return;
    }

    final nextWarning = _pendingModerationWarnings.removeAt(0);
    _showModerationWarningDialog(
      context,
      nextWarning['roomName']?.toString() ?? '',
      int.tryParse(nextWarning['violationCount']?.toString() ?? '') ?? 0,
      nextWarning['reason']?.toString() ?? 'Inappropriate content detected',
      nextWarning['alertType']?.toString() ?? '',
      nextWarning['type']?.toString() ?? 'general',
    );
  }

  void _dismissWarningWithCooldown(BuildContext dialogCtx) {
    if (_moderationDialogContext == dialogCtx) {
      try {
        Navigator.of(dialogCtx).pop();
      } catch (_) {}
      _moderationDialogContext = null;

      // Trigger 3-second delay cooldown before allowing next dialog to be shown
      _isModerationDialogDelayed = true;
      Timer(const Duration(seconds: 3), () {
        _isModerationDialogDelayed = false;
        final activeContext = navigatorKey.currentContext;
        if (activeContext != null) {
          _tryShowNextModerationWarning(activeContext);
        }
      });
    }
  }

  void _showModerationWarningDialog(
    BuildContext context,
    String roomName,
    int violationCount,
    String reason,
    String alertType,
    String type,
  ) {
    _dismissModerationDialog();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _moderationDialogContext = dialogCtx;

        // Automatically close the dialog after 2 seconds
        Timer(const Duration(seconds: 2), () {
          _dismissWarningWithCooldown(dialogCtx);
        });

        return Dialog(
          backgroundColor: appColor(context).grey900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: appColor(context).red.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: appColor(context).grey900,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Shield/Gavel Indicator
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appColor(context).red.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: appColor(context).red,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  "Moderation Warning",
                  style: fontStyle.clashDisplayBold18.textColor(
                    appColor(context).white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Violation Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appColor(context).red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appColor(context).red.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Warning #$violationCount",
                    style: fontStyle.clashDisplaySemiBold12.textColor(
                      appColor(context).red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reason / Type Details Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appColor(context).black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appColor(context).white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Violation",
                            style: fontStyle.clashDisplayBold12.textColor(
                              appColor(context).textGrey,
                            ),
                          ),
                          if (alertType.isNotEmpty)
                            Text(
                              "Source",
                              style: fontStyle.clashDisplayBold12.textColor(
                                appColor(context).textGrey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reason,
                            style: fontStyle.clashDisplayMedium14.textColor(
                              appColor(context).white,
                            ),
                          ),
                          if (alertType.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: appColor(
                                  context,
                                ).white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alertType.toUpperCase(),
                                style: fontStyle.clashDisplayBold10.textColor(
                                  appColor(context).white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Friendly guidelines info
                Text(
                  "ShieldConnect uses automated moderation to ensure safety. Repeated violations of our guidelines may lead to automatic suspension or call termination.",
                  style: fontStyle.clashDisplayMedium12
                      .textColor(appColor(context).textGrey)
                      .copyWith(height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Acknowledge Button
                GestureDetector(
                  onTap: () {
                    _dismissWarningWithCooldown(dialogCtx);
                  },
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appColor(context).red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Acknowledge",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // void _handleModerationViolationEvent(dynamic data) {
  //   dev.log(
  //     '📞 CallManager: Received moderation_violation event with data: $data',
  //     name: 'CallManager',
  //   );
  //   if (_state != CallState.connected) return;

  //   final context = navigatorKey.currentContext;
  //   if (context == null) return;

  //   Map<dynamic, dynamic> map = {};
  //   if (data is Map) {
  //     map = data;
  //   } else if (data != null) {
  //     try {
  //       final decoded = jsonDecode(data.toString());
  //       if (decoded is Map) {
  //         map = decoded;
  //       }
  //     } catch (_) {}
  //   }

  //   final String reason =
  //       map['reason']?.toString() ??
  //       (data is String ? data : 'Inappropriate content detected');
  //   dev.log("Reasonnnnnnnnnnnnnnnnnnnnnn: $reason");
  //   final String roomName = map['roomName']?.toString() ?? '';
  //   final int violationCount =
  //       int.tryParse(map['violationCount']?.toString() ?? '') ?? 0;
  //   final String alertType = map['alertType']?.toString() ?? '';
  //   final String type = map['type']?.toString() ?? 'general';

  //   _showModerationWarningDialog(
  //     context,
  //     roomName,
  //     violationCount,
  //     reason,
  //     alertType,
  //     type,
  //   );
  // }

  // void _showModerationWarningDialog(
  //   BuildContext context,
  //   String roomName,
  //   int violationCount,
  //   String reason,
  //   String alertType,
  //   String type,
  // ) {
  //   _dismissModerationDialog();

  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogCtx) {
  //       _moderationDialogContext = dialogCtx;
  //       return Dialog(
  //         backgroundColor: appColor(context).grey900,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(24),
  //           side: BorderSide(
  //             color: appColor(context).red.withValues(alpha: 0.3),
  //             width: 1.5,
  //           ),
  //         ),
  //         insetPadding: const EdgeInsets.symmetric(horizontal: 24),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             color: appColor(context).grey900,
  //             borderRadius: BorderRadius.circular(24),
  //           ),
  //           padding: const EdgeInsets.all(24.0),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // Warning Shield/Gavel Indicator
  //               Container(
  //                 width: 56,
  //                 height: 56,
  //                 decoration: BoxDecoration(
  //                   shape: BoxShape.circle,
  //                   color: appColor(context).red.withValues(alpha: 0.1),
  //                 ),
  //                 child: Center(
  //                   child: Icon(
  //                     Icons.warning_amber_rounded,
  //                     color: appColor(context).red,
  //                     size: 28,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               // Title
  //               Text(
  //                 "Moderation Warning",
  //                 style: fontStyle.clashDisplayBold18.textColor(
  //                   appColor(context).white,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 8),

  //               // Violation Count Badge
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 4,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: appColor(context).red.withValues(alpha: 0.15),
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(
  //                     color: appColor(context).red.withValues(alpha: 0.4),
  //                     width: 1,
  //                   ),
  //                 ),
  //                 child: Text(
  //                   "Warning #$violationCount",
  //                   style: fontStyle.clashDisplaySemiBold12.textColor(
  //                     appColor(context).red,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               // Reason / Type Details Box
  //               Container(
  //                 width: double.infinity,
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: appColor(context).black.withValues(alpha: 0.3),
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(
  //                     color: appColor(context).white.withValues(alpha: 0.05),
  //                   ),
  //                 ),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           "Violation Category",
  //                           style: fontStyle.clashDisplayBold12.textColor(
  //                             appColor(context).textGrey,
  //                           ),
  //                         ),
  //                         if (alertType.isNotEmpty)
  //                           Text(
  //                             "Source",
  //                             style: fontStyle.clashDisplayBold12.textColor(
  //                               appColor(context).textGrey,
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 6),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           reason,
  //                           style: fontStyle.clashDisplayMedium14.textColor(
  //                             appColor(context).white,
  //                           ),
  //                         ),
  //                         if (alertType.isNotEmpty)
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 8,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: appColor(
  //                                 context,
  //                               ).white.withValues(alpha: 0.1),
  //                               borderRadius: BorderRadius.circular(6),
  //                             ),
  //                             child: Text(
  //                               alertType.toUpperCase(),
  //                               style: fontStyle.clashDisplayBold10.textColor(
  //                                 appColor(context).white,
  //                               ),
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               // Friendly guidelines info
  //               Text(
  //                 "ShieldConnect uses automated moderation to ensure safety. Repeated violations of our guidelines may lead to automatic suspension or call termination.",
  //                 style: fontStyle.clashDisplayMedium12
  //                     .textColor(appColor(context).textGrey)
  //                     .copyWith(height: 1.4),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 20),

  //               // Acknowledge Button
  //               GestureDetector(
  //                 onTap: () {
  //                   Navigator.of(dialogCtx).pop();
  //                   _moderationDialogContext = null;
  //                 },
  //                 child: Container(
  //                   height: 44,
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                     color: appColor(context).red,
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Center(
  //                     child: Text(
  //                       "Acknowledge",
  //                       style: fontStyle.clashDisplaySemiBold14.textColor(
  //                         appColor(context).white,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

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

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkOffline = false;
  bool get isNetworkOffline => _isNetworkOffline;

  bool get isReconnecting {
    if (_state != CallState.connected) return false;
    return roomManager.isReconnecting ||
        _isNetworkOffline ||
        !SocketService().connectionNotifier.value;
  }

  void _initConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool isOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (SocketService().connectionNotifier.value) {
        isOffline = false;
      }
      dev.log(
        '🔌 CallManager: Connectivity changed: $results (isOffline: $isOffline)',
        name: 'CallManager',
      );
      if (_isNetworkOffline != isOffline) {
        _isNetworkOffline = isOffline;
        notifyListeners();

        if (!isOffline && _myUserId != null) {
          dev.log(
            '🔌 CallManager: Network restored. Triggering manual Socket.IO reconnect...',
            name: 'CallManager',
          );
          SocketService().connect(_myUserId!);

          if (_state == CallState.connected) {
            if (!roomManager.isConnected && !roomManager.isConnecting) {
              dev.log(
                '🎙️ CallManager: WebRTC room is not connected. Re-connecting to LiveKit room...',
                name: 'CallManager',
              );
              _connectLiveKitRoom();
            }
            if (_currentCallId != null) {
              final context = navigatorKey.currentContext;
              if (context != null && context.mounted) {
                try {
                  final controller = Provider.of<CallController>(
                    context,
                    listen: false,
                  );
                  controller.fetchParticipants(_currentCallId!);
                } catch (e) {
                  dev.log(
                    '🚨 CallManager: Error refreshing participants: $e',
                    name: 'CallManager',
                  );
                }
              }
            }
          }
        }
      }
    });
    // Check initial connectivity status immediately
    unawaited(_checkCurrentConnectivity());
  }

  Future<void> _cacheCallSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeCallId', _currentCallId ?? '');
      await prefs.setString('activeRoomId', _currentRoomId ?? '');
      await prefs.setString('activeCallType', _isVideo ? 'video' : 'audio');
      await prefs.setBool('activeIsGroup', _isGroup);
      await prefs.setString('activeReceiverName', _receiverName ?? '');
      await prefs.setString('activeReceiverAvatar', _receiverAvatar ?? '');
      await prefs.setString('activeCallerId', _callerId ?? '');
      await prefs.setString('activeReceiverId', _receiverId ?? '');
      dev.log(
        '📞 CallManager: Cached call session ID: $_currentCallId',
        name: 'CallManager',
      );
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error caching call session: $e',
        name: 'CallManager',
      );
    }
  }

  Future<void> _clearCallSessionCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeCallId');
      await prefs.remove('activeRoomId');
      await prefs.remove('activeCallType');
      await prefs.remove('activeIsGroup');
      await prefs.remove('activeReceiverName');
      await prefs.remove('activeReceiverAvatar');
      await prefs.remove('activeCallerId');
      await prefs.remove('activeReceiverId');
      dev.log(
        '📞 CallManager: Cleared call session cache',
        name: 'CallManager',
      );
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error clearing call session cache: $e',
        name: 'CallManager',
      );
    }
  }

  Future<bool> _isCallSessionValid(String callId) async {
    if (_myUserId == null) return false;
    try {
      // 1. Check active calls first
      final responseActive = await _apiService.get("/call/active/$_myUserId");
      if (responseActive.data != null &&
          responseActive.data['success'] == true) {
        final List calls = responseActive.data['data'] ?? [];
        final hasCall = calls.any((c) {
          if (c is Map) {
            final String? cId =
                (c['_id'] ??
                        c['id'] ??
                        c['callId'] ??
                        c['roomId'] ??
                        c['group_id'])
                    ?.toString();
            return cId == callId;
          }
          return false;
        });
        if (hasCall) {
          dev.log(
            '📞 CallManager: Found call ID in active calls list.',
            name: 'CallManager',
          );
          return true;
        }
      }

      // 2. Fallback: Check participants
      final responseParticipants = await _apiService.get(
        "/call/participants/$callId",
      );
      if (responseParticipants.data != null) {
        final dynamic rawData = responseParticipants.data is Map
            ? (responseParticipants.data['data'] ??
                  responseParticipants.data['participants'] ??
                  [])
            : responseParticipants.data;
        List<dynamic> participantsList = [];
        if (rawData is List) {
          participantsList = rawData;
        } else if (responseParticipants.data['success'] == true) {
          participantsList = responseParticipants.data['data'] ?? [];
        }

        for (final p in participantsList) {
          if (p is Map) {
            final String? pId = (p['user_id'] ?? p['id'] ?? p['_id'])
                ?.toString();
            if (pId == _myUserId) {
              final String? status = p['status']?.toString().toLowerCase();
              if (status != 'left' &&
                  status != 'declined' &&
                  status != 'missed' &&
                  status != 'rejected') {
                dev.log(
                  '📞 CallManager: User is active participant in the call.',
                  name: 'CallManager',
                );
                return true;
              }
            }
          }
        }
      }
      return false;
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error validating cached call: $e',
        name: 'CallManager',
      );
      return false;
    }
  }

  Future<void> attemptReconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedCallId = prefs.getString('activeCallId');
      if (cachedCallId == null || cachedCallId.isEmpty) {
        dev.log(
          '📞 CallManager: No cached call session found to reconnect.',
          name: 'CallManager',
        );
        return;
      }

      dev.log(
        '📞 CallManager: Found cached call session ID: $cachedCallId. Validating with server...',
        name: 'CallManager',
      );

      final bool isValid = await _isCallSessionValid(cachedCallId);
      if (!isValid) {
        dev.log(
          '📞 CallManager: Cached call session is no longer active. Cleaning up.',
          name: 'CallManager',
        );
        await _clearCallSessionCache();
        return;
      }

      final String cachedRoomId =
          prefs.getString('activeRoomId') ?? cachedCallId;
      final String cachedCallType =
          prefs.getString('activeCallType') ?? 'audio';
      final bool cachedIsGroup = prefs.getBool('activeIsGroup') ?? false;
      final String cachedReceiverName =
          prefs.getString('activeReceiverName') ?? 'Active Call';
      final String? cachedReceiverAvatar = prefs.getString(
        'activeReceiverAvatar',
      );
      final String? cachedCallerId = prefs.getString('activeCallerId');
      final String? cachedReceiverId = prefs.getString('activeReceiverId');

      _currentCallId = cachedCallId;
      _currentRoomId = cachedRoomId;
      _isVideo = cachedCallType == 'video';
      _isGroup = cachedIsGroup;
      _receiverName = cachedReceiverName;
      _receiverAvatar =
          (cachedReceiverAvatar != null && cachedReceiverAvatar.isNotEmpty)
          ? cachedReceiverAvatar
          : null;
      _callerId = cachedCallerId;
      _receiverId = cachedReceiverId;

      dev.log(
        '📞 CallManager: Cached call session is valid! Restoring call state and rejoining...',
        name: 'CallManager',
      );

      _state = CallState.connected;
      _startCallConnectedFlow();
      _startConnectivityPolling();
      notifyListeners();

      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        _isCallScreenPushed = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _isVideo
                ? VideoCallingScreen(userName: _receiverName ?? 'User')
                : VoiceCallingScreen(
                    userName: _receiverName ?? 'User',
                    avatarUrl: _receiverAvatar,
                  ),
          ),
        );
      }

      await _connectLiveKitRoom();
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error during attemptReconnect: $e',
        name: 'CallManager',
      );
    }
  }

  Future<void> _checkCurrentConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      bool isOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (SocketService().connectionNotifier.value) {
        isOffline = false;
      }
      dev.log(
        '🔌 CallManager: checkCurrentConnectivity results: $results (isOffline: $isOffline)',
        name: 'CallManager',
      );
      if (_isNetworkOffline != isOffline) {
        _isNetworkOffline = isOffline;
        notifyListeners();
      }
    } catch (e) {
      dev.log(
        '🚨 CallManager: Error checking current connectivity: $e',
        name: 'CallManager',
      );
    }
  }

  @override
  void dispose() {
    _activeCallsRefreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityPollingTimer?.cancel();
    SocketService().connectionNotifier.removeListener(notifyListeners);
    roomManager.removeListener(notifyListeners);
    super.dispose();
  }

  Timer? _connectivityPollingTimer;

  void _startConnectivityPolling() {
    _connectivityPollingTimer?.cancel();
    _connectivityPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (_state != CallState.connected) {
        timer.cancel();
        return;
      }
      try {
        final results = await Connectivity().checkConnectivity();
        bool isOffline =
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
        if (SocketService().connectionNotifier.value) {
          isOffline = false;
        }
        if (_isNetworkOffline != isOffline) {
          dev.log(
            '🔌 CallManager Poller: Network status changed actively: isOffline: $isOffline',
            name: 'CallManager',
          );
          _isNetworkOffline = isOffline;
          notifyListeners();

          if (!isOffline && _myUserId != null) {
            dev.log(
              '🔌 CallManager Poller: Network restored. Reconnecting socket...',
              name: 'CallManager',
            );
            SocketService().connect(_myUserId!);
            if (_state == CallState.connected) {
              if (!roomManager.isConnected && !roomManager.isConnecting) {
                dev.log(
                  '🎙️ CallManager Poller: WebRTC room is not connected. Re-connecting to LiveKit room...',
                  name: 'CallManager',
                );
                _connectLiveKitRoom();
              }
              if (_currentCallId != null) {
                final context = navigatorKey.currentContext;
                if (context != null && context.mounted) {
                  final controller = Provider.of<CallController>(
                    context,
                    listen: false,
                  );
                  controller.fetchParticipants(_currentCallId!);
                }
              }
            }
          }
        }
      } catch (e) {
        dev.log('🚨 CallManager Poller error: $e', name: 'CallManager');
        final isOffline = !SocketService().connectionNotifier.value;
        if (_isNetworkOffline != isOffline) {
          dev.log(
            '🔌 CallManager Poller (Fallback): Network status changed: isOffline: $isOffline',
            name: 'CallManager',
          );
          _isNetworkOffline = isOffline;
          notifyListeners();

          if (!isOffline && _myUserId != null) {
            dev.log(
              '🔌 CallManager Poller (Fallback): Network restored. Reconnecting socket...',
              name: 'CallManager',
            );
            SocketService().connect(_myUserId!);
            if (_state == CallState.connected &&
                !roomManager.isConnected &&
                !roomManager.isConnecting) {
              dev.log(
                '🎙️ CallManager Poller (Fallback): WebRTC room is not connected. Re-connecting to LiveKit room...',
                name: 'CallManager',
              );
              _connectLiveKitRoom();
            }
          }
        }
      }
    });
  }
}
