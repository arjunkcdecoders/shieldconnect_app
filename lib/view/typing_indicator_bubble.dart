import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';

class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate a periodic stream of ticks every 120 milliseconds to animate the rolling bounce waves
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(milliseconds: 120), (x) => x),
      builder: (context, snapshot) {
        final int tick = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(4), // speech bubble incoming tail
            ),
            boxShadow: [
              BoxShadow(
                color: appColor(context).black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              // Mathematical rolling wave translation based on delay index and tick count
              final double phase = (tick - index * 2) * 0.4;
              final double yTranslation = -sin(phase).clamp(0.0, 1.0) * 4.5; // Bounces upwards up to 4.5 pixels

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.8),
                transform: Matrix4.translationValues(0, yTranslation, 0),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: appColor(context).secondary, // Premium vibrant pink app theme color
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
