import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/onboarding_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Navigation Bar (Back & Skip)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (shown on 2nd and 3rd screens)
                  if (controller.currentPage > 0)
                    TextButton(
                      onPressed: () => controller.previousPage(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: appColor(context).black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Back",
                            style: fontStyle.clashDisplayRegular14
                                .textColor(appColor(context).black)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Skip Button
                  TextButton(
                    onPressed: () => controller.skip(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Skip",
                          style: fontStyle.clashDisplayRegular14
                              .textColor(appColor(context).black)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: appColor(context).black,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Center PageView containing the images
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.updatePage,
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Image.asset(item.image, fit: BoxFit.contain);
                },
              ),
            ),

            // Bottom Static Card Section with curved bottom
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // The Red Gradient Card with precise notched bottom
                  ClipPath(
                    clipper: CardNotchClipper(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 15, // Increased height padding
                        bottom:
                            70, // Increased height padding to make card taller
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            appColor(context).primary,
                            appColor(context).primaryDark,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Page indicator dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              controller.items.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: controller.currentPage == index ? 20 : 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: controller.currentPage == index
                                      ? appColor(context).white
                                      : appColor(
                                          context,
                                        ).white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title Text
                          Text(
                            "ShieldConnect™",
                            textAlign: TextAlign.center,
                            style: fontStyle.clashDisplaySemiBold24.textColor(
                              appColor(context).white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Dynamic Content (Headline & Subtitle)
                          Text(
                            controller.items[controller.currentPage].headline,
                            textAlign: TextAlign.center,
                            style: fontStyle.clashDisplayMedium20.textColor(
                              appColor(context).white,
                            ),
                            // .copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            controller.items[controller.currentPage].subtitle,
                            textAlign: TextAlign.center,
                            style: fontStyle.clashDisplayRegular14.textColor(
                              appColor(context).white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // The navigation circular button nesting precisely in the notch
                  Positioned(
                    bottom: -35, // Split exactly at center of 70px container
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: appColor(context).white,
                        shape: BoxShape.circle,
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: appColor(context).black.withValues(alpha: 0.1),
                        //     blurRadius: 8,
                        //     offset: const Offset(0, 4),
                        //   ),
                        // ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: GestureDetector(
                        onTap: () => controller.nextPage(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                appColor(context).secondary,
                                appColor(context).primary,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: appColor(context).white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Extra space underneath for overlapping button
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}

// Precise Clipper generating corner radius and inverted semi-circle notch
class CardNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double cornerRadius = 30.0;
    const double notchRadius =
        30.0; // Proportional clearance for a 70px circle (radius 35)

    // Start Top Left
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Top Edge to Top Right
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right Edge to Bottom Right
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bottom Edge from Right to Notch edge
    final double centerX = size.width / 2;
    path.lineTo(centerX + notchRadius, size.height);

    // Semi-circular NOTCH (Arcing UPWARDS)
    path.arcToPoint(
      Offset(centerX - notchRadius, size.height),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Bottom Edge from Notch to Bottom Left
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
