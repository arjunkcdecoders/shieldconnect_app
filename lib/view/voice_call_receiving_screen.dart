import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';

class VoiceCallReceivingScreen extends StatelessWidget {
  final String userName;

  const VoiceCallReceivingScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep luxurious immersive black background
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Main Centered Identity Block
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                          image: const DecorationImage(
                            image: AssetImage(ImageAssets.maisieAvatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bold styled user identity text
                  Text(
                    userName,
                    style: fontStyle.clashDisplayBold24.textColor(appColor(context).white),
                  ),
                  const SizedBox(height: 12),

                  // Incoming Call Status
                  Text(
                    "Incoming voice call...",
                    style: fontStyle.clashDisplayMedium14.textColor(
                      appColor(context).white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Incoming Call Actions
            Positioned(
              bottom: 48,
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

                  // Accept Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoiceCallingScreen(userName: userName),
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
                              Icons.call,
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
  }
}
