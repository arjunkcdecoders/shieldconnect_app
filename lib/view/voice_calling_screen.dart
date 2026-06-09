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
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';
import 'package:shieldconnect_app/view/add_call_members_screen.dart';

class VoiceCallingScreen extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const VoiceCallingScreen({super.key, required this.userName, this.avatarUrl});

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

    if (otherId.isNotEmpty && !callManager.isGroup) {
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
          '👥 VoiceCallingScreen: Primary participant ($userName, ID: $otherId) has left or declined the call. Skipping from grid UI.',
          name: 'VoiceCallingScreen',
        );
      }
    }

    // 3. Add all fetched participants uniquely
    for (final p in callController.participants) {
      final pId = p['user_id'] ?? p['id'] ?? p['_id'];
      final String pName = p['name'] ?? p['username'] ?? 'User';
      final String? pAvatar = p['avatar'] ?? p['profile_pic'];
      final bool pMute = p['is_muted'] == true || p['isMuted'] == true;
      final String? pStatus = p['status']?.toString();

      if (pId != null) {
        final String pIdStr = pId.toString();
        if (callManager.roomManager.hasParticipantLeft(pIdStr)) {
          continue;
        }
        final isDup = gridMembers.any((m) => m['user_id'].toString() == pIdStr);
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
      '🖥️ VoiceCallingScreen: Rebuilding call grid. Active members inside UI cell array: ${gridMembers.map((m) => "${m['name']} (ID: ${m['user_id']}, Muted: ${m['is_muted']})").toList()}',
      name: 'VoiceCallingScreen',
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
        final hasAddedMembers = gridMembers.length >= 3;

        // Resolve dynamic single member details when falling back to 1-to-1 UI
        final activeOther = gridMembers.firstWhere(
          (m) => m['isMe'] != true,
          orElse: () => <String, dynamic>{},
        );

        // UI-level safeguard: Auto-end call if connected and no other active participant is in the call
        if (!callManager.isGroup &&
            callManager.state == CallState.connected &&
            callManager.roomManager.isConnected &&
            !callManager.isReconnecting &&
            callManager.secondsElapsed > 2 &&
            callController.hasFetchedParticipants &&
            activeOther.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            dev.log(
              '👥 VoiceCallingScreen: Rebuilt grid has only Me left. Automatically ending call.',
              name: 'VoiceCallingScreen',
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
                callManager.state == CallState.connected &&
                callManager.roomManager.isConnected &&
                !callManager.isReconnecting &&
                callManager.secondsElapsed > 4 &&
                callController.hasFetchedParticipants &&
                activeOther.isEmpty);

        dev.log(
          '📞 VoiceCallingScreen build: callState=${callManager.state}, activeOther.isEmpty=${activeOther.isEmpty}, isCallEnding=$isCallEnding',
          name: 'VoiceCallingScreen',
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
                  // 1. Background Content: Grid view or standard layout
                  hasAddedMembers
                      ? Positioned.fill(
                          child: CallGridView(
                            members: gridMembers,
                            callDuration:
                                callManager.statusText ??
                                (callManager.state == CallState.connected
                                    ? callManager.callDuration
                                    : "Calling..."),
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

                              // Dedicated dynamic timer badge
                              Text(
                                callManager.statusText ??
                                    (callManager.state == CallState.connected
                                        ? callManager.callDuration
                                        : "Calling..."),
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  appColor(
                                    context,
                                  ).white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                  // 2. Immersive Floating Translucent Bottom Toolbar
                  Positioned(
                    bottom: 32,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // A. Standard Toolbar Actions
                                GestureDetector(
                                  onTap: isConnected
                                      ? () {
                                          callManager.setCameraEnabled(
                                            !roomManager.isCameraOn,
                                          );
                                        }
                                      : null,
                                  child: Opacity(
                                    opacity: isConnected ? 1.0 : 0.4,
                                    child: _buildRoundTool(
                                      context,
                                      asset: ImageAssets.videoOn,
                                      isActive: roomManager.isCameraOn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: isConnected
                                      ? () {
                                          callManager.setMicrophoneEnabled(
                                            isMuted,
                                          );
                                        }
                                      : null,
                                  child: Opacity(
                                    opacity: isConnected ? 1.0 : 0.4,
                                    child: _buildRoundTool(
                                      context,
                                      asset: isMuted
                                          ? ImageAssets.micOff
                                          : ImageAssets.recorder,
                                      isActive: !isMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                   onTap: isConnected
                                       ? () {
                                           roomManager.setSpeakerphoneOn(
                                             !isSpeakerOn,
                                           );
                                         }
                                       : null,
                                   child: Opacity(
                                     opacity: isConnected ? 1.0 : 0.4,
                                     child: _buildRoundTool(
                                       context,
                                       icon: isSpeakerOn
                                           ? Icons.volume_up
                                           : Icons.volume_down,
                                       isActive: isSpeakerOn,
                                     ),
                                   ),
                                 ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: isConnected
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddCallMembersScreen(),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Opacity(
                                    opacity: isConnected ? 1.0 : 0.4,
                                    child: _buildRoundTool(
                                      context,
                                      asset: ImageAssets.addUser,
                                      isActive: isConnected,
                                    ),
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

                  // 3. Minimization Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
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
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  // 4. Call Waiting Overlay Card
                  // if (callManager.incomingWaitingCall != null)
                  //   Positioned(
                  //     bottom: 120,
                  //     left: 20,
                  //     right: 20,
                  //     child: CallWaitingOverlay(
                  //       waitingCall: callManager.incomingWaitingCall!,
                  //       onAccept: () => callManager.acceptWaitingCall(),
                  //       onDecline: () => callManager.declineWaitingCall(),
                  //     ),
                  //   ),
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

class CallGridView extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String callDuration;

  const CallGridView({
    super.key,
    required this.members,
    required this.callDuration,
  });

  @override
  Widget build(BuildContext context) {
    final callController = Provider.of<CallController>(context);
    final callManager = Provider.of<CallManager>(context);
    final total = members.length;

    // Calculate number of pages (max 6 grids per page)
    int numPages = 1;
    if (total > 6) {
      int tempTotal = total;
      numPages = 1;
      tempTotal -= 5;
      while (tempTotal > 6) {
        numPages++;
        tempTotal -= 5;
      }
      if (tempTotal > 0) {
        numPages++;
      }
    }
    final int currentPage = callController.currentPage;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2D141E), // Rich plum wine
            Color(0xFF121212), // Deep black
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              if (callManager.isGroup) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    callManager.receiverName ?? 'Group',
                    style: fontStyle.clashDisplayBold18.textColor(Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Top timer display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  callDuration,
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Grid Area inside PageView
              Expanded(
                child: PageView.builder(
                  controller: callController.pageController,
                  itemCount: numPages,
                  onPageChanged: callController.setCurrentPage,
                  itemBuilder: (context, pageIndex) {
                    List<Map<String, dynamic>> pageMembers = [];
                    bool showIndicatorCard = false;
                    List<Map<String, dynamic>> remainingMembersForIndicator = [];

                    final int startIndex = pageIndex * 5;
                    final int remainingFromStart = total - startIndex;

                    if (remainingFromStart <= 6) {
                      pageMembers = members.sublist(startIndex);
                      showIndicatorCard = false;
                    } else {
                      pageMembers = members.sublist(startIndex, startIndex + 5);
                      showIndicatorCard = true;
                      remainingMembersForIndicator = members.sublist(startIndex + 5);
                    }

                    final int gridItemCount = pageMembers.length + (showIndicatorCard ? 1 : 0);

                    // Build the grid widgets for this page
                    final List<Widget> gridWidgets = [];
                    for (int index = 0; index < gridItemCount; index++) {
                      if (showIndicatorCard && index == 5) {
                        gridWidgets.add(_buildIndicatorCard(context, remainingMembersForIndicator));
                      } else {
                        gridWidgets.add(_buildMemberCard(context, pageMembers[index], callManager, callController));
                      }
                    }

                    // Lay them out in Rows (max 2 per Row)
                    final List<Widget> rows = [];
                    int idx = 0;
                    while (idx < gridWidgets.length) {
                      final int remaining = gridWidgets.length - idx;
                      if (remaining == 1) {
                        // Last single item takes full width
                        rows.add(
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: gridWidgets[idx]),
                              ],
                            ),
                          ),
                        );
                        idx += 1;
                      } else {
                        // Two items side-by-side with a small 4px space between them
                        rows.add(
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: gridWidgets[idx]),
                                const SizedBox(width: 4),
                                Expanded(child: gridWidgets[idx + 1]),
                              ],
                            ),
                          ),
                        );
                        idx += 2;
                      }
                    }

                    final List<Widget> columnChildren = [];
                    for (int i = 0; i < rows.length; i++) {
                      columnChildren.add(rows[i]);
                      if (i < rows.length - 1) {
                        columnChildren.add(const SizedBox(height: 4));
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: columnChildren,
                    );
                  },
                ),
              ),
              if (numPages > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(numPages, (i) {
                    final bool isActive = i == currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF8B263E) // Active dot
                            : Colors.white.withValues(
                                alpha: 0.3,
                              ), // Inactive dot
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 110), // Space for bottom action bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(
    BuildContext context,
    List<Map<String, dynamic>> remaining,
  ) {
    final visibleCount = remaining.length > 4 ? 4 : remaining.length;

    // Layout details for overlapping avatars
    const double avatarSize = 44.0;
    const double overlap = 14.0;
    const double itemWidth = avatarSize - overlap;
    final double stackWidth = avatarSize + (visibleCount - 1) * itemWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Overlapping stack of remaining members
                SizedBox(
                  width: stackWidth,
                  height: avatarSize,
                  child: Stack(
                    children: List.generate(visibleCount, (vIndex) {
                      // Reverse generation so leftmost is top-most
                      final i = visibleCount - 1 - vIndex;
                      final m = remaining[i];
                      final String? mAvatar = m['avatar'];

                      return Positioned(
                        left: i * itemWidth,
                        child: Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(avatarSize / 2),
                            child: (mAvatar != null && mAvatar.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: ApiService.getImageUrl(mAvatar),
                                    cacheKey: _normalizeAvatarUrl(mAvatar),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 14),
                // Count text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "+${remaining.length} others",
                    textAlign: TextAlign.center,
                    style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    Map<String, dynamic> member,
    CallManager callManager,
    CallController callController,
  ) {
    final String userId = member['user_id']?.toString() ?? '';
    final String name = member['name'] ?? 'User';
    final String? avatar = member['avatar'];
    final bool isMe = member['isMe'] == true;
    final String? status = member['status']?.toString().toLowerCase();
    final bool isRemoteConnected = callManager.roomManager.room?.remoteParticipants.values
            .any((rp) => rp.identity == userId) ??
        false;
    final bool isCalling = !isMe &&
        !isRemoteConnected &&
        (status == 'ringing' || status == 'dialing' || status == 'invited' || status == null);
    final bool isSpeaking = isMe
        ? (callManager.roomManager.room?.localParticipant?.isSpeaking ?? false)
        : (callManager.roomManager.room?.remoteParticipants[userId]?.isSpeaking ?? false);

    return Container(
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF6B1D2F).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSpeaking
              ? const Color(0xFF23C123)
              : (isMe
                  ? const Color(0xFF8B263E).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08)),
          width: isSpeaking ? 3.0 : 1.5,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: const Color(0xFF23C123).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Large background avatar shadow/silhouette
            if (avatar != null && avatar.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22, // Subtle and deep
                  child: CachedNetworkImage(
                    imageUrl: ApiService.getImageUrl(avatar),
                    cacheKey: _normalizeAvatarUrl(avatar),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Opacity(
                      opacity: 0.04,
                      child: Icon(
                        Icons.person,
                        size: 140,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            else
              const Positioned.fill(
                child: Opacity(
                  opacity: 0.04,
                  child: Icon(
                    Icons.person,
                    size: 140,
                    color: Colors.white,
                  ),
                ),
              ),

            // Shading colored filter overlay to blend beautifully with plum/wine background
            Positioned.fill(
              child: Container(
                color: isMe
                    ? const Color(0xFF2D141E).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.15),
              ),
            ),

            // 2. Avatar & Name Column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rounded Avatar with thin border
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 2,
                    ),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: (avatar != null && avatar.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(43),
                          child: CachedNetworkImage(
                            imageUrl: ApiService.getImageUrl(avatar),
                            cacheKey: _normalizeAvatarUrl(avatar),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 40,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 40,
                        ),
                ),
                const SizedBox(height: 14),
                // Name Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white),
                  ),
                ),
                if (isCalling) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Calling..",
                    style: fontStyle.clashDisplayMedium10.textColor(Colors.white70),
                  ),
                ],
              ],
            ),

            // 3. "Me" pill badge at top right
            if (isMe)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B263E), // Deep wine pill color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Me",
                    style: fontStyle.clashDisplayBold10.textColor(Colors.white),
                  ),
                ),
              ),

            // 4. Mute indicator badge at top left
            Builder(
              builder: (context) {
                final callManagerWatch = context.watch<CallManager>();
                final String memberId = member['user_id']?.toString() ?? '';
                final bool isMuted = isMe
                    ? callManagerWatch.roomManager.isMuted
                    : (callManagerWatch.mutedParticipants[memberId] ??
                        (member['is_muted'] == true || member['isMuted'] == true));

                if (isMuted) {
                  return Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.95), // Premium crimson mute badge
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
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
