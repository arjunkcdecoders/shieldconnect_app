import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/bottomnav_controller.dart';
import 'package:shieldconnect_app/controller/moderator/moderator_home_controller.dart';
import 'package:shieldconnect_app/controller/moderator/moderator_users_controller.dart';
import 'package:shieldconnect_app/controller/moderator/moderation_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/moderator/home_screen/home_screen.dart';
import 'package:shieldconnect_app/view/moderator/moderation_screen/moderation_screen.dart';
import 'package:shieldconnect_app/view/moderator/profile_screen/profile_screen.dart';
import 'package:shieldconnect_app/view/moderator/users_screen/users_screen.dart';

class BottomnavScreen extends StatelessWidget {
  const BottomnavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomnavController()),
        ChangeNotifierProvider(create: (_) => ModeratorHomeController()),
        ChangeNotifierProvider(create: (_) => ModeratorUsersController()),
        ChangeNotifierProvider(create: (_) => ModerationController()),
      ],
      child: Consumer<BottomnavController>(
        builder: (context, controller, _) {
          final List<Widget> screens = [
            const HomeScreen(),
            const UsersScreen(),
            const ModerationScreen(),
            const ProfileScreen(),
          ];

          return Scaffold(
            body: screens[controller.currentIndex],
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: appColor(context).white,
                boxShadow: [
                  BoxShadow(
                    color: appColor(context).black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context,
                      index: 0,
                      icon: controller.currentIndex == 0
                          ? ImageAssets.homeActive
                          : ImageAssets.home,
                      label: 'Home',
                      currentIndex: controller.currentIndex,
                      onTap: () => controller.changeIndex(0),
                    ),
                    _buildNavItem(
                      context,
                      index: 1,
                      icon: controller.currentIndex == 1
                          ? ImageAssets.usersActive
                          : ImageAssets.users,
                      label: 'Users',
                      currentIndex: controller.currentIndex,
                      onTap: () => controller.changeIndex(1),
                    ),
                    _buildNavItem(
                      context,
                      index: 2,
                      icon: controller.currentIndex == 2
                          ? ImageAssets.moderationActive
                          : ImageAssets.moderation,
                      label: 'Moderation',
                      currentIndex: controller.currentIndex,
                      onTap: () => controller.changeIndex(2),
                    ),
                    _buildNavItem(
                      context,
                      index: 3,
                      icon: controller.currentIndex == 3
                          ? ImageAssets.profileActive
                          : ImageAssets.profile,
                      label: 'Profile',
                      currentIndex: controller.currentIndex,
                      onTap: () => controller.changeIndex(3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required String icon,
    required String label,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    bool isSelected = currentIndex == index;
    Color color = isSelected
        ? appColor(context).primary
        : appColor(context).darkGrey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            height: 24,
            width: 24,
            // color: color, // Removed to allow asset colors to show
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: fontStyle.clashDisplayMedium12.textColor(color).size(12),
          ),
        ],
      ),
    );
  }
}
