import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/bottomnav_screen.dart' as user;
import 'package:shieldconnect_app/controller/bottomnav_controller.dart'
    as user_nav;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: appColor(context).white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: appColor(context).transparent,
        title: Text(
          "Profile",
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).black)
              .size(20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildUserInfo(context),
            const SizedBox(height: 40),
            _buildMenuItem(context, ImageAssets.edit, "Edit Profile"),
            _buildMenuItem(context, ImageAssets.key, "Account"),
            _buildMenuItem(context, ImageAssets.theme, "Theme"),
            const SizedBox(height: 60),
            _buildLogoutButton(context),
            const SizedBox(height: 16),
            Text(
              "Delete Account",
              style: fontStyle.clashDisplaySemiBold24
                  .textColor(appColor(context).black)
                  .size(12),
            ),
            const SizedBox(height: 30),
            Image.asset(ImageAssets.appIcon, height: 24),
            const SizedBox(height: 10),
            Text(
              "Version 8.2.0",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(10),
            ),
            const SizedBox(height: 4),
            Text(
              "Created with Safety",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(10),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1887&auto=format&fit=crop",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: -5,
              child: Image.asset(
                ImageAssets.checkVerified,
                height: 24,
                width: 24,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bruce Wayne",
              style: fontStyle.clashDisplayBold30
                  .textColor(appColor(context).black)
                  .size(16),
            ),
            const SizedBox(height: 4),
            Text(
              "brucewayne@gmail.com",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(12),
            ),
            const SizedBox(height: 8),
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
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: appColor(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: appColor(context).primary,
                    width: 1,
                  ),
                ),
                child: Text(
                  "👤 User Mode",
                  style: fontStyle.clashDisplaySemiBold12.textColor(
                    appColor(context).primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String imagePath, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: appColor(context).bgGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                color: appColor(context).primary,
                height: 20,
                width: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: fontStyle.clashDisplayMedium12
                .textColor(appColor(context).black)
                .size(14),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: appColor(context).primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutBottomSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: appColor(context).primary.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: appColor(context).primary, size: 20),
            const SizedBox(width: 12),
            Text(
              "Log Out",
              style: fontStyle.clashDisplayBold30
                  .textColor(appColor(context).primary)
                  .size(16),
            ),
          ],
        ),
      ),
    );
  }

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

                // Outlined Red/Pink Stadium Button
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
                            color: appColor(context).primary,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: profileController.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: appColor(context).primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_outlined,
                                      color: appColor(context).primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Log Out",
                                      style: fontStyle.clashDisplaySemiBold16
                                          .textColor(appColor(context).primary),
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
              "Switch to User Mode?",
              style: fontStyle.clashDisplayBold18.textColor(
                appColor(context).darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              "You will be redirected back to your personal user account. You can return to moderator mode at any time.",
              style: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).grey600,
              ).copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Cancel and Switch Buttons
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

                // Switch Mode Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Dismiss dialog
                      context.read<user_nav.BottomnavController>().reset();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const user.BottomnavScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: appColor(context).primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Switch Mode",
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
