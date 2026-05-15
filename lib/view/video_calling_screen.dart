import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';

class VideoCallingScreen extends StatelessWidget {
  final String userName;

  const VideoCallingScreen({
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
          // 1. Immersive Full-Screen Distant Remote Video Background
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

          // Subtle top gradient layer to maintain text contrast on bright video feeds
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

          // 2. Top Styled Identity Information
          Positioned(
            top: 64,
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
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "00:05:10",
                    style: fontStyle.clashDisplayMedium14.textColor(appColor(context).white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating High-Fidelity Local PiP Video Feed Container
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
                    color: appColor(context).black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400", // High-fidelity female portrait matching local visual feeds
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: appColor(context).grey800,
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: appColor(context).white24,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
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
                      color: appColor(context).white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: appColor(context).white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: appColor(context).black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Standard circle utility tools
                        _buildRoundTool(
                          context,
                          asset: ImageAssets.videoOff,
                        ),
                        const SizedBox(width: 8),
                        _buildRoundTool(
                          context,
                          asset: ImageAssets.micOff,
                        ),
                        const SizedBox(width: 8),
                        _buildRoundTool(
                          context,
                          asset: ImageAssets.volume,
                        ),
                        const SizedBox(width: 14),

                        // Elongated solid RED hangup button seen on video calls mockup
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            width: 104,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F), // Vibrant crimson hangup tone
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                const BoxShadow(
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
    );
  }

  /// Render standard circular toolbar modifiers
  Widget _buildRoundTool(BuildContext context, {required String asset}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appColor(context).black.withValues(alpha: 0.6),
        border: Border.all(
          color: appColor(context).white.withValues(alpha: 0.12),
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
