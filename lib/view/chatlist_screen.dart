import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

import 'package:shieldconnect_app/view/add_new_chat_screen.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:shieldconnect_app/view/chat_screen.dart';
import 'package:shieldconnect_app/view/group_chat_screen.dart';
import 'package:shieldconnect_app/view/announcement_details_screen.dart';

class ChatlistScreen extends StatelessWidget {
  const ChatlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chatItems = [
      {
        "name": "Family",
        "message": "Hello everyone!",
        "time": "11:00 AM",
        "status": "read_empty",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": true,
        "isGroup": true,
      },
      {
        "name": "Maisie williams",
        "message": "Hii..Are You There?",
        "time": "11:00 AM",
        "status": "read_filled",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": false,
      },
      {
        "name": "Maisie williams",
        "message": "Hii..Are You There?",
        "time": "11:00 AM",
        "status": "read_filled",
        "unread": 0,
        "hasRing": true,
        "hasStatusDot": false,
      },
      {
        "name": "Maisie williams",
        "message": "Hii..Are You There?",
        "time": "11:00 AM",
        "status": "none",
        "unread": 1,
        "hasRing": false,
        "hasStatusDot": true,
      },
      {
        "name": "Maisie williams",
        "message": "Hii..Are You There?",
        "time": "11:00 AM",
        "status": "read_empty",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": true,
      },
      {
        "name": "Maisie williams",
        "message": "Hii..Are You There?",
        "time": "11:00 AM",
        "status": "read_empty",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": true,
      },
      {
        "name": "Bruce Wayne",
        "message": "Hey! 😊",
        "time": "10:00 AM",
        "status": "none",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": false,
        "isRequest": true,
      },
    ];

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile avatar stack
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage(ImageAssets.userAvatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: -4,
                        child: Image.asset(
                          ImageAssets.tick,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ],
                  ),
                  // Actions (Notification bell, Plus)
                  Row(
                    children: [
                      _buildHeaderAction(
                        context,
                        assetPath: ImageAssets.notification,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderAction(
                        context,
                        assetPath: ImageAssets.plus,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNewChatScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Page Title
              Text(
                "Chats",
                style: fontStyle.clashDisplayBold30.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 20),

              // Scrollable filter tags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterTag(context, text: "All", isActive: true),
                    _buildFilterTag(context, text: "Unread", isActive: false),
                    _buildFilterTag(context, text: "Requests", isActive: false),
                    _buildFilterTag(context, text: "Group", isActive: false),
                    _buildFilterTag(
                      context,
                      text: "Favourites",
                      isActive: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Chat list
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: chatItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAnnouncementCard(context);
                    }
                    return _buildChatItem(context, chatItems[index - 1]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    required String assetPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: appColor(context).silver.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 22,
            height: 22,
            color: appColor(context).secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTag(
    BuildContext context, {
    required String text,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? appColor(context).secondary : appColor(context).grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: fontStyle.clashDisplayMedium12.textColor(
          isActive ? appColor(context).white : appColor(context).grey400,
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    final bool hasRing = chat["hasRing"] ?? false;
    final bool hasStatusDot = chat["hasStatusDot"] ?? false;
    final String status = chat["status"] ?? "none";
    final int unread = chat["unread"] ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (chat["isGroup"] ?? false) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupName: chat["name"],
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userName: chat["name"],
                isGroup: chat["isGroup"] ?? false,
                isRequest: chat["isRequest"] ?? false,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22.0),
        child: Row(
          children: [
            // Avatar logic
            SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: hasRing
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appColor(context).secondary,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: (chat["isGroup"] ?? false)
                              ? const NetworkImage(
                                  "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                                ) as ImageProvider
                              : const AssetImage(ImageAssets.maisieAvatar),
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: (chat["isGroup"] ?? false)
                                ? const NetworkImage(
                                    "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                                  ) as ImageProvider
                                : const AssetImage(ImageAssets.maisieAvatar),
                          ),
                          if (hasStatusDot)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: appColor(context).secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: appColor(context).white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Mid Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chat["name"],
                    style: fontStyle.clashDisplaySemiBold16.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (status == "read_empty") ...[
                        Icon(
                          Icons.check_circle_outline,
                          color: appColor(context).green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ] else if (status == "read_filled") ...[
                        Icon(
                          Icons.check_circle,
                          color: appColor(context).green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          chat["message"],
                          style: fontStyle.clashDisplayRegular12.textColor(
                            appColor(context).grey400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right side (time & unread count)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat["time"],
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).grey300,
                  ),
                ),
                const SizedBox(height: 6),
                unread > 0
                    ? Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: appColor(context).secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread.toString(),
                            style: fontStyle.clashDisplaySemiBold12
                                .textColor(appColor(context).white)
                                .copyWith(fontSize: 10),
                          ),
                        ),
                      )
                    : const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnnouncementDetailsScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22.0),
        child: Row(
          children: [
            // Icon as Avatar
            SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: appColor(context).secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      ImageAssets.appIcon,
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Mid Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Announcements",
                    style: fontStyle.clashDisplaySemiBold16.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Maintenance update at 12:00 PM today...",
                    style: fontStyle.clashDisplayRegular12.textColor(
                      appColor(context).grey400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "11:00 AM",
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).grey300,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: appColor(context).secondary,
                    shape: BoxShape.circle,
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
