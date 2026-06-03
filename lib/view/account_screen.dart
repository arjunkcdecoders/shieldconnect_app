import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/account_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/view/change_password_screen.dart';
import 'package:shieldconnect_app/view/chat_settings_screen.dart';
import 'package:shieldconnect_app/view/blocked_users_screen.dart';
import 'package:shieldconnect_app/view/delete_account_dialog.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/change_password_controller.dart';

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
                  iconAsset: ImageAssets.chatSettings,
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
                    context.read<ChangePasswordController>().clearAll();
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
                  onTap: () {
                    context.read<ProfileController>().resetDeleteAccountState();
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => const DeleteAccountDialog(),
                    );
                  },
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

  /// Renders a beautiful grid of active wallpapers for chat customization
  void _showWallpaperBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
        return const WallpaperBottomSheetContent();
      },
    );
  }
}

class WallpaperBottomSheetContent extends StatefulWidget {
  const WallpaperBottomSheetContent({super.key});

  @override
  State<WallpaperBottomSheetContent> createState() =>
      _WallpaperBottomSheetContentState();
}

class _WallpaperBottomSheetContentState
    extends State<WallpaperBottomSheetContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AccountController>(context, listen: false);
      controller.init();
      controller.fetchWallpapers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountController>(
      builder: (context, controller, child) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appColor(context).white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.50,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (controller.wallpapers.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: Text(
                                "No wallpapers available",
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  appColor(context).grey600,
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: controller.wallpapers.length,
                            itemBuilder: (context, index) {
                              final wallpaper = controller.wallpapers[index];
                              final isSelected =
                                  controller.selectedWallpaperId ==
                                  wallpaper.id;
                              final isSelecting =
                                  controller.selectingWallpaperId ==
                                  wallpaper.id;
                              final isFailed =
                                  controller.failedWallpaperId ==
                                  wallpaper.id;
                              final imageUrl = ApiService.getImageUrl(
                                wallpaper.wallpaperImage,
                              );

                              return GestureDetector(
                                onTap: () {
                                  if (wallpaper.id != null && !isSelecting) {
                                    controller.selectWallpaper(
                                      context,
                                      wallpaper.id!,
                                    ).then((success) {
                                      if (success && context.mounted) {
                                        Future.delayed(const Duration(milliseconds: 600), () {
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        });
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected
                                        ? Border.all(
                                            color: appColor(context).secondary,
                                            width: 3.0,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: appColor(
                                          context,
                                        ).black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    image: imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      if (isSelecting)
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (isFailed)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            margin: const EdgeInsets.all(8),
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.error,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        )
                                      else if (isSelected)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            margin: const EdgeInsets.all(8),
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: appColor(
                                                context,
                                              ).secondary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
