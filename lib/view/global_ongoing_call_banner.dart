import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/main.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class GlobalOngoingCallBanner extends StatelessWidget {
  const GlobalOngoingCallBanner({super.key});

  String? _normalizeAvatarUrl(dynamic avatar) {
    if (avatar == null || avatar is! String || avatar.isEmpty) return null;
    try {
      final uri = Uri.parse(avatar);
      return uri.replace(queryParameters: {}).toString();
    } catch (_) {
      return avatar;
    }
  }

  Widget _buildAvatarCircle(
    BuildContext context,
    String? avatar,
    String name,
    double size, {
    bool isGroup = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        color: const Color(0xFF262626),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: (avatar != null && avatar.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: ApiService.getImageUrl(avatar),
                cacheKey: _normalizeAvatarUrl(avatar),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white30,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildPlaceholderIcon(context, name, isGroup: isGroup),
              )
            : _buildPlaceholderIcon(context, name, isGroup: isGroup),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context, String name, {bool isGroup = false}) {
    return Center(
      child: Icon(
        isGroup ? Icons.group : Icons.person,
        color: Colors.white70,
        size: 18,
      ),
    );
  }

  Widget _buildAvatarStack(
    BuildContext context,
    List<Map<String, dynamic>> otherParticipants,
  ) {
    final double avatarSize = 40.0;
    final double overlapOffset = 14.0;
    final int count = otherParticipants.length;

    if (count == 1) {
      return _buildAvatarCircle(
        context,
        otherParticipants[0]['avatar'],
        otherParticipants[0]['name'] ?? 'User',
        avatarSize,
      );
    }

    final int displayCount = count > 3 ? 2 : count;
    final List<Widget> stackItems = [];

    // Flutter Stack items paint in order.
    // To match the mockup, the first participant (left-most) is painted first (bottom),
    // and subsequent participants overlap it from the right.
    for (int i = 0; i < displayCount; i++) {
      stackItems.add(
        Positioned(
          left: i * overlapOffset,
          child: _buildAvatarCircle(
            context,
            otherParticipants[i]['avatar'],
            otherParticipants[i]['name'] ?? 'User',
            avatarSize,
          ),
        ),
      );
    }

    if (count > 3) {
      final int remainingCount = count - 2;
      stackItems.add(
        Positioned(
          left: 2 * overlapOffset,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                "${remainingCount}+",
                style: fontStyle.clashDisplayBold12.textColor(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    final int totalCircles = count > 3 ? 3 : count;
    final double stackWidth = avatarSize + (totalCircles - 1) * overlapOffset;

    return SizedBox(
      width: stackWidth,
      height: avatarSize,
      child: Stack(clipBehavior: Clip.none, children: stackItems),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallManager, CallController>(
      builder: (context, callManager, callController, child) {
        if (callManager.state == CallState.idle || !callManager.isMinimized) {
          return const SizedBox.shrink();
        }

        final isVideo = callManager.isVideo;
        final duration = callManager.callDuration;

        // Resolve other active participants
        final myId = callManager.myUserId;
        final List<Map<String, dynamic>> otherParticipants = [];

        for (final p in callController.participants) {
          final pId = (p['user_id'] ?? p['id'] ?? p['_id'])?.toString();
          if (pId != null && pId != myId) {
            final String? status = p['status']?.toString().toLowerCase();
            if (status != 'left' &&
                status != 'declined' &&
                status != 'missed' &&
                status != 'rejected') {
              otherParticipants.add({
                'name':
                    p['name']?.toString() ??
                    p['username']?.toString() ??
                    'User',
                'avatar':
                    p['avatar']?.toString() ?? p['profile_pic']?.toString(),
              });
            }
          }
        }

        // Fallback for 1-on-1 call when participants list is not populated yet
        if (otherParticipants.isEmpty) {
          otherParticipants.add({
            'name': callManager.receiverName ?? 'User',
            'avatar': callManager.receiverAvatar,
          });
        }

        // Format names displayed in name banner
        String name = 'User';
        if (callManager.isGroup) {
          name = callManager.receiverName ?? 'Group';
        } else {
          if (otherParticipants.length == 1) {
            name = otherParticipants[0]['name'] ?? 'User';
          } else if (otherParticipants.length == 2) {
            name =
                "${otherParticipants[0]['name']} and ${otherParticipants[1]['name']}";
          } else if (otherParticipants.length == 3) {
            name =
                "${otherParticipants[0]['name']}, ${otherParticipants[1]['name']} and ${otherParticipants[2]['name']}";
          } else {
            name =
                "${otherParticipants[0]['name']}, ${otherParticipants[1]['name']} and ${otherParticipants.length - 2} others";
          }
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              callManager.setMinimized(false);
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => isVideo
                      ? VideoCallingScreen(userName: name)
                      : VoiceCallingScreen(
                          userName: name,
                          avatarUrl: otherParticipants.isNotEmpty
                              ? otherParticipants[0]['avatar']
                              : callManager.receiverAvatar,
                        ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: Dynamic Avatar Stack or Group Avatar
                        callManager.isGroup
                            ? _buildAvatarCircle(
                                context,
                                callManager.receiverAvatar,
                                name,
                                40.0,
                                isGroup: true,
                              )
                            : _buildAvatarStack(context, otherParticipants),
                        const SizedBox(width: 12),

                        // Middle: Call Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: fontStyle.clashDisplaySemiBold14
                                    .textColor(appColor(context).white),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.call,
                                    color: Color(0xFF1A9E16),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    callManager.state == CallState.connected
                                        ? "Ongoing Call"
                                        : "Incoming Call",
                                    style: fontStyle.clashDisplayMedium10
                                        .textColor(const Color(0xFF1A9E16)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    duration,
                                    style: fontStyle.clashDisplayMedium10
                                        .textColor(appColor(context).white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right: Solid Red Immediate Termination Hangup Trigger
                        GestureDetector(
                          onTap: () {
                            callManager.endCall();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 18,
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
        );
      },
    );
  }
}
