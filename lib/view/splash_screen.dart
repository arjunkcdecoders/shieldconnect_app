import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/splash_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger navigation logic from the controller after current build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SplashController>(context, listen: false).initSplash(context);
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              ImageAssets.splashscreenVector,
              width: MediaQuery.sizeOf(context).width * 0.8,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  ImageAssets.appIcon,
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Shield',
                        style: fontStyle.clashDisplayBold34
                            .textColor(appColor(context).darkText)
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                      ),
                      TextSpan(
                        text: 'Connect\u2122',
                        style: fontStyle.clashDisplayBold34
                            .textColor(appColor(context).darkText)
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Protecting every connection that matters.',
                  textAlign: TextAlign.center,
                  style: fontStyle.clashDisplayRegular14
                      .textColor(appColor(context).darkGrey)
                      .copyWith(
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
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


