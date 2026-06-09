import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/view/add_call_members_screen.dart';

class VideoCallingScreen extends StatelessWidget {
  final String userName;

  const VideoCallingScreen({super.key, required this.userName});

  List<Map<String, dynamic>> _buildGridMembers(
    CallManager callManager,
    CallController callController,
    BuildContext context,
  ) {
    final List<Map<String, dynamic>> gridMembers = [];

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
      String? resolvedAvatar = callManager.receiverAvatar;
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
        final bool isConnected = callManager.state == CallState.connected;
        if (isConnected && callController.hasFetchedParticipants) {
          hasLeft = true;
        }
      }

      if (callManager.roomManager.hasParticipantLeft(otherId)) {
        hasLeft = true;
      }

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
              (callManager.state == CallState.connected
                  ? 'connected'
                  : 'ringing'),
        });
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

    return gridMembers;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallManager, CallController>(
      builder: (context, callManager, callController, child) {
        final roomManager = callManager.roomManager;
        final isMuted = roomManager.isMuted;
        final isSpeakerOn = roomManager.isSpeakerOn;
        final isCameraOn = roomManager.isCameraOn;
        final localVideoTrack = roomManager.localVideoTrack;
        final isConnected = callManager.state == CallState.connected;

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

        final gridMembers = _buildGridMembers(
          callManager,
          callController,
          context,
        );
        final bool hasMultipleParticipants = gridMembers.length > 2;

        final activeOther = gridMembers.firstWhere(
          (m) => m['isMe'] != true,
          orElse: () => <String, dynamic>{},
        );

        // UI-level safeguard: Auto-end call if connected and no other participant is in the call
        if (!callManager.isGroup &&
            callManager.state == CallState.connected &&
            callManager.secondsElapsed > 2 &&
            callController.hasFetchedParticipants &&
            activeOther.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callManager.endCall();
          });
        }

        final String activeOtherId = activeOther.isNotEmpty
            ? (activeOther['user_id']?.toString() ?? '')
            : ((callManager.myUserId == callManager.callerId)
                  ? (callManager.receiverId ?? '')
                  : (callManager.callerId ?? ''));

        bool otherHasLeft = false;
        if (!callManager.isGroup &&
            activeOther.isEmpty &&
            activeOtherId.isNotEmpty) {
          if (roomManager.hasParticipantLeft(activeOtherId)) {
            otherHasLeft = true;
          } else {
            try {
              final matchingParticipant = callController.participants
                  .firstWhere((p) {
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
              final bool isConnected = callManager.state == CallState.connected;
              if (isConnected && callController.hasFetchedParticipants) {
                otherHasLeft = true;
              }
            }
          }
        }

        final String activeName =
            (callManager.isGroup && activeOther.isNotEmpty)
            ? "$userName - ${activeOther['name']}"
            : (callManager.isGroup || activeOther.isEmpty)
            ? (otherHasLeft ? '🔚📞' : userName)
            : (activeOther['name'] ?? userName);
        final String activeAvatar = (callManager.isGroup || activeOther.isEmpty)
            ? (otherHasLeft ? '' : (callManager.receiverAvatar ?? ''))
            : (activeOther['avatar']?.toString() ?? '');

        final bool isOtherMuted =
            callManager.mutedParticipants[activeOtherId] == true ||
            callController.participants.any((p) {
              final pId = p['user_id'] ?? p['id'] ?? p['_id'];
              return pId?.toString() == activeOtherId &&
                  (p['is_muted'] == true || p['isMuted'] == true);
            });

        // Dynamic lookup of the active remaining participant's video track in 1-to-1 mode
        final remoteVideoTrack =
            roomManager.getRemoteVideoTrackFor(activeOtherId) ??
            roomManager.remoteVideoTrack;
        final isRemoteVideoActive =
            remoteVideoTrack != null && !remoteVideoTrack.muted;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              callManager.setMinimized(true);
            }
          },
          child: Scaffold(
            backgroundColor: appColor(context).black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Content: Live Grid view or Immersive Full-Screen 1-to-1 Video/Avatar
                hasMultipleParticipants
                    ? Positioned.fill(
                        child: VideoCallGridView(
                          members: gridMembers,
                          callManager: callManager,
                          callController: callController,
                        ),
                      )
                    : (isRemoteVideoActive
                          ? lk.VideoTrackRenderer(remoteVideoTrack)
                          : (activeAvatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: ApiService.getImageUrl(
                                      activeAvatar,
                                    ),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: appColor(context).grey900,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: appColor(context).grey900,
                                          child: Center(
                                            child: Icon(
                                              callManager.isGroup
                                                  ? Icons.group
                                                  : Icons.person,
                                              color: appColor(
                                                context,
                                              ).white.withValues(alpha: 0.15),
                                              size: 100,
                                            ),
                                          ),
                                        ),
                                  )
                                : Container(
                                    color: appColor(context).grey900,
                                    child: Center(
                                      child: Icon(
                                        callManager.isGroup
                                            ? Icons.group
                                            : Icons.person,
                                        color: appColor(
                                          context,
                                        ).white.withValues(alpha: 0.15),
                                        size: 100,
                                      ),
                                    ),
                                  ))),

                // Apply heavy premium blur to the background when remote video is not yet active (only in 1-to-1)
                if (!hasMultipleParticipants && !isRemoteVideoActive)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: Container(
                        color: appColor(context).black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                // Subtle top gradient layer to maintain text contrast on bright video feeds
                if (!hasMultipleParticipants)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            appColor(context).black.withValues(alpha: 0.4),
                            appColor(context).transparent,
                            appColor(context).transparent,
                            appColor(context).black.withValues(alpha: 0.3),
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),

                // Callee circle avatar and status when calling / camera off (only in 1-to-1)
                if (!hasMultipleParticipants && !isRemoteVideoActive)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appColor(
                                    context,
                                  ).white.withValues(alpha: 0.3),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: appColor(
                                      context,
                                    ).black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: activeAvatar.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: ApiService.getImageUrl(
                                          activeAvatar,
                                        ),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              color: appColor(context).grey800,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: appColor(context)
                                                          .white
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: appColor(context).grey800,
                                              child: Center(
                                                child: Icon(
                                                  callManager.isGroup
                                                      ? Icons.group
                                                      : Icons.person,
                                                  color: appColor(context).white
                                                      .withValues(alpha: 0.5),
                                                  size: 60,
                                                ),
                                              ),
                                            ),
                                      )
                                    : Container(
                                        color: appColor(context).grey800,
                                        child: Center(
                                          child: Icon(
                                            callManager.isGroup
                                                ? Icons.group
                                                : Icons.person,
                                            color: appColor(
                                              context,
                                            ).white.withValues(alpha: 0.5),
                                            size: 60,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (isOtherMuted)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: appColor(context).white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.mic_off,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // if (callManager.statusText != null) ...[
                        //   const SizedBox(height: 16),
                        //   Text(
                        //     callManager.statusText!,
                        //     style: fontStyle.clashDisplaySemiBold16.textColor(
                        //       appColor(context).white,
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                  ),

                // 2. Top Styled Identity Information (only in 1-to-1)
                if (!hasMultipleParticipants)
                  Positioned(
                    top: 64,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  activeName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: fontStyle.clashDisplayBold20
                                      .textColor(appColor(context).white)
                                      .copyWith(
                                        shadows: [
                                          Shadow(
                                            color: appColor(context).black45,
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              if (isOtherMuted) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.mic_off,
                                  color: const Color(0xFFD32F2F),
                                  size: 22,
                                  shadows: [
                                    Shadow(
                                      color: appColor(context).black45,
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            callManager.statusText ??
                                (callManager.state == CallState.connected
                                    ? callManager.callDuration
                                    : "Calling..."),
                            style: fontStyle.clashDisplayMedium14.textColor(
                              appColor(context).white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Floating High-Fidelity Local PiP Video Feed Container (only in 1-to-1)
                if (!hasMultipleParticipants)
                  Positioned(
                    bottom: 120,
                    right: 24,
                    child: Container(
                      width: 108,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: appColor(context).white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appColor(
                              context,
                            ).black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: isCameraOn && localVideoTrack != null
                                  ? lk.VideoTrackRenderer(
                                      localVideoTrack,
                                      fit: lk.VideoViewFit.cover,
                                    )
                                  : Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Background shadow/avatar
                                        (myAvatar != null &&
                                                myAvatar.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    ApiService.getImageUrl(
                                                      myAvatar,
                                                    ),
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                      color: appColor(
                                                        context,
                                                      ).grey900,
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      color: appColor(
                                                        context,
                                                      ).grey900,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.person,
                                                          color:
                                                              appColor(context)
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                          size: 40,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: appColor(
                                                  context,
                                                ).grey900,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: appColor(context)
                                                        .white
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                        // Backdrop blur
                                        Positioned.fill(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 10.0,
                                              sigmaY: 10.0,
                                            ),
                                            child: Container(
                                              color: appColor(
                                                context,
                                              ).black.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                        // Small circle avatar in center
                                        Center(
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: appColor(
                                                  context,
                                                ).white.withValues(alpha: 0.3),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: appColor(context).black
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(26),
                                              child:
                                                  (myAvatar != null &&
                                                      myAvatar.isNotEmpty)
                                                  ? CachedNetworkImage(
                                                      imageUrl:
                                                          ApiService.getImageUrl(
                                                            myAvatar,
                                                          ),
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => Container(
                                                            color: appColor(
                                                              context,
                                                            ).grey800,
                                                            child: const Center(
                                                              child: SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white24,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => Container(
                                                            color: appColor(
                                                              context,
                                                            ).grey800,
                                                            child: Center(
                                                              child: Icon(
                                                                Icons.person,
                                                                color:
                                                                    appColor(
                                                                      context,
                                                                    ).white.withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                                size: 24,
                                                              ),
                                                            ),
                                                          ),
                                                    )
                                                  : Container(
                                                      color: appColor(
                                                        context,
                                                      ).grey800,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.person,
                                                          color:
                                                              appColor(context)
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                          size: 24,
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
                          if (isMuted)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD32F2F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic_off,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // 4. Bottom Blurry Glassmorphic Actions Toolbar
                Positioned(
                  bottom: 32,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: appColor(
                              context,
                            ).white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: appColor(
                                context,
                              ).white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: appColor(
                                  context,
                                ).black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Standard circle utility tools
                                GestureDetector(
                                  onTap: isConnected
                                      ? () {
                                          callManager.setCameraEnabled(
                                            !isCameraOn,
                                          );
                                        }
                                      : null,
                                  child: Opacity(
                                    opacity: isConnected ? 1.0 : 0.4,
                                    child: _buildRoundTool(
                                      context,
                                      asset: ImageAssets.videoOn,
                                      isActive: isCameraOn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: isConnected
                                      ? () {
                                          roomManager.switchCamera();
                                        }
                                      : null,
                                  child: Opacity(
                                    opacity: isConnected ? 1.0 : 0.4,
                                    child: _buildRoundTool(
                                      context,
                                      icon: Icons.cameraswitch_outlined,
                                      isActive: false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
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
                                const SizedBox(width: 6),
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
                                const SizedBox(width: 6),
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
                                const SizedBox(width: 10),

                                // Circular solid RED hangup button
                                GestureDetector(
                                  onTap: () {
                                    callManager.endCall();
                                  },
                                  child: Container(
                                    height: 44,
                                    width: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(
                                        0xFFD32F2F,
                                      ), // Vibrant crimson hangup tone
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
                ),

                // 5. Minimization Back Button
                Positioned(
                  top: 64,
                  left: 20,
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
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// Render standard circular toolbar modifiers
  Widget _buildRoundTool(
    BuildContext context, {
    String? asset,
    IconData? icon,
    required bool isActive,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? appColor(context).secondary.withValues(alpha: 0.8)
            : appColor(context).black.withValues(alpha: 0.6),
        border: Border.all(
          color: appColor(context).white.withValues(alpha: 0.12),
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

class VideoCallGridView extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final CallManager callManager;
  final CallController callController;

  const VideoCallGridView({
    super.key,
    required this.members,
    required this.callManager,
    required this.callController,
  });

  @override
  Widget build(BuildContext context) {
    final roomManager = callManager.roomManager;
    final total = members.length;

    // Calculate number of pages
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
      color: appColor(context).black,
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
                  callManager.statusText ??
                      (callManager.state == CallState.connected
                          ? callManager.callDuration
                          : "Calling..."),
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // PageView Grid Area
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
                        gridWidgets.add(_buildMemberCard(context, pageMembers[index], roomManager));
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
              const SizedBox(height: 100), // Space for bottom action bar
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
    dynamic roomManager,
  ) {
    final bool isMe = member['isMe'] == true;
    final String userId = member['user_id']?.toString() ?? '';
    final String? status = member['status']?.toString().toLowerCase();
    final bool isRemoteConnected = callManager.roomManager.room?.remoteParticipants.values
            .any((rp) => rp.identity == userId) ??
        false;
    final bool isCalling = !isMe &&
        !isRemoteConnected &&
        (status == 'ringing' || status == 'dialing' || status == 'invited' || status == null);
    final String name = member['name'] ?? 'User';
    final String? avatar = member['avatar'];

    // Check if camera is on and track is active
    bool isCameraOn = false;
    lk.VideoTrack? videoTrack;

    if (isMe) {
      isCameraOn = roomManager.isCameraOn;
      videoTrack = roomManager.localVideoTrack;
    } else {
      videoTrack = roomManager.getRemoteVideoTrackFor(userId);
      isCameraOn = videoTrack != null && !videoTrack.muted;
    }

    final bool isMuted = isMe
        ? roomManager.isMuted
        : (callManager.mutedParticipants[userId] == true ||
            callController.participants.any((p) {
              final pId = p['user_id'] ?? p['id'] ?? p['_id'];
              return pId?.toString() == userId &&
                  (p['is_muted'] == true || p['isMuted'] == true);
            }));

    final bool isActive = isCameraOn && videoTrack != null;
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
            // 1. Live video track or camera off avatar shadow + central circle
            isActive
                ? Positioned.fill(
                    child: lk.VideoTrackRenderer(
                      videoTrack!,
                      fit: lk.VideoViewFit.cover,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background shadow/avatar
                      (avatar != null && avatar.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: ApiService.getImageUrl(avatar),
                              cacheKey: _normalizeAvatarUrl(avatar),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: appColor(context).grey900,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: appColor(context).grey900,
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    color: appColor(context).white.withValues(alpha: 0.15),
                                    size: 60,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: appColor(context).grey900,
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: appColor(context).white.withValues(alpha: 0.15),
                                  size: 60,
                                ),
                              ),
                            ),
                      // Backdrop blur
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                          child: Container(
                            color: appColor(context).black.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      // Small circle avatar in center
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appColor(context).white.withValues(alpha: 0.3),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: appColor(context).black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: (avatar != null && avatar.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: ApiService.getImageUrl(avatar),
                                        cacheKey: _normalizeAvatarUrl(avatar),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: appColor(context).grey800,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: appColor(context).grey800,
                                          child: Center(
                                            child: Icon(
                                              Icons.person,
                                              color: appColor(context).white.withValues(alpha: 0.5),
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: appColor(context).grey800,
                                        child: Center(
                                          child: Icon(
                                            Icons.person,
                                            color: appColor(context).white.withValues(alpha: 0.5),
                                            size: 36,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (isCalling) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Calling..",
                                style: fontStyle.clashDisplayMedium12.textColor(Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

            // 2. Name badge overlay at bottom center/left
            if (!isMe)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: fontStyle.clashDisplaySemiBold12.textColor(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. "Me" pill badge at top right
            if (isMe)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            if (isMuted)
              Positioned(
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
              ),
          ],
        ),
      ),
    );
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
}
