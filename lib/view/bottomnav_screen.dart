import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class BottomnavScreen extends StatelessWidget {
  const BottomnavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BottomnavController>(context);

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
          onTap: controller.changeTab,
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
