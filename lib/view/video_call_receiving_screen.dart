import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class VideoCallReceivingScreen extends StatelessWidget {
  final String userName;

  const VideoCallReceivingScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Immersive Full-Screen Distant Remote Video Background (Blurred for ringing state)
          Image.network(
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800", // High-fidelity professional male portrait seen in user mockup
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: appColor(context).grey900,
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: appColor(context).white24,
                    size: 80,
                  ),
                ),
              );
            },
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

          // 2. Top Styled Identity Information
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Text(
                    "Incoming video call...",
                    style: fontStyle.clashDisplayMedium14.textColor(appColor(context).white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
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
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F), // Vibrant material red hangup color
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallingScreen(userName: userName),
                          ),
                        );
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
    );
  }
}
