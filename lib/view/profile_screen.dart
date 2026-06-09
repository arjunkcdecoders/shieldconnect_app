import 'package:flutter/material.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/view/delete_account_dialog.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/view/moderator/bottomnav_screen/bottomnav_screen.dart'
    as mod;
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/view/bottomnav_screen.dart' as user_nav;
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:shieldconnect_app/view/edit_profile_screen.dart';
import 'package:shieldconnect_app/view/account_screen.dart';
import 'package:shieldconnect_app/view/archived_chats_screen.dart';
import 'package:shieldconnect_app/view/help_support_screen.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().fetchUserDetails();
    });
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
                    Expanded(
                      child: Text(
                        "Profile",
                        style: fontStyle.clashDisplaySemiBold20.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ),
                    Consumer<NotificationController>(
                      builder: (context, notificationController, child) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
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
                              if (notificationController.unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: appColor(context).secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: appColor(context).white,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        notificationController.unreadCount > 9
                                            ? '9+'
                                            : notificationController.unreadCount
                                                  .toString(),
                                        style: fontStyle.clashDisplayBold10
                                            .textColor(appColor(context).white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Focused User Summary Block
                Consumer<ProfileController>(
                  builder: (context, controller, child) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stylized Squircle profile image
                          GestureDetector(
                            onTap: () {
                              final String fullImageUrl =
                                  ApiService.getImageUrl(controller.imageUrl);
                              if (fullImageUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FullScreenProfilePictureScreen(
                                          imageUrl: fullImageUrl,
                                          heroTag: 'profile_avatar',
                                        ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Hero(
                                  tag: 'profile_avatar',
                                  child: Container(
                                    width: 106,
                                    height: 106,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: appColor(context).grey100,
                                      image:
                                          ApiService.getImageUrl(
                                            controller.imageUrl,
                                          ).isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                ApiService.getImageUrl(
                                                  controller.imageUrl,
                                                ),
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        ApiService.getImageUrl(
                                          controller.imageUrl,
                                        ).isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color: appColor(context).grey400,
                                            size: 48,
                                          )
                                        : null,
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
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.name.isNotEmpty
                                ? controller.name
                                : "No Name",
                            style: fontStyle.clashDisplaySemiBold16.textColor(
                              appColor(context).black,
                            ),
                          ),
                          if (controller.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              controller.bio,
                              style: fontStyle.clashDisplayMedium10.textColor(
                                appColor(context).textMediumGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (controller.appMode == 'moderator') ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) => const UserModeDialog(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: appColor(
                                    context,
                                  ).primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: appColor(context).primary,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "👤 User Mode",
                                  style: fontStyle.clashDisplaySemiBold12
                                      .textColor(appColor(context).primary),
                                ),
                              ),
                            ),
                          ] else if (controller.isModerator) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) => const ModeratorModeDialog(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: appColor(
                                    context,
                                  ).primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: appColor(context).primary,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "🛡️ Moderator Mode",
                                  style: fontStyle.clashDisplaySemiBold12
                                      .textColor(appColor(context).primary),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
                    context.read<ProfileController>().fetchArchivedChats();
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
                    onTap: () {
                      context
                          .read<ProfileController>()
                          .resetDeleteAccountState();
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => const DeleteAccountDialog(),
                      );
                    },
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
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
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
                      "Ready to log out",
                      style: fontStyle.clashDisplaySemiBold18.textColor(
                        appColor(context).black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
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
                Consumer<ProfileController>(
                  builder: (context, profileController, child) {
                    return GestureDetector(
                      onTap: profileController.isLoading
                          ? null
                          : () {
                              profileController.logout(context);
                            },
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
                          child: profileController.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: appColor(context).secondary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
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
                                      style: fontStyle.clashDisplaySemiBold16
                                          .textColor(
                                            appColor(context).secondary,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
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
        return SafeArea(
          child: StatefulBuilder(
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
          ),
        );
      },
    );
  }
}

class FullScreenProfilePictureScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenProfilePictureScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModeratorModeDialog extends StatelessWidget {
  const ModeratorModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appColor(context).white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Header Shield Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColor(context).primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.security_rounded,
                  color: appColor(context).primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              "Enter Moderator Mode?",
              style: fontStyle.clashDisplayBold18.textColor(
                appColor(context).darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              "You will be redirected to the Content Moderation Dashboard to review pending safety queues, reports, and user flagged activities.",
              style: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).grey600,
              ).copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Cancel and Enter Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: appColor(context).white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appColor(context).grey200,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Cancel",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).darkText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Enter Mode Button
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Dismiss dialog
                      await context.read<ProfileController>().setAppMode('moderator');
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const mod.BottomnavScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: appColor(context).primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Enter Mode",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserModeDialog extends StatelessWidget {
  const UserModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appColor(context).white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Header User Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColor(context).primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  color: appColor(context).primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              "Enter User Mode?",
              style: fontStyle.clashDisplayBold18.textColor(
                appColor(context).darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              "You will be redirected back to the main chat application.",
              style: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).grey600,
              ).copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Cancel and Enter Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: appColor(context).white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appColor(context).grey200,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Cancel",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).darkText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Enter Mode Button
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Dismiss dialog
                      await context.read<ProfileController>().setAppMode('user');
                      if (context.mounted) {
                        Provider.of<HomeScreenController>(context, listen: false).init();
                        Provider.of<ProfileController>(context, listen: false).init();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const user_nav.BottomnavScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: appColor(context).primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Enter Mode",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
