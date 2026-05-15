import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:shieldconnect_app/view/edit_profile_screen.dart';
import 'package:shieldconnect_app/view/account_screen.dart';
import 'package:shieldconnect_app/view/archived_chats_screen.dart';
import 'package:shieldconnect_app/view/help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                // Top header aligning Settings and Notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Profile",
                      style: fontStyle.clashDisplaySemiBold20.textColor(
                        appColor(context).black,
                      ),
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
                const SizedBox(height: 24),

                // Focused User Summary Block
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stylized Squircle profile image
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              image: const DecorationImage(
                                image: AssetImage(ImageAssets.userAvatar),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Image.asset(
                              ImageAssets.tick,
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Bruce Wayne",
                        style: fontStyle.clashDisplaySemiBold16.textColor(
                          appColor(context).black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Happy Life 🥰",
                        style: fontStyle.clashDisplayMedium10.textColor(
                          appColor(context).textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Core settings menu hierarchy
                _buildMenuCard(
                  context,
                  iconAsset: ImageAssets.edit,
                  title: "Edit Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  iconAsset: ImageAssets.key,
                  title: "Account",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  iconAsset: ImageAssets.theme,
                  title: "Theme",
                  onTap: () => _showThemeBottomSheet(context),
                ),
                _buildMenuCard(
                  context,
                  iconAsset: ImageAssets.archive,
                  title: "Archived Chats",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArchivedChatsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  iconAsset: ImageAssets.addPerson,
                  title: "Help & Support",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Destructive system action paths
                GestureDetector(
                  onTap: () => _showLogoutBottomSheet(context),
                  child: Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: appColor(context).secondary,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: appColor(context).secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Log Out",
                            style: fontStyle.clashDisplaySemiBold14.textColor(
                              appColor(context).secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => _showDeleteBottomSheet(context),
                    child: Text(
                      "Delete Account",
                      style: fontStyle.clashDisplayBold12.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Software integrity signature footer
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(ImageAssets.appIcon, width: 32, height: 32),
                      const SizedBox(height: 12),
                      Text(
                        "Version 8.2.0",
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).grey500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Created with Safety",
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String iconAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: appColor(context).transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                Image.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  color: appColor(context).secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: fontStyle.clashDisplayMedium14.textColor(
                      appColor(context).black,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: appColor(context).secondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders highly stylized Logout Confirmation Drawer mimicking your mockup asset
  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ready to log out",
                    style: fontStyle.clashDisplaySemiBold18.textColor(
                      appColor(context).black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: appColor(context).black,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "People will still be able to see your profile",
                style: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).grey600,
                ),
              ),
              const SizedBox(height: 32),

              // Highlighted Pink Stadium Button Anchor
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: appColor(context).secondary,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          color: appColor(context).secondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Log Out",
                          style: fontStyle.clashDisplaySemiBold16.textColor(
                            appColor(context).secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    "Not Now",
                    style: fontStyle.clashDisplayBold14.textColor(
                      appColor(context).black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Renders highly stylized Delete Confirmation Drawer mimicking your mockup asset
  void _showDeleteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ready to Delete",
                    style: fontStyle.clashDisplaySemiBold18.textColor(
                      appColor(context).black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: appColor(context).black,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "People won’t be able to see your profile",
                style: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).grey600,
                ),
              ),
              const SizedBox(height: 32),

              // Bold Black Border Action Stadium Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: appColor(context).black,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: appColor(context).black,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Delete Account",
                          style: fontStyle.clashDisplaySemiBold16.textColor(
                            appColor(context).black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    "Not Now",
                    style: fontStyle.clashDisplayBold14.textColor(
                      appColor(context).black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Manages interactive Radio states in a modal dialog to Select Application Theme
  void _showThemeBottomSheet(BuildContext context) {
    String selectedTheme = "App Default";

    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Widget buildThemeRadio(String value) {
              final bool isSelected = selectedTheme == value;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    selectedTheme = value;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? appColor(context).secondary
                                : appColor(context).grey300,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isSelected
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: appColor(context).secondary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        value,
                        style: fontStyle.clashDisplayMedium14.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Theme",
                        style: fontStyle.clashDisplaySemiBold18.textColor(
                          appColor(context).black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: appColor(context).black,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildThemeRadio("App Default"),
                  buildThemeRadio("Light"),
                  buildThemeRadio("Dark"),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            "Cancel",
                            style: fontStyle.clashDisplaySemiBold14.textColor(
                              appColor(context).black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            "OK",
                            style: fontStyle.clashDisplaySemiBold14.textColor(
                              appColor(context).secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
