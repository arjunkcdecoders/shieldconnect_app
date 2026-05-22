import 'package:flutter/material.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

import 'package:shieldconnect_app/view/add_new_chat_screen.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:shieldconnect_app/view/chat_screen.dart';
import 'package:shieldconnect_app/view/group_chat_screen.dart';
import 'package:shieldconnect_app/view/announcement_details_screen.dart';

import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';

class ChatlistScreen extends StatelessWidget {
  const ChatlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Consumer<HomeScreenController>(
            builder: (context, homeController, child) {
              return Column(
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
                              borderRadius: BorderRadius.circular(9.33),
                              color: appColor(context).grey100,
                              image:
                                  ApiService.getImageUrl(
                                    homeController.profileImage,
                                  ).isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        ApiService.getImageUrl(
                                          homeController.profileImage,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                ApiService.getImageUrl(
                                  homeController.profileImage,
                                ).isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: appColor(context).grey400,
                                    size: 24,
                                  )
                                : null,
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
                                              notificationController
                                                          .unreadCount >
                                                      9
                                                  ? '9+'
                                                  : notificationController
                                                        .unreadCount
                                                        .toString(),
                                              style: fontStyle
                                                  .clashDisplayBold10
                                                  .textColor(
                                                    appColor(context).white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
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
                                  builder: (context) =>
                                      const AddNewChatScreen(),
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
                        _buildFilterTag(
                          context,
                          text: "All",
                          isActive: homeController.activeTab == 'All',
                          onTap: () => homeController.setActiveTab('All'),
                        ),
                        _buildFilterTag(
                          context,
                          text: "Unread",
                          isActive: homeController.activeTab == 'Unread',
                          onTap: () => homeController.setActiveTab('Unread'),
                        ),
                        _buildFilterTag(
                          context,
                          text: homeController.requestCount > 0
                              ? "Requests (${homeController.requestCount})"
                              : "Requests",
                          isActive: homeController.activeTab == 'Requests',
                          onTap: () => homeController.setActiveTab('Requests'),
                        ),
                        _buildFilterTag(
                          context,
                          text: "Group",
                          isActive: homeController.activeTab == 'Groups',
                          onTap: () => homeController.setActiveTab('Groups'),
                        ),
                        _buildFilterTag(
                          context,
                          text: "Favourites",
                          isActive: homeController.activeTab == 'Favourite',
                          onTap: () => homeController.setActiveTab('Favourite'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Chat list
                  Expanded(
                    child: homeController.isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: appColor(context).primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Syncing chats...",
                                  style: fontStyle.clashDisplayMedium12
                                      .textColor(appColor(context).grey400),
                                ),
                              ],
                            ),
                          )
                        : Consumer<AnnouncementController>(
                            builder: (context, announcementController, child) {
                              final announcements =
                                  announcementController.announcements;
                              final hasAnnouncement =
                                  announcements.isNotEmpty &&
                                  homeController.activeTab == 'All';
                              final chats = homeController.recentChats;

                              return ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount:
                                    chats.length + (hasAnnouncement ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (hasAnnouncement && index == 0) {
                                    return _buildAnnouncementCard(
                                      context,
                                      announcements,
                                    );
                                  }
                                  final chatIndex = hasAnnouncement
                                      ? index - 1
                                      : index;
                                  return _buildChatItem(
                                    context,
                                    chats[chatIndex] as Map<String, dynamic>,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? appColor(context).secondary
              : appColor(context).grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: fontStyle.clashDisplayMedium12.textColor(
            isActive ? appColor(context).white : appColor(context).grey400,
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> item) {
    final conversation = item['conversation'] ?? {};
    final lastMessage = item['last_message'] ?? {};

    final bool isGroup = conversation['type'] == 'group';
    final bool isRequest =
        item['relationship']?['status'] == 'pending' &&
        item['requested_by'] != null;
    final String name = conversation['name'] ?? 'Unknown';
    final String messageContent = lastMessage['content'] ?? 'No messages yet';
    final String time = lastMessage['created_at'] != null
        ? DateHelper.formatTime(lastMessage['created_at'])
        : '';
    final int unread = item['unread_count'] ?? 0;

    final String rawType = (lastMessage['message_type'] ?? lastMessage['type'] ?? '').toString().toLowerCase();
    IconData? mediaIcon;
    String? mediaText;
    if (rawType == 'image') {
      mediaIcon = Icons.image_outlined;
      mediaText = 'image';
    } else if (rawType == 'video') {
      mediaIcon = Icons.videocam_outlined;
      mediaText = 'video';
    } else if (rawType == 'audio' || rawType == 'voice') {
      mediaIcon = Icons.mic_none_outlined;
      mediaText = 'audio';
    } else if (rawType == 'file' || rawType == 'doc' || rawType == 'document') {
      mediaIcon = Icons.insert_drive_file_outlined;
      mediaText = 'file';
    }

    final bool hasRing = false;
    final bool hasStatusDot = conversation['is_online'] ?? false;
    final String msgStatus = lastMessage['status'] ?? 'none';
    final String status = msgStatus == 'read'
        ? 'read_filled'
        : (msgStatus == 'sent' ? 'read_empty' : 'none');
    final String? imagePath = conversation['image'];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isGroup) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupName: name,
                groupId: conversation['id'] ?? conversation['_id'],
                isFavorite: item['is_favorite'] ?? item['isFavorite'] ?? conversation['is_favorite'] ?? conversation['isFavorite'] ?? false,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userName: name,
                isGroup: isGroup,
                isRequest: isRequest,
                recipientId: conversation['id'] ?? conversation['_id'],
                isFavorite: item['is_favorite'] ?? item['isFavorite'] ?? conversation['is_favorite'] ?? conversation['isFavorite'] ?? false,
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
                          backgroundColor: appColor(context).grey100,
                          backgroundImage:
                              imagePath != null &&
                                  ApiService.getImageUrl(imagePath).isNotEmpty
                              ? NetworkImage(ApiService.getImageUrl(imagePath))
                              : null,
                          child:
                              imagePath == null ||
                                  ApiService.getImageUrl(imagePath).isEmpty
                              ? Icon(
                                  isGroup ? Icons.group : Icons.person,
                                  color: appColor(context).grey400,
                                  size: 24,
                                )
                              : null,
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: appColor(context).grey100,
                            backgroundImage:
                                imagePath != null &&
                                    ApiService.getImageUrl(imagePath).isNotEmpty
                                ? NetworkImage(
                                    ApiService.getImageUrl(imagePath),
                                  )
                                : null,
                            child:
                                imagePath == null ||
                                    ApiService.getImageUrl(imagePath).isEmpty
                                ? Icon(
                                    isGroup ? Icons.group : Icons.person,
                                    color: appColor(context).grey400,
                                    size: 28,
                                  )
                                : null,
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
                    name,
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
                        child: mediaIcon != null && mediaText != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    mediaIcon,
                                    color: appColor(context).textMediumGrey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mediaText,
                                    style: fontStyle.clashDisplayRegular12.textColor(
                                      appColor(context).textMediumGrey,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                messageContent,
                                style: fontStyle.clashDisplayRegular12.textColor(
                                  appColor(context).textMediumGrey,
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
                  time,
                  style: fontStyle.clashDisplayMedium10.textColor(
                    appColor(context).grey400,
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

  Widget _buildAnnouncementCard(
    BuildContext context,
    List<dynamic> announcements,
  ) {
    if (announcements.isEmpty) return const SizedBox.shrink();
    final announcement = announcements[0];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AnnouncementDetailsScreen(announcements: announcements),
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

            // Mid Content - Title Only
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
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right side - Time display
            Text(
              DateHelper.formatTime(
                announcement["createdAt"] ?? announcement["time"],
              ),
              style: fontStyle.clashDisplayMedium10.textColor(
                appColor(context).grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
