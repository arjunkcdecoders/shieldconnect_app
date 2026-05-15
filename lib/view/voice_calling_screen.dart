import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';

class VoiceCallingScreen extends StatelessWidget {
  final String userName;

  const VoiceCallingScreen({
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

                  // Dedicated dynamic timer badge
                  Text(
                    "00:05:10",
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
                          _buildRoundTool(
                            context,
                            asset: ImageAssets.videoOn,
                            isActive: false,
                          ),
                          const SizedBox(width: 8),
                          _buildRoundTool(
                            context,
                            asset: ImageAssets.micOff,
                            isActive: false,
                          ),
                          const SizedBox(width: 8),
                          _buildRoundTool(
                            context,
                            asset: ImageAssets.expand,
                            isActive: false,
                          ),
                          const SizedBox(width: 8),
                          _buildRoundTool(
                            context,
                            asset: ImageAssets.addUser,
                            isActive: false,
                          ),
                          const SizedBox(width: 12),

                          // B. Solid Red Immediate Termination Hangup Trigger
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
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
        color: appColor(context).white.withValues(alpha: 0.06),
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
