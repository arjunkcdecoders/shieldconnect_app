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
import 'package:shieldconnect_app/services/socket_service.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';


class VoiceCallingScreen extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const VoiceCallingScreen({
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

    // Resolve "Me" avatar robustly from various providers
    String? myAvatar = callManager.myUserAvatar;
    if (myAvatar == null || myAvatar.isEmpty) {
      try {
        final profileController = Provider.of<ProfileController>(context, listen: false);
        if (profileController.imageUrl.isNotEmpty) {
          myAvatar = profileController.imageUrl;
        }
      } catch (_) {}
    }
    if (myAvatar == null || myAvatar.isEmpty) {
      try {
        final homeController = Provider.of<HomeScreenController>(context, listen: false);
        if (homeController.profileImage != null && homeController.profileImage!.isNotEmpty) {
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
      bool hasLeft = false;
      try {
        final matchingParticipant = callController.participants.firstWhere(
          (p) {
            final pId = p['user_id'] ?? p['id'] ?? p['_id'];
            return pId?.toString() == otherId;
          },
        );
        final String? status = matchingParticipant['status']?.toString().toLowerCase();
        if (status == 'left' || status == 'declined' || status == 'missed' || status == 'rejected') {
          hasLeft = true;
        }
      } catch (_) {
        // If otherId is not found in participants list and we have successfully fetched participants, then they have left.
        if (callController.hasFetchedParticipants) {
          hasLeft = true;
        }
      }

      if (!hasLeft) {
        final bool isOtherMuted = callManager.mutedParticipants[otherId] == true || 
            callController.participants.any((p) {
              final pId = p['user_id'] ?? p['id'] ?? p['_id'];
              return pId?.toString() == otherId && (p['is_muted'] == true || p['isMuted'] == true);
            });

        gridMembers.add({
          'user_id': otherId,
          'name': userName,
          'avatar': avatarUrl,
          'isMe': false,
          'is_muted': isOtherMuted,
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

      if (pId != null) {
        final isDup = gridMembers.any((m) => m['user_id'].toString() == pId.toString());
        if (!isDup) {
          gridMembers.add({
            'user_id': pId.toString(),
            'name': pName,
            'avatar': pAvatar,
            'isMe': pId.toString() == callManager.myUserId.toString(),
            'is_muted': pMute,
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
        final isVideoActive = callManager.isVideo || roomManager.isCameraOn || roomManager.remoteVideoTrack != null;
        if (isVideoActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callManager.setVideoCallMode(true);
          });
          return VideoCallingScreen(userName: userName);
        }

        final isMuted = roomManager.isMuted;
        final isSpeakerOn = roomManager.isSpeakerOn;

        // Build call members list for grid view
        final gridMembers = _buildGridMembers(callManager, callController, context);
        final hasAddedMembers = gridMembers.length >= 3;

        // Resolve dynamic single member details when falling back to 1-to-1 UI
        final activeOther = gridMembers.firstWhere(
          (m) => m['isMe'] != true,
          orElse: () => <String, dynamic>{},
        );

        // UI-level safeguard: Auto-end call if connected and no other active participant is in the call
        if (callManager.state == CallState.connected && activeOther.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            dev.log('👥 VoiceCallingScreen: Rebuilt grid has only Me left. Automatically ending call.', name: 'VoiceCallingScreen');
            callManager.endCall();
          });
        }

        final String activeName = activeOther.isNotEmpty 
            ? (activeOther['name'] ?? userName) 
            : userName;
        final String? activeAvatar = activeOther.isNotEmpty 
            ? activeOther['avatar'] 
            : avatarUrl;

        final bool isCallEnding = callManager.state == CallState.idle ||
            (callManager.state == CallState.connected && activeOther.isEmpty);

        dev.log(
          '📞 VoiceCallingScreen build: callState=${callManager.state}, activeOther.isEmpty=${activeOther.isEmpty}, isCallEnding=$isCallEnding',
          name: 'VoiceCallingScreen',
        );

        return Scaffold(
          backgroundColor: const Color(0xFF121212), // Deep luxurious immersive black background
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Background Content: Grid view or standard layout
                hasAddedMembers
                    ? Positioned.fill(
                        child: CallGridView(
                          members: gridMembers,
                          callDuration: callManager.state == CallState.connected
                              ? callManager.callDuration
                              : "Calling...",
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
                                    ? (activeOther['user_id']?.toString() ?? '')
                                    : ((callManager.myUserId == callManager.callerId)
                                        ? (callManager.receiverId ?? '')
                                        : (callManager.callerId ?? ''));
                                final bool isOtherMuted = activeOther.isNotEmpty
                                    ? (activeOther['is_muted'] == true)
                                    : (callManager.mutedParticipants[otherId] == true || 
                                        callController.participants.any((p) {
                                          final pId = p['user_id'] ?? p['id'] ?? p['_id'];
                                          return pId?.toString() == otherId && (p['is_muted'] == true || p['isMuted'] == true);
                                        }));
                                final isConnected = callManager.state == CallState.connected;

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
                                            color: appColor(context).white.withValues(alpha: 0.04),
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
                                              color: appColor(context).white.withValues(alpha: 0.1),
                                              width: 2,
                                            ),
                                            color: appColor(context).white.withValues(alpha: 0.06),
                                          ),
                                          child: (activeAvatar != null && activeAvatar.isNotEmpty)
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(70),
                                                  child: CachedNetworkImage(
                                                    imageUrl: ApiService.getImageUrl(activeAvatar),
                                                    cacheKey: _normalizeAvatarUrl(activeAvatar),
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => const Center(
                                                      child: SizedBox(
                                                        width: 32,
                                                        height: 32,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white30,
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => Icon(
                                                      Icons.person,
                                                      color: appColor(context).white,
                                                      size: 64,
                                                    ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  color: appColor(context).white,
                                                  size: 64,
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
                                            color: const Color(0xFFD32F2F).withValues(alpha: 0.95), // Premium crimson mute badge
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
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
                              style: fontStyle.clashDisplayBold24.textColor(appColor(context).white),
                            ),
                            const SizedBox(height: 12),

                            // Dedicated dynamic timer badge
                            Text(
                              callManager.state == CallState.connected
                                  ? callManager.callDuration
                                  : "Calling...",
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).white.withValues(alpha: 0.7),
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
                            color: const Color(0xFF262626).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: appColor(context).white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: appColor(context).black.withValues(alpha: 0.2),
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
                                onTap: () {
                                  callManager.setCameraEnabled(!roomManager.isCameraOn);
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
                                  asset: isMuted ? ImageAssets.micOff : ImageAssets.recorder,
                                  isActive: !isMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  roomManager.setSpeakerphoneOn(!isSpeakerOn);
                                },
                                child: _buildRoundTool(
                                  context,
                                  asset: ImageAssets.volume,
                                  isActive: isSpeakerOn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: callManager.state == CallState.connected
                                    ? () {
                                        showAddUserDialog(context, callManager.myUserId);
                                      }
                                    : null,
                                child: Opacity(
                                  opacity: callManager.state == CallState.connected ? 1.0 : 0.4,
                                  child: _buildRoundTool(
                                    context,
                                    asset: ImageAssets.addUser,
                                    isActive: callManager.state == CallState.connected,
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
                                    color: Color(0xFFD32F2F), // Vibrant material red hangup color
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// Render individual dark circular utilities within call toolbar
  Widget _buildRoundTool(
    BuildContext context, {
    required String asset,
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
        child: Image.asset(
          asset,
          color: appColor(context).white,
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}

class AddUserDialog extends StatelessWidget {
  const AddUserDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Add Members",
                      style: fontStyle.clashDisplayBold18.textColor(Colors.white),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content
                Flexible(
                  child: Consumer<CallController>(
                    builder: (context, controller, child) {
                      if (controller.isLoadingFriends) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                              color: Color(0xFF23C123),
                            ),
                          ),
                        );
                      }

                      if (controller.friendsErrorMessage != null) {
                        return Center(
                          child: Text(
                            controller.friendsErrorMessage!,
                            style: fontStyle.clashDisplayMedium12.textColor(Colors.white70),
                          ),
                        );
                      }

                       final callManager = Provider.of<CallManager>(context, listen: false);
                       final String myId = callManager.myUserId ?? '';
                       final String otherId = (callManager.myUserId == callManager.callerId)
                           ? (callManager.receiverId ?? '')
                           : (callManager.callerId ?? '');

                       final Set<String> existingUserIds = {myId, otherId};
                       for (final p in controller.participants) {
                         final pId = p['user_id'] ?? p['id'] ?? p['_id'];
                         if (pId != null) {
                           existingUserIds.add(pId.toString());
                         }
                       }

                        final filteredFriends = controller.friends.where((friend) {
                          // Only allow online users
                          if (friend['is_online'] != true) return false;

                          final friendId = friend['user_id'] ?? friend['id'] ?? friend['_id'];
                          if (friendId == null) return true;
                          return !existingUserIds.contains(friendId.toString());
                        }).toList();

                       if (filteredFriends.isEmpty) {
                         return Center(
                           child: Padding(
                             padding: const EdgeInsets.symmetric(vertical: 40),
                             child: Text(
                               controller.friends.isEmpty
                                   ? "No connected friends found."
                                   : "All friends are already in the call.",
                               style: fontStyle.clashDisplayMedium12.textColor(Colors.white54),
                             ),
                           ),
                         );
                       }

                       return ListView.separated(
                         shrinkWrap: true,
                         physics: const BouncingScrollPhysics(),
                         itemCount: filteredFriends.length,
                        separatorBuilder: (context, index) => Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          final String friendName = friend['name'] ?? 'User';
                          final String? friendAvatar = friend['avatar'];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                // Avatar Squircle or circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      width: 1.5,
                                    ),
                                    image: (friendAvatar != null && friendAvatar.isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(ApiService.getImageUrl(friendAvatar)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  child: (friendAvatar != null && friendAvatar.isNotEmpty)
                                      ? null
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friendName,
                                        style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        friend['is_online'] == true ? "Online" : "Offline",
                                        style: fontStyle.clashDisplayMedium10.textColor(
                                          friend['is_online'] == true
                                              ? const Color(0xFF23C123)
                                              : Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Invite/Add Button
                                GestureDetector(
                                  onTap: () async {
                                    final callManager = Provider.of<CallManager>(context, listen: false);
                                    final callId = callManager.currentCallId;
                                    final friendId = friend['user_id'] ?? friend['id'] ?? friend['_id'];
                                    if (context.mounted) {
                                      Navigator.pop(context); // Close the sheet/dialog immediately
                                    }
                                    if (callId != null && friendId != null) {
                                      final controller = Provider.of<CallController>(context, listen: false);
                                      final success = await controller.addParticipant(callId, friendId.toString());
                                      if (success) {
                                        // Gather all unique active participant IDs and names
                                        final List<String> pIds = [];
                                        final List<String> pNames = [];
                                        
                                        // 1. Add "Me" / Caller
                                        String? myName = callManager.myUserName;
                                        if (myName == null || myName.isEmpty || myName == 'User') {
                                          try {
                                            final profileController = Provider.of<ProfileController>(context, listen: false);
                                            if (profileController.name.isNotEmpty) {
                                              myName = profileController.name;
                                            }
                                          } catch (_) {}
                                        }

                                        String? myAvatar = callManager.myUserAvatar;
                                        if (myAvatar == null || myAvatar.isEmpty) {
                                          try {
                                            final profileController = Provider.of<ProfileController>(context, listen: false);
                                            if (profileController.imageUrl.isNotEmpty) {
                                              myAvatar = profileController.imageUrl;
                                            }
                                          } catch (_) {}
                                        }

                                        if (callManager.myUserId != null) {
                                          pIds.add(callManager.myUserId!);
                                          pNames.add(myName ?? 'User');
                                        }

                                        // 2. Add other participants from controller.participants
                                        for (final p in controller.participants) {
                                          final pId = (p['user_id'] ?? p['id'] ?? p['_id'])?.toString();
                                          final pName = (p['name'] ?? p['username'] ?? 'User').toString();
                                          if (pId != null && pId.isNotEmpty && !pIds.contains(pId)) {
                                            pIds.add(pId);
                                            pNames.add(pName);
                                          }
                                        }

                                        // 3. Make sure the newly added friend is included
                                        final String friendIdStr = friendId.toString();
                                        if (!pIds.contains(friendIdStr)) {
                                          pIds.add(friendIdStr);
                                          pNames.add(friendName);
                                        }

                                        final Map<String, dynamic> socketData = {
                                          'callId': callId,
                                          'roomId': callManager.currentRoomId,
                                          'callerId': callManager.myUserId,
                                          'callerName': myName,
                                          'callerAvatar': myAvatar,
                                          'receiverId': friendId.toString(),
                                          'receiverIds': [friendId.toString()],
                                          'isVideo': callManager.isVideo,
                                          'isGroup': true,
                                          'groupName': callManager.isGroup
                                              ? (callManager.receiverName ?? "Group Call")
                                              : (myName ?? "Group Call"),
                                          'groupAvatar': callManager.isGroup
                                              ? (callManager.receiverAvatar ?? "")
                                              : (myAvatar ?? ""),
                                          'participantIds': pIds,
                                          'participantNames': pNames,
                                          'participantsCount': pIds.length,
                                        };
                                        SocketService().emit('call_user', socketData);
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF23C123).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF23C123).withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      "Add",
                                      style: fontStyle.clashDisplayBold10.textColor(const Color(0xFF23C123)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final total = members.length;
    final int numPages = total <= 6 ? 1 : 1 + ((total - 6) / 5.0).ceil();
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Top timer display
              Text(
                callDuration,
                style: fontStyle.clashDisplaySemiBold16.textColor(Colors.white70),
              ),
              const SizedBox(height: 24),
              // Grid Area inside PageView
              Expanded(
                child: PageView.builder(
                  controller: callController.pageController,
                  itemCount: numPages,
                  onPageChanged: callController.setCurrentPage,
                  itemBuilder: (context, pageIndex) {
                    // Extract items for this page index
                    List<Map<String, dynamic>> pageMembers = [];
                    bool showIndicatorCard = false;
                    List<Map<String, dynamic>> remainingMembersForIndicator = [];

                    if (total <= 6) {
                      pageMembers = members;
                    } else {
                      final int startIndex = pageIndex * 5;
                      if (pageIndex < numPages - 1) {
                        // Non-last page: show 5 members + 1 indicator card
                        final int endIndex = startIndex + 5;
                        pageMembers = members.sublist(startIndex, endIndex);
                        showIndicatorCard = true;
                        remainingMembersForIndicator = members.sublist(endIndex);
                      } else {
                        // Last page: show remaining members
                        pageMembers = members.sublist(startIndex);
                      }
                    }

                    final int gridItemCount = pageMembers.length + (showIndicatorCard ? 1 : 0);

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Scroll managed by PageView
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: gridItemCount,
                      itemBuilder: (context, index) {
                        if (showIndicatorCard && index == 5) {
                          final remaining = remainingMembersForIndicator;
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
                                                          errorWidget: (context, url, error) => const Icon(
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

                        final member = pageMembers[index];
                        final String name = member['name'] ?? 'User';
                        final String? avatar = member['avatar'];
                        final bool isMe = member['isMe'] == true;

                        return Container(
                          decoration: BoxDecoration(
                            color: isMe 
                                ? const Color(0xFF6B1D2F).withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isMe 
                                  ? const Color(0xFF8B263E).withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
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
                                  Positioned.fill(
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
                                    final callManager = context.watch<CallManager>();
                                    final String memberId = member['user_id']?.toString() ?? '';
                                    final bool isMuted = isMe 
                                        ? callManager.roomManager.isMuted 
                                        : (callManager.mutedParticipants[memberId] ?? (member['is_muted'] == true || member['isMuted'] == true));

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
                      },
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
                            : Colors.white.withValues(alpha: 0.3), // Inactive dot
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
}

void showAddUserDialog(BuildContext context, String? myUserId) {
  Provider.of<CallController>(context, listen: false).fetchFriends(myUserId);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const AddUserDialog(),
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

