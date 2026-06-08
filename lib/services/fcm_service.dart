import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/call_manager.dart';

/// Top-level background message handler.
/// This MUST be a top-level static function so it can execute when the app process is killed/terminated.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized inside the background isolates
  await Firebase.initializeApp();

  dev.log(
    '🔔 FCM Background: Received background notification message payload: ${message.data}',
    name: 'FcmService',
  );

  final data = message.data;
  final event = data['event']?.toString() ?? data['type']?.toString();

  if (event == 'incoming_call') {
    final String callId =
        data['callId']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final String callerId = data['callerId']?.toString() ?? '';
    final String roomId = data['roomId']?.toString() ?? '';
    final bool isVideo = data['isVideo'] == 'true' || data['isVideo'] == true;

    final bool isGroup =
        data['isGroup'] == 'true' ||
        data['isGroup'] == true ||
        data['is_group'] == 'true' ||
        data['is_group'] == true ||
        (data['groupName'] != null &&
            data['groupName'].toString().isNotEmpty) ||
        (data['group_name'] != null &&
            data['group_name'].toString().isNotEmpty);

    final String? groupName =
        data['groupName']?.toString() ?? data['group_name']?.toString();
    final String? groupAvatar =
        data['groupAvatar']?.toString() ?? data['group_avatar']?.toString();

    final String callerName =
        (isGroup && groupName != null && groupName.isNotEmpty)
        ? groupName
        : (data['callerName']?.toString() ?? 'Incoming Call');

    final String? callerAv = data['callerAvatar']?.toString();
    final String callerAvatar = isGroup
        ? (groupAvatar == null ||
                  groupAvatar == 'null' ||
                  groupAvatar.isEmpty ||
                  groupAvatar == callerAv
              ? ''
              : groupAvatar)
        : (callerAv ?? '');

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'ShieldConnect',
      avatar: (callerAvatar.isNotEmpty)
          ? ApiService.getImageUrl(callerAvatar)
          : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
      type: isVideo ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'callerId': callerId,
        'roomId': roomId,
        'isVideo': isVideo,
        'isGroup': isGroup,
        'groupName': groupName,
        'groupAvatar': groupAvatar,
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
    dev.log(
      '🔔 FCM Background: Displayed native OS incoming CallKit dialog.',
      name: 'FcmService',
    );
  } else if (event == 'call_ended' || event == 'group_call_ended') {
    await FlutterCallkitIncoming.endAllCalls();
    dev.log(
      '🔔 FCM Background: Ended/Dismissed background CallKit overlays.',
      name: 'FcmService',
    );
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  /// Initialize and register FCM handlers.
  /// Call this inside `main()` after widgets binding initialization.
  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request device notification permissions
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Register the static top-level background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        dev.log(
          '🔔 FCM Foreground: Received foreground message payload: ${message.data}',
          name: 'FcmService',
        );
        final data = message.data;
        final event = data['event']?.toString() ?? data['type']?.toString();

        if (event == 'call_ended' || event == 'group_call_ended') {
          await FlutterCallkitIncoming.endAllCalls();
        }
        // else if (event == 'moderation_violation') {
        //   CallManager().handleModerationViolationEvent(data);
        // }
      });

      dev.log(
        '🔔 FCM Service: FCM background and foreground listeners configured successfully.',
        name: 'FcmService',
      );
    } catch (e) {
      dev.log(
        '🚨 FCM Service: Error configuring FCM: $e',
        name: 'FcmService',
        error: e,
      );
    }
  }
}
