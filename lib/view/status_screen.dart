import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:shieldconnect_app/view/status_view_screen.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> recentUpdates = [
      {
        "name": "Mr. Strickland",
        "time": "4h ago",
        "segments": 3,
        "isRecent": true,
      },
      {
        "name": "Mr. Strickland",
        "time": "4h ago",
        "segments": 1,
        "isRecent": true,
      },
      {
        "name": "Mr. Strickland",
        "time": "4h ago",
        "segments": 4,
        "isRecent": true,
      },
      {
        "name": "Mr. Strickland",
        "time": "4h ago",
        "segments": 2,
        "isRecent": true,
      },
    ];

    final List<Map<String, dynamic>> viewedUpdates = [
      {
        "name": "Mr. Strickland",
        "time": "4h ago",
        "segments": 3,
        "isRecent": false,
      },
      {
        "name": "Mr. Strickland",
        "time": "4h ago",
        "segments": 2,
        "isRecent": false,
      },
    ];

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Consistent App Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage(ImageAssets.userAvatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: -4,
                          child: Image.asset(
                            ImageAssets.tick,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appColor(
                            context,
                          ).silver.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Image.asset(
                            ImageAssets.notification,
                            width: 22,
                            height: 22,
                            color: appColor(context).secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Screen Title
                Text(
                  "Status",
                  style: fontStyle.clashDisplayBold30.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 24),

                // My Status block
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatusViewScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage(ImageAssets.userAvatar),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: appColor(context).secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appColor(context).white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: appColor(context).white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "My status",
                              style: fontStyle.clashDisplaySemiBold16.textColor(
                                appColor(context).black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to add status update",
                              style: fontStyle.clashDisplayRegular12.textColor(
                                appColor(context).textMediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // First section: "Recent Updates"
                Text(
                  "Recent Updates",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Active status list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentUpdates.length,
                  itemBuilder: (context, index) {
                    return _buildStatusItem(context, recentUpdates[index]);
                  },
                ),
                const SizedBox(height: 12),

                // Second section label as formatted in mockup ("Recent Updates")
                Text(
                  "Viewed Updates",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Viewed/Inactive status list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewedUpdates.length,
                  itemBuilder: (context, index) {
                    return _buildStatusItem(context, viewedUpdates[index]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, Map<String, dynamic> status) {
    final bool isRecent = status["isRecent"] ?? false;
    final int segments = status["segments"] ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          // Custom Segmented Ring surrounding Avatar
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: StatusRingPainter(
                      segments: segments,
                      color: isRecent
                          ? appColor(context).secondary
                          : appColor(context).grey300,
                    ),
                  ),
                ),
                const CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage(ImageAssets.maisieAvatar),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Text descriptors
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status["name"],
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status["time"],
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).textMediumGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mathematical Status Segment Painter defining dynamic high-fidelity updates arcs.
class StatusRingPainter extends CustomPainter {
  final int segments;
  final Color color;

  StatusRingPainter({required this.segments, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.5;
    final Rect rect =
        const Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (segments <= 1) {
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }

    // Spacing in radians between status rings
    const double spacing = 0.25;
    final double availableAngle = (2 * pi) - (spacing * segments);
    final double arcLength = availableAngle / segments;

    double currentAngle = -pi / 2; // Orient upwards at 12 o'clock position

    for (int i = 0; i < segments; i++) {
      canvas.drawArc(rect, currentAngle, arcLength, false, paint);
      currentAngle += arcLength + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant StatusRingPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.color != color;
  }
}
