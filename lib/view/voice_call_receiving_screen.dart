import 'dart:ui';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/view/add_call_members_screen.dart';
import 'package:shieldconnect_app/main.dart';

class VoiceCallReceivingScreen extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const VoiceCallReceivingScreen({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  List<Map<String, dynamic>> _buildGridMembers(
    CallManager callManager,
    CallController callController,
    BuildContext context,
  ) {
    final List<Map<String, dynamic>> gridMembers = [];
    final bool isConnected = callManager.state == CallState.connected;

    // Resolve "Me" avatar robustly from various providers
    String? myAvatar = callManager.myUserAvatar;
    if (myAvatar == null || myAvatar.isEmpty) {
      try {
        final profileController = Provider.of<ProfileController>(
          context,
          listen: false,
        );
        if (profileController.imageUrl.isNotEmpty) {
          myAvatar = profileController.imageUrl;
        }
      } catch (_) {}
    }
    if (myAvatar == null || myAvatar.isEmpty) {
      try {
        final homeController = Provider.of<HomeScreenController>(
          context,
          listen: false,
        );
        if (homeController.profileImage != null &&
            homeController.profileImage!.isNotEmpty) {
          myAvatar = homeController.profileImage;
        }
      } catch (_) {}
    }

    // 1. Add "Me"
    gridMembers.add({
      'user_id': callManager.myUserId ?? 'me',
      'name': 'Me',
      'avatar': myAvatar,
      'isMe': true,
      'is_muted': callManager.roomManager.isMuted,
    });

    // 2. Add the primary call recipient/caller
    final String otherId = (callManager.myUserId == callManager.callerId)
        ? (callManager.receiverId ?? '')
        : (callManager.callerId ?? '');

    if (otherId.isNotEmpty) {
      String resolvedName = userName;
      if (resolvedName.contains(" and ")) {
        resolvedName = resolvedName.split(" and ").first;
      }
      bool hasLeft = false;
      String? otherStatus;
      String? resolvedAvatar = avatarUrl;
      try {
        final matchingParticipant = callController.participants.firstWhere((p) {
          final pId = p['user_id'] ?? p['id'] ?? p['_id'];
          return pId?.toString() == otherId;
        });
        final String? status = matchingParticipant['status']
            ?.toString()
            .toLowerCase();
        otherStatus = status;
        if (status == 'left' ||
            status == 'declined' ||
            status == 'missed' ||
            status == 'rejected') {
          hasLeft = true;
        } else {
          resolvedName =
              matchingParticipant['name'] ??
              matchingParticipant['username'] ??
              resolvedName;
          resolvedAvatar =
              matchingParticipant['avatar'] ??
              matchingParticipant['profile_pic'] ??
              resolvedAvatar;
        }
      } catch (_) {
        // If otherId is not found in participants list and we have successfully fetched participants, then they have left.
        if (isConnected && callController.hasFetchedParticipants) {
          hasLeft = true;
        }
      }

      // Do not consider the remote participant as permanently left just because they temporarily dropped from the LiveKit room.
      // They are only considered left if they are no longer in the participants list from backend polling.
      // if (callManager.roomManager.hasParticipantLeft(otherId)) {
      //   hasLeft = true;
      // }

      if (!hasLeft) {
        final bool isOtherMuted =
            callManager.mutedParticipants[otherId] == true ||
            callController.participants.any((p) {
              final pId = p['user_id'] ?? p['id'] ?? p['_id'];
              return pId?.toString() == otherId &&
                  (p['is_muted'] == true || p['isMuted'] == true);
            });

        gridMembers.add({
          'user_id': otherId,
          'name': resolvedName,
          'avatar': resolvedAvatar,
          'isMe': false,
          'is_muted': isOtherMuted,
          'status':
              otherStatus ??
              (callManager.roomManager.hasParticipantLeft(otherId)
                  ? 'disconnected'
                  : (callManager.state == CallState.connected
                        ? 'connected'
                        : 'ringing')),
        });
      } else {
        dev.log(
          '👥 VoiceCallReceivingScreen: Primary participant ($userName, ID: $otherId) has left or declined the call. Skipping from grid UI.',
          name: 'VoiceCallReceivingScreen',
        );
      }
    }

    // 3. Add all fetched participants uniquely
    for (final p in callController.participants) {
      final pId = p['user_id'] ?? p['id'] ?? p['_id'];
      final pName = p['name'] ?? p['username'] ?? 'User';
      final pAvatar = p['avatar'] ?? p['profile_pic'];
      final bool pMute = p['is_muted'] == true || p['isMuted'] == true;
      final String? pStatus = p['status']?.toString();

      if (pId != null) {
        final String pIdStr = pId.toString();
        if (callManager.roomManager.hasParticipantLeft(pIdStr)) {
          continue;
        }
        final isDup = gridMembers.any(
          (m) => m['user_id'].toString() == pId.toString(),
        );
        if (!isDup) {
          gridMembers.add({
            'user_id': pId.toString(),
            'name': pName,
            'avatar': pAvatar,
            'isMe': pId.toString() == callManager.myUserId.toString(),
            'is_muted': pMute,
            'status': pStatus,
          });
        }
      }
    }

    // Verbose grid UI change logger
    dev.log(
      '🖥️ VoiceCallReceivingScreen: Rebuilding call grid. Active members inside UI cell array: ${gridMembers.map((m) => "${m['name']} (ID: ${m['user_id']}, Muted: ${m['is_muted']})").toList()}',
      name: 'VoiceCallReceivingScreen',
    );

    return gridMembers;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallManager, CallController>(
      builder: (context, callManager, callController, child) {
        final roomManager = callManager.roomManager;
        final isVideoActive =
            callManager.isVideo ||
            roomManager.isCameraOn ||
            roomManager.remoteVideoTrack != null;
        if (isVideoActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callManager.setVideoCallMode(true);
          });
          return VideoCallingScreen(userName: userName);
        }

        final isConnected = callManager.state == CallState.connected;
        final isMuted = roomManager.isMuted;
        final isSpeakerOn = roomManager.isSpeakerOn;

        // Build call members list for grid view
        final gridMembers = _buildGridMembers(
          callManager,
          callController,
          context,
        );
        final hasAddedMembers = isConnected && gridMembers.length >= 3;

        // Resolve dynamic single member details when falling back to 1-to-1 UI
        final activeOther = gridMembers.firstWhere(
          (m) => m['isMe'] != true,
          orElse: () => <String, dynamic>{},
        );

        // UI-level safeguard: Auto-end call if connected and no other active participant is in the call
        if (!callManager.isGroup &&
            isConnected &&
            callManager.roomManager.isConnected &&
            !callManager.isReconnecting &&
            callManager.secondsElapsed > 2 &&
            callController.hasFetchedParticipants &&
            activeOther.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            dev.log(
              '👥 VoiceCallReceivingScreen: Rebuilt grid has only Me left. Automatically ending call.',
              name: 'VoiceCallReceivingScreen',
            );
            callManager.endCall();
          });
        }

        final String activeOtherId = activeOther.isNotEmpty
            ? (activeOther['user_id']?.toString() ?? '')
            : ((callManager.myUserId == callManager.callerId)
                  ? (callManager.receiverId ?? '')
                  : (callManager.callerId ?? ''));

        bool otherHasLeft = false;
        if (isConnected &&
            !callManager.isGroup &&
            activeOther.isEmpty &&
            activeOtherId.isNotEmpty) {
          // Do not treat LiveKit disconnection as immediate leave.
          try {
            final matchingParticipant = callController.participants.firstWhere((
              p,
            ) {
              final pId = p['user_id'] ?? p['id'] ?? p['_id'];
              return pId?.toString() == activeOtherId;
            });
            final String? status = matchingParticipant['status']
                ?.toString()
                .toLowerCase();
            if (status == 'left' ||
                status == 'declined' ||
                status == 'missed' ||
                status == 'rejected') {
              otherHasLeft = true;
            }
          } catch (_) {
            if (callController.hasFetchedParticipants) {
              otherHasLeft = true;
            }
          }
        }

        final String activeName =
            (callManager.isGroup && activeOther.isNotEmpty)
            ? "$userName - ${activeOther['name']}"
            : (callManager.isGroup || activeOther.isEmpty)
            ? (otherHasLeft ? '🔚📞' : userName)
            : (activeOther['name'] ?? userName);
        final String? activeAvatar =
            (callManager.isGroup || activeOther.isEmpty)
            ? (otherHasLeft ? null : avatarUrl)
            : activeOther['avatar'];

        final bool isCallEnding =
            callManager.state == CallState.idle ||
            (!callManager.isGroup &&
                isConnected &&
                callManager.roomManager.isConnected &&
                !callManager.isReconnecting &&
                callManager.secondsElapsed > 4 &&
                callController.hasFetchedParticipants &&
                activeOther.isEmpty);

        dev.log(
          '📞 VoiceCallReceivingScreen build: callState=${callManager.state}, activeOther.isEmpty=${activeOther.isEmpty}, isCallEnding=$isCallEnding',
          name: 'VoiceCallReceivingScreen',
        );

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              callManager.setMinimized(true);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(
              0xFF121212,
            ), // Deep luxurious immersive black background
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Main Background Content: Grid view or standard layout
                  hasAddedMembers
                      ? Positioned.fill(
                          child: CallGridView(
                            members: gridMembers,
                            callDuration: callManager.callDuration,
                          ),
                        )
                      : isCallEnding
                      ? const SizedBox.shrink()
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Builder(
                                builder: (context) {
                                  final String otherId = activeOther.isNotEmpty
                                      ? (activeOther['user_id']?.toString() ??
                                            '')
                                      : ((callManager.myUserId ==
                                                callManager.callerId)
                                            ? (callManager.receiverId ?? '')
                                            : (callManager.callerId ?? ''));
                                  final bool isOtherMuted =
                                      activeOther.isNotEmpty
                                      ? (activeOther['is_muted'] == true)
                                      : (callManager.mutedParticipants[otherId] ==
                                                true ||
                                            callController.participants.any((
                                              p,
                                            ) {
                                              final pId =
                                                  p['user_id'] ??
                                                  p['id'] ??
                                                  p['_id'];
                                              return pId?.toString() ==
                                                      otherId &&
                                                  (p['is_muted'] == true ||
                                                      p['isMuted'] == true);
                                            }));
                                  final isConnected =
                                      callManager.state == CallState.connected;

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Animated pulsing outer avatar glow container
                                      Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: appColor(
                                                context,
                                              ).white.withValues(alpha: 0.04),
                                              blurRadius: 30,
                                              spreadRadius: 20,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 140,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: appColor(
                                                  context,
                                                ).white.withValues(alpha: 0.1),
                                                width: 2,
                                              ),
                                              color: appColor(
                                                context,
                                              ).white.withValues(alpha: 0.06),
                                            ),
                                            child:
                                                (activeAvatar != null &&
                                                    activeAvatar.isNotEmpty)
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          70,
                                                        ),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          ApiService.getImageUrl(
                                                            activeAvatar,
                                                          ),
                                                      cacheKey:
                                                          _normalizeAvatarUrl(
                                                            activeAvatar,
                                                          ),
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => const Center(
                                                            child: SizedBox(
                                                              width: 32,
                                                              height: 32,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: Colors
                                                                        .white30,
                                                                  ),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => Icon(
                                                            callManager.isGroup
                                                                ? Icons.group
                                                                : Icons.person,
                                                            color: appColor(
                                                              context,
                                                            ).white,
                                                            size: 64,
                                                          ),
                                                    ),
                                                  )
                                                : Icon(
                                                    callManager.isGroup
                                                        ? Icons.group
                                                        : Icons.person,
                                                    color: appColor(
                                                      context,
                                                    ).white,
                                                    size: 64,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      if (callManager.isConnectingAudio)
                                        Positioned.fill(
                                          child: Center(
                                            child: SizedBox(
                                              width: 144,
                                              height: 144,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 4.0,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(const Color(0xFFE91E63)),
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (isConnected && isOtherMuted)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD32F2F)
                                                  .withValues(
                                                    alpha: 0.95,
                                                  ), // Premium crimson mute badge
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.mic_off,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),

                              // Bold styled user identity text
                              Text(
                                activeName,
                                style: fontStyle.clashDisplayBold20.textColor(
                                  appColor(context).white,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Incoming Call Status / Call Duration
                              Text(
                                callManager.statusText ??
                                    (isConnected
                                        ? callManager.callDuration
                                        : callManager
                                                  .incomingParticipantsCount >
                                              1
                                        ? "Incoming voice call... (${callManager.incomingParticipantsCount} members in this call)"
                                        : "Incoming voice call..."),
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  appColor(
                                    context,
                                  ).white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                  // 2. Actions (Incoming Call Actions OR Active Call Toolbar)
                  if (!isConnected)
                    Positioned(
                      bottom: 64,
                      left: 48,
                      right: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Decline Button (Left End)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.read<CallManager>().declineCall();
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: Color(
                                      0xFFD32F2F,
                                    ), // Vibrant material red hangup color
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFFB71C1C),
                                        offset: Offset(0, 4),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      ImageAssets.endCall,
                                      color: Colors.white,
                                      width: 26,
                                      height: 26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Decline",
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  appColor(
                                    context,
                                  ).white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          // Answer Button (Right End)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.read<CallManager>().acceptCall();
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: Color(
                                      0xFF23C123,
                                    ), // Vibrant active call green
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF1B5E20),
                                        offset: Offset(0, 4),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      ImageAssets.answerCall,
                                      color: Colors.white,
                                      width: 26,
                                      height: 26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Answer",
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  appColor(
                                    context,
                                  ).white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // Connected Floating Translucent Bottom Toolbar
                    Positioned(
                      bottom: 32,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 12.0,
                              sigmaY: 12.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF262626,
                                ).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: appColor(
                                    context,
                                  ).white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: appColor(
                                      context,
                                    ).black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // A. Standard Toolbar Actions
                                  GestureDetector(
                                    onTap: () {
                                      callManager.setCameraEnabled(
                                        !roomManager.isCameraOn,
                                      );
                                    },
                                    child: _buildRoundTool(
                                      context,
                                      asset: ImageAssets.videoOn,
                                      isActive: roomManager.isCameraOn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      callManager.setMicrophoneEnabled(isMuted);
                                    },
                                    child: _buildRoundTool(
                                      context,
                                      asset: isMuted
                                          ? ImageAssets.micOff
                                          : ImageAssets.recorder,
                                      isActive: !isMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      roomManager.setSpeakerphoneOn(
                                        !isSpeakerOn,
                                      );
                                    },
                                    child: _buildRoundTool(
                                      context,
                                      icon: isSpeakerOn
                                          ? Icons.volume_up
                                          : Icons.volume_down,
                                      isActive: isSpeakerOn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddCallMembersScreen(),
                                        ),
                                      );
                                    },
                                    child: _buildRoundTool(
                                      context,
                                      asset: ImageAssets.addUser,
                                      isActive: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // B. Solid Red Immediate Termination Hangup Trigger
                                  GestureDetector(
                                    onTap: () {
                                      callManager.endCall();
                                    },
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: const BoxDecoration(
                                        color: Color(
                                          0xFFD32F2F,
                                        ), // Vibrant material red hangup color
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFFB71C1C),
                                            offset: Offset(0, 3),
                                            blurRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.phone_disabled_outlined,
                                          color: appColor(context).white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isConnected)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          navigatorKey.currentState?.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              // const SizedBox(width: 6),
                              // Text(
                              //   "Back",
                              //   style: fontStyle.clashDisplayMedium12.textColor(
                              //     Colors.white,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (callManager.isReconnecting)
                    Positioned.fill(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.65),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE91E63),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "Reconnecting...",
                                    style: fontStyle.clashDisplayBold18
                                        .textColor(Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Please check your internet connection",
                                    style: fontStyle.clashDisplaySemiBold12
                                        .textColor(Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoundTool(
    BuildContext context, {
    String? asset,
    IconData? icon,
    required bool isActive,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? appColor(context).secondary.withValues(alpha: 0.8)
            : appColor(context).white.withValues(alpha: 0.06),
        border: Border.all(
          color: appColor(context).white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Center(
        child: asset != null
            ? Image.asset(
                asset,
                color: appColor(context).white,
                width: 20,
                height: 20,
              )
            : Icon(icon, color: appColor(context).white, size: 20),
      ),
    );
  }
}

String? _normalizeAvatarUrl(dynamic avatar) {
  if (avatar == null || avatar is! String || avatar.isEmpty) return null;
  try {
    final uri = Uri.parse(avatar);
    return uri.replace(queryParameters: {}).toString();
  } catch (_) {
    return avatar;
  }
}
