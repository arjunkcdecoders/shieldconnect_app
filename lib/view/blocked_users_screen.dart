import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  // Mock list of blocked users
  final List<Map<String, String>> _blockedUsers = [
    {"name": "Alex Thompson", "image": ImageAssets.obchild1},
    {"name": "Sarah Jenkins", "image": ImageAssets.obchild2},
    {"name": "Michael Chen", "image": ImageAssets.obchild3},
  ];

  void _unblockUser(int index) {
    setState(() {
      _blockedUsers.removeAt(index);
    });
    // Show a premium toast
    ToastHelper.showToast(context, "User unblocked successfully");
  }

  @override
  Widget build(BuildContext context) {
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
              child: _blockedUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        return _buildBlockedUserCard(index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aesthetic card for each blocked user
  Widget _buildBlockedUserCard(int index) {
    final user = _blockedUsers[index];
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
                image: AssetImage(user['image']!),
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
          GestureDetector(
            onTap: () => _unblockUser(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: appColor(context).secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
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
        ],
      ),
    );
  }

  /// Centered state for when no users are blocked
  Widget _buildEmptyState() {
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
