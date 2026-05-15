import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/change_password_screen.dart';
import 'package:shieldconnect_app/view/chat_settings_screen.dart';
import 'package:shieldconnect_app/view/blocked_users_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

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
                // 1. Custom Navigation Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appColor(context).grey100,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chevron_left,
                            color: appColor(context).secondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Account",
                      style: fontStyle.clashDisplaySemiBold20.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // 2. Visual Options Stack
                _buildOptionCard(
                  context,
                  iconAsset: ImageAssets.key,
                  title: "Privacy",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockedUsersScreen(),
                      ),
                    );
                  },
                ),
                _buildOptionCard(
                  context,
                  iconAsset: ImageAssets.gallery,
                  title: "Change Chat Wallpaper",
                  onTap: () => _showWallpaperBottomSheet(context),
                ),
                _buildOptionCard(
                  context,
                  iconAsset: ImageAssets.settingsInActive,
                  title: "Chat Settings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildOptionCard(
                  context,
                  iconAsset: ImageAssets.password,
                  title: "Change Password",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                _buildOptionCard(
                  context,
                  iconAsset: ImageAssets.deleteChat,
                  title: "Delete Account",
                  onTap: () => _showDeleteBottomSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Aesthetic container representing highly-rounded configuration options matching your mockup
  Widget _buildOptionCard(
    BuildContext context, {
    required String iconAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(
          32,
        ), // High-stadium rounding matching Image 1
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: appColor(context).transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 18.0,
            ),
            child: Row(
              children: [
                Image.asset(
                  iconAsset,
                  width: 22,
                  height: 22,
                  color: appColor(
                    context,
                  ).secondary, // Renders icons in beautiful secondary pink
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
                  color: appColor(
                    context,
                  ).secondary, // Matches right navigation prompt color
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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

  /// Renders a beautiful grid of mock wallpapers for chat customization
  void _showWallpaperBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chat Wallpapers",
                    style: fontStyle.clashDisplaySemiBold20.textColor(
                      appColor(context).black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appColor(context).grey100,
                      ),
                      child: Icon(
                        Icons.close,
                        color: appColor(context).black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  // Premium Unsplash Mock Wallpapers
                  final List<String> wallPaths = [
                    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80",
                    "https://images.unsplash.com/photo-1633613286991-611fe299c4be?auto=format&fit=crop&w=400&q=80",
                    "https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?auto=format&fit=crop&w=400&q=80",
                    "https://images.unsplash.com/photo-1635776062127-d379bfcba9f8?auto=format&fit=crop&w=400&q=80",
                    "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=400&q=80",
                    "https://images.unsplash.com/photo-1557683316-973673baf926?auto=format&fit=crop&w=400&q=80",
                  ];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: appColor(
                              context,
                            ).black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(wallPaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
