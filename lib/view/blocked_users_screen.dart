import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/account_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountController>(context, listen: false).fetchBlockedUsers();
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Navigation Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
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
                    "Blocked Users",
                    style: fontStyle.clashDisplaySemiBold20.textColor(
                      appColor(context).black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Blocked Users List
            Expanded(
              child: Consumer<AccountController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: appColor(context).secondary,
                      ),
                    );
                  }

                  if (controller.blockedUsers.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: controller.blockedUsers.length,
                    itemBuilder: (context, index) {
                      return _buildBlockedUserCard(context, controller, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aesthetic card for each blocked user
  Widget _buildBlockedUserCard(BuildContext context, AccountController controller, int index) {
    final user = controller.blockedUsers[index];
    final String avatarUrl = ApiService.getImageUrl(user['image']);
    final ImageProvider imageProvider = avatarUrl.isNotEmpty
        ? NetworkImage(avatarUrl)
        : const AssetImage(ImageAssets.userAvatar) as ImageProvider;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              user['name']!,
              style: fontStyle.clashDisplaySemiBold16.textColor(
                appColor(context).black,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: controller.unblockingUserId != null
                    ? null
                    : () => controller.unblockUser(user['id']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: appColor(context).secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: controller.unblockingUserId == user['id']
                      ? SizedBox(
                          width: 50,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: appColor(context).secondary,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_open_rounded,
                              color: appColor(context).secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Unblock",
                              style: fontStyle.clashDisplaySemiBold12.textColor(
                                appColor(context).secondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (controller.unblockErrors.containsKey(user['id'])) ...[
                const SizedBox(height: 4),
                Text(
                  controller.unblockErrors[user['id']]!,
                  style: fontStyle.clashDisplayRegular10.textColor(
                    const Color(0xFFB71C44),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Centered state for when no users are blocked
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appColor(context).grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: appColor(context).grey400,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Blocked Users",
            style: fontStyle.clashDisplaySemiBold18.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Users you block will appear here",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey600,
            ),
          ),
        ],
      ),
    );
  }
}
