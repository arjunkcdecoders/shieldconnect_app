import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/launch_loading_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class LaunchLoadingScreen extends StatelessWidget {
  const LaunchLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<LaunchLoadingController>().startTimer(context);
      }
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.2, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.linear,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Image.asset(
            ImageAssets.appIcon,
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
  }
}
