import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/main.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class GlobalOngoingCallBanner extends StatelessWidget {
  const GlobalOngoingCallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallManager, CallController>(
      builder: (context, callManager, callController, child) {
        if (callManager.state == CallState.idle || !callManager.isMinimized) {
          return const SizedBox.shrink();
        }

        final isVideo = callManager.isVideo;
        final duration = callManager.callDuration;

        // Resolve dynamic display name based on active participants
        String name = callManager.receiverName ?? 'User';
        if (callController.participants.isNotEmpty) {
          final myId = callManager.myUserId;
          final otherParticipants = callController.participants.where((p) {
            final pId = (p['user_id'] ?? p['id'] ?? p['_id'])?.toString();
            return pId != null && pId != myId;
          }).toList();

          if (otherParticipants.isNotEmpty) {
            final otherNames = otherParticipants
                .map((p) => p['name']?.toString() ?? 'User')
                .where((n) => n.isNotEmpty)
                .toList();

            if (otherNames.isNotEmpty) {
              if (otherNames.length == 1) {
                name = otherNames[0];
              } else if (otherNames.length == 2) {
                name = "${otherNames[0]} and ${otherNames[1]}";
              } else {
                name = "${otherNames[0]} and ${otherNames.length - 1} others";
              }
            }
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
                          avatarUrl: callManager.receiverAvatar,
                        ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: appColor(context).white.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Pulsing Green Call Icon Container
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A9E16).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk,
                            color: Color(0xFF1A9E16),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Call information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Ongoing Call",
                                style: fontStyle.clashDisplayBold12.textColor(
                                  const Color(0xFF1A9E16),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: fontStyle.clashDisplaySemiBold14.textColor(
                                  appColor(context).white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Side timer badge & Return text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              duration,
                              style: fontStyle.clashDisplayBold14.textColor(
                                appColor(context).white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Tap to return",
                                  style: fontStyle.clashDisplayMedium10.textColor(
                                    appColor(context).white.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: appColor(context).white.withValues(alpha: 0.6),
                                  size: 10,
                                ),
                              ],
                            ),
                          ],
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
