import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class VideoCallReceivingScreen extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const VideoCallReceivingScreen({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CallManager>(
      builder: (context, callManager, child) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              callManager.setMinimized(true);
            }
          },
          child: callManager.state == CallState.connected
              ? VideoCallingScreen(userName: userName)
              : Scaffold(
                  backgroundColor: appColor(context).black,
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Immersive Full-Screen Distant Remote Video Background (Blurred for ringing state)
                      (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: ApiService.getImageUrl(avatarUrl!),
                              cacheKey: _normalizeAvatarUrl(avatarUrl!),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: appColor(context).grey900,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: appColor(context).white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: appColor(context).grey900,
                                child: Center(
                                  child: Icon(
                                    callManager.isGroup ? Icons.group : Icons.person,
                                    color: appColor(context).white.withValues(alpha: 0.15),
                                    size: 100,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: appColor(context).grey900,
                              child: Center(
                                child: Icon(
                                  callManager.isGroup ? Icons.group : Icons.person,
                                  color: appColor(context).white.withValues(alpha: 0.15),
                                  size: 100,
                                ),
                              ),
                            ),

                      // Apply heavy premium blur to the background to signify pending connection
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Container(
                            color: appColor(context).black.withValues(alpha: 0.3),
                          ),
                        ),
                      ),

                      // Subtle top/bottom gradient layer to maintain text and button contrast
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                appColor(context).black.withValues(alpha: 0.6),
                                appColor(context).transparent,
                                appColor(context).transparent,
                                appColor(context).black.withValues(alpha: 0.5),
                              ],
                              stops: const [0.0, 0.2, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 2. Centered Identity Information & Avatar
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Pulsing outer avatar glow container
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
                                      child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(70),
                                              child: CachedNetworkImage(
                                                imageUrl: ApiService.getImageUrl(avatarUrl!),
                                                cacheKey: _normalizeAvatarUrl(avatarUrl!),
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
                                                  callManager.isGroup ? Icons.group : Icons.person,
                                                  color: appColor(context).white,
                                                  size: 64,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              callManager.isGroup ? Icons.group : Icons.person,
                                              color: appColor(context).white,
                                              size: 64,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Bold styled user identity text
                            Text(
                              userName,
                              style: fontStyle.clashDisplayBold24.textColor(appColor(context).white).copyWith(
                                shadows: [
                                  Shadow(
                                    color: appColor(context).black45,
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Incoming Call Status
                            Text(
                              callManager.statusText ?? (callManager.incomingParticipantsCount > 1
                                  ? "Incoming video call... (${callManager.incomingParticipantsCount} members in this call)"
                                  : "Incoming video call..."),
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Bottom Incoming Call Actions
                      Positioned(
                        bottom: 64,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Decline Button
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
                                      child: Icon(
                                        Icons.call_end,
                                        color: appColor(context).white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Decline",
                                  style: fontStyle.clashDisplayMedium14.textColor(
                                    appColor(context).white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),

                            // Accept Video Button
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
                                      color: Color(0xFF23C123), // Vibrant active call green
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
                                      child: Icon(
                                        Icons.videocam,
                                        color: appColor(context).white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Accept",
                                  style: fontStyle.clashDisplayMedium14.textColor(
                                    appColor(context).white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
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
