import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/call_list_controller.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/dhsi_controller.dart';

class BottomnavScreen extends StatelessWidget {
  const BottomnavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BottomnavController>(context);

    // Call checkStatusFeature in post frame callback to avoid setstate during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkStatusFeature();
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: controller.currentScreen,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: appColor(context).black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: controller.currentIndex,
          onTap: (index) {
            controller.changeTab(index);
            
            // Map back to original indices for controller initialization
            int resolvedIndex = index;
            if (!controller.statusFeatureEnabled && index >= 3) {
              resolvedIndex = index + 1;
            }

            if (resolvedIndex == 0) {
              Provider.of<HomeScreenController>(context, listen: false).init();
            } else if (resolvedIndex == 1) {
              Provider.of<CallListController>(context, listen: false).init();
            } else if (resolvedIndex == 2) {
              final userId = Provider.of<ProfileController>(context, listen: false).userId;
              if (userId.isNotEmpty) {
                Provider.of<DhsiController>(context, listen: false).fetchDhsiData(userId);
              }
            } else if (resolvedIndex == 3) {
              Provider.of<StatusController>(context, listen: false).init();
            } else if (resolvedIndex == 4) {
              Provider.of<ProfileController>(context, listen: false).init(context: context);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: appColor(context).white,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: appColor(context).primary,
          unselectedItemColor: appColor(context).textGrey,
          selectedLabelStyle: fontStyle.clashDisplayMedium12
              .textColor(appColor(context).primary)
              .copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: fontStyle.clashDisplayMedium12
              .textColor(appColor(context).textGrey)
              .copyWith(fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                ImageAssets.chatInActive,
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                ImageAssets.chatActive,
                width: 24,
                height: 24,
              ),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                ImageAssets.callInActive,
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                ImageAssets.callActive,
                width: 24,
                height: 24,
              ),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                ImageAssets.dhsiInactive,
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                ImageAssets.dhsi,
                width: 24,
                height: 24,
              ),
              label: 'DHSI',
            ),
            if (controller.statusFeatureEnabled)
              BottomNavigationBarItem(
                icon: Image.asset(
                  ImageAssets.statusInActive,
                  width: 24,
                  height: 24,
                ),
                activeIcon: Image.asset(
                  ImageAssets.statusActive,
                  width: 24,
                  height: 24,
                ),
                label: 'Status',
              ),
            BottomNavigationBarItem(
              icon: Image.asset(
                ImageAssets.settingsInActive,
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                ImageAssets.settingsActive,
                width: 24,
                height: 24,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
