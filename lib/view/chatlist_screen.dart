import 'package:flutter/material.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
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
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:shieldconnect_app/services/call_manager.dart';

class ChatlistScreen extends StatelessWidget {
  const ChatlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<CallManager>().fetchActiveGroupCalls();
      }
    });

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
                                  ).then((_) {
                                    if (context.mounted) {
                                      homeController.init();
                                    }
                                  });
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
                                                      99
                                                  ? '99+'
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
                              context.read<AddNewChatController>().init();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddNewChatScreen(),
                                ),
                              ).then((_) {
                                if (context.mounted) {
                                  homeController.init();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Page Title Row / Search Bar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Chats",
                        style: fontStyle.clashDisplayBold30.textColor(
                          appColor(context).black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: homeController.isSearching
                              ? Container(
                                  key: const ValueKey('search_active'),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: appColor(context).grey100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: homeController.searchController,
                                    focusNode: homeController.searchFocusNode,
                                    onChanged: (value) {
                                      homeController.setSearchQuery(value);
                                    },
                                    cursorColor: appColor(context).primary,
                                    style: fontStyle.clashDisplayMedium14
                                        .textColor(appColor(context).black),
                                    decoration: InputDecoration(
                                      hintText: "Search...",
                                      hintStyle: fontStyle.clashDisplayMedium14
                                          .textColor(appColor(context).grey400),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(11.0),
                                        child: Image.asset(
                                          ImageAssets.searchIcon,
                                          width: 18,
                                          height: 18,
                                          color: appColor(context).secondary,
                                        ),
                                      ),
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          if (homeController
                                              .searchController
                                              .text
                                              .isNotEmpty) {
                                            homeController.searchController
                                                .clear();
                                            homeController.setSearchQuery("");
                                          } else {
                                            homeController.setSearching(false);
                                          }
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: appColor(context).primary,
                                          size: 20,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                )
                              : Align(
                                  key: const ValueKey('search_inactive'),
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      homeController.setSearching(true);
                                      homeController.searchFocusNode
                                          .requestFocus();
                                    },
                                    child: Image.asset(
                                      ImageAssets.searchIcon,
                                      width: 18,
                                      height: 18,
                                      color: appColor(context).secondary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
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
                          text: homeController.totalUnreadCount > 0
                              ? "All (${homeController.totalUnreadCount})"
                              : "All",
                          isActive: homeController.activeTab == 'All',
                          onTap: () => homeController.setActiveTab('All'),
                        ),
                        _buildFilterTag(
                          context,
                          text: homeController.totalUnreadCount > 0
                              ? "Unread (${homeController.totalUnreadCount})"
                              : "Unread",
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

                  // Active ongoing group call banner(s)
                  Consumer<CallManager>(
                    builder: (context, callManager, child) {
                      final activeCalls = callManager.activeGroupCalls;
                      if (activeCalls.isEmpty) return const SizedBox.shrink();

                      // Filter out calls that the user is currently actively in
                      final joinableCalls = activeCalls.entries.where((entry) {
                        final call = entry.value;
                        final callId = (call['_id'] ?? call['id'])?.toString();
                        return callManager.state == CallState.idle || callManager.currentCallId != callId;
                      }).toList();

                      if (joinableCalls.isEmpty) return const SizedBox.shrink();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: joinableCalls.map((entry) {
                          final call = entry.value;
                          final groupId = entry.key;
                          final groupName = call['group_name'] ?? call['group_id']?['name'] ?? 'Group Call';
                          final groupImage = call['group_avatar'] ?? call['group_id']?['group_image'] ?? call['group_id']?['avatar'];
                          final isVideo = call['call_type'] == 'video';
                          final roomId = (call['_id'] ?? call['id'] ?? call['roomId'])?.toString() ?? '';
                          final String? callerId = (call['initiator_id'] is Map
                              ? (call['initiator_id']['_id'] ?? call['initiator_id']['id'])?.toString()
                              : call['initiator_id']?.toString()) ?? call['callerId']?.toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E), // Premium dark theme
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF25D366),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "$groupName - Live Call",
                                        style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isVideo ? "Tap Join Now to join the video call" : "Tap Join Now to join the voice call",
                                        style: fontStyle.clashDisplayRegular12.textColor(Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    callManager.joinCall(
                                      roomId,
                                      isVideo,
                                      groupId: groupId,
                                      groupName: groupName,
                                      groupAvatar: groupImage,
                                      callerId: callerId,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Join Now",
                                    style: fontStyle.clashDisplayBold12.textColor(Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

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

                              if (chats.isEmpty) {
                                if (hasAnnouncement) {
                                  return ListView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _buildAnnouncementCard(
                                        context,
                                        announcements,
                                      ),
                                      _buildEmptyState(
                                        context,
                                        homeController.activeTab,
                                        isEmbedded: true,
                                      ),
                                    ],
                                  );
                                } else {
                                  return _buildEmptyState(
                                    context,
                                    homeController.activeTab,
                                    isEmbedded: false,
                                  );
                                }
                              }

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
    final homeController = Provider.of<HomeScreenController>(
      context,
      listen: false,
    );
    final conversation = item['conversation'] ?? {};
    final lastMessage = item['last_message'] ?? {};
    final String chatId = (conversation['id'] ?? conversation['_id'] ?? '')
        .toString();
    final bool isGroup = conversation['type'] == 'group';
    final bool showTypingIndicator = conversation['show_typing_indicator'] as bool? ?? true;
    final String? typingIndicatorText = (!isGroup && !showTypingIndicator)
        ? null
        : homeController.getTypingIndicatorText(
            chatId,
          );

    final bool isRequest =
        item['relationship']?['status'] == 'pending' &&
        item['requested_by'] != null;
    final String name = conversation['name'] ?? 'Unknown';
    final String messageContentRaw = lastMessage['content'] ?? 'No messages yet';
    String messageContent = messageContentRaw;
    if (isGroup) {
      final String msgLower = messageContentRaw.toLowerCase();
      if (msgLower.contains("created") ||
          msgLower.contains("system_group_created")) {
        messageContent = 'Group "$name" created';
      } else if (messageContentRaw.startsWith("system_member_added:")) {
        final parts = messageContentRaw.split(':');
        final memberName = parts.length >= 3
            ? parts[2]
            : (parts.length == 2
                ? parts[1]
                : "A member");
        messageContent = "$memberName added to group";
      } else if (messageContentRaw.startsWith("system_member_removed:")) {
        final parts = messageContentRaw.split(':');
        final memberName = parts.length >= 3
            ? parts[2]
            : (parts.length == 2
                ? parts[1]
                : "A member");
        messageContent = "$memberName removed from group";
      } else if (messageContentRaw.startsWith("system_member_joined:")) {
        final parts = messageContentRaw.split(':');
        final memberName = parts.length >= 3
            ? parts[2]
            : (parts.length == 2
                ? parts[1]
                : "A member");
        messageContent = "$memberName joined the group";
      } else if (messageContentRaw.startsWith("system_member_left:")) {
        final parts = messageContentRaw.split(':');
        final memberId = parts.length >= 2 ? parts[1] : '';
        if (memberId == (homeController.userId ?? '')) {
          messageContent = "You left the group";
        } else {
          final memberName = parts.length >= 3
              ? parts[2]
              : (parts.length == 2
                  ? parts[1]
                  : "A member");
          messageContent = "$memberName left the group";
        }
      }
    }
    final String time = lastMessage['created_at'] != null
        ? DateHelper.formatTime(lastMessage['created_at'])
        : '';
    final int unread = item['unread_count'] ?? 0;

    final String rawType =
        (lastMessage['message_type'] ?? lastMessage['type'] ?? '')
            .toString()
            .toLowerCase();
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
    } else if (rawType == 'sticker') {
      mediaIcon = Icons.sticky_note_2_outlined;
      mediaText = 'sticker';
    }

    final bool hasRing = false;
    final bool showLastSeen = conversation['show_last_seen'] as bool? ?? true;
    final bool hasStatusDot = (!isGroup && !showLastSeen)
        ? false
        : (conversation['is_online'] ?? false);
    final String? senderId =
        lastMessage['sender_id']?.toString() ??
        lastMessage['sender']?.toString();
    final bool isOutgoing =
        senderId != null && senderId == homeController.userId;
    final String msgStatus = lastMessage['status'] ?? 'none';
    final bool isSystemMessage = rawType == 'system' ||
        rawType == 'status' ||
        messageContentRaw.startsWith("system_member_") ||
        messageContentRaw.contains("system_group_created");
    final bool showProfilePic = conversation['show_profile_pic'] as bool? ?? true;
    final String? imagePath = (!isGroup && !showProfilePic)
        ? null
        : conversation['image'];

    bool showNewGroupBadge = false;
    if (isGroup &&
        (messageContent == 'No messages yet' || messageContent == 'Group "$name" created') &&
        lastMessage['created_at'] != null) {
      try {
        final DateTime createdAt = DateTime.parse(lastMessage['created_at'].toString()).toUtc();
        final DateTime now = DateTime.now().toUtc();
        final Duration difference = now.difference(createdAt);
        if (difference.inHours >= 0 && difference.inHours < 10) {
          showNewGroupBadge = true;
        }
      } catch (_) {}
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final String chatId = (conversation['id'] ?? conversation['_id'] ?? '')
            .toString();
        if (chatId.isNotEmpty) {
          homeController.markChatAsReadLocally(chatId);

          final String currentUserId = homeController.userId ?? '';
          if (currentUserId.isNotEmpty) {
            SocketService().markAsRead(
              chatId: chatId,
              userId: currentUserId,
              otherId: isGroup ? '' : chatId,
              isGroup: isGroup,
            );
          }
        }

        if (isGroup) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupName: name,
                groupId: conversation['id'] ?? conversation['_id'],
                isFavorite:
                    item['is_favorite'] ??
                    item['isFavorite'] ??
                    conversation['is_favorite'] ??
                    conversation['isFavorite'] ??
                    false,
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              homeController.setSearching(false);
              homeController.init();
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userName: name,
                isGroup: isGroup,
                isRequest: isRequest,
                recipientId: conversation['id'] ?? conversation['_id'],
                isFavorite:
                    item['is_favorite'] ??
                    item['isFavorite'] ??
                    conversation['is_favorite'] ??
                    conversation['isFavorite'] ??
                    false,
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              homeController.setSearching(false);
              homeController.init();
            }
          });
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
                          if (!isGroup)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: hasStatusDot
                                      ? appColor(context).green
                                      : appColor(context).grey,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: fontStyle.clashDisplaySemiBold16.textColor(
                            appColor(context).black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showNewGroupBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: appColor(context).secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: appColor(context).secondary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "NEW GROUP",
                            style: fontStyle.clashDisplayBold10.textColor(
                              appColor(context).secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (typingIndicatorText == null && isOutgoing && !isSystemMessage && msgStatus != 'none' && msgStatus.isNotEmpty) ...[
                        _buildListReadReceipt(context, msgStatus),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: typingIndicatorText != null
                            ? Text(
                                typingIndicatorText,
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  appColor(context).secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : (mediaIcon != null && mediaText != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          mediaIcon,
                                          color: appColor(
                                            context,
                                          ).textMediumGrey,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          mediaText,
                                          style: fontStyle.clashDisplayRegular12
                                              .textColor(
                                                appColor(
                                                  context,
                                                ).textMediumGrey,
                                              ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      messageContent,
                                      style: fontStyle.clashDisplayRegular12
                                          .textColor(
                                            appColor(context).textMediumGrey,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
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
        ).then((_) {
          if (context.mounted) {
            Provider.of<HomeScreenController>(context, listen: false).init();
          }
        });
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
                    "RoseShield",
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

  Widget _buildEmptyState(
    BuildContext context,
    String tab, {
    bool isEmbedded = false,
  }) {
    IconData iconData;
    String title;
    String subtitle;

    switch (tab) {
      case 'Unread':
        iconData = Icons.mark_chat_unread_outlined;
        title = "All Caught Up";
        subtitle =
            "You have no unread messages. Any new messages will appear here.";
        break;
      case 'Requests':
        iconData = Icons.question_answer_outlined;
        title = "No Requests";
        subtitle =
            "You have no pending message requests from non-connected users.";
        break;
      case 'Groups':
        iconData = Icons.groups_outlined;
        title = "No Groups Yet";
        subtitle =
            "Create a group or ask someone to add you to their group to get started.";
        break;
      case 'Favourite':
        iconData = Icons.star_border_rounded;
        title = "No Favourites";
        subtitle =
            "Mark important chats as favourites to find them easily at the top.";
        break;
      case 'All':
      default:
        iconData = Icons.chat_bubble_outline_rounded;
        title = "No Chats Yet";
        subtitle =
            "Start a new conversation by tapping the '+' button in the top right corner.";
        break;
    }

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isEmbedded ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!isEmbedded) const Spacer(flex: 2),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: appColor(context).secondary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: appColor(context).secondary, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: fontStyle.clashDisplaySemiBold18.textColor(
            appColor(context).black,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayRegular14.textColor(
              appColor(context).grey400,
            ),
          ),
        ),
        if (!isEmbedded) const Spacer(flex: 3),
      ],
    );

    if (isEmbedded) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
        child: content,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: content,
      ),
    );
  }

  Widget _buildListReadReceipt(BuildContext context, String status) {
    if (status == 'read') {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: appColor(context).green,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.done_all_rounded,
            color: Colors.white,
            size: 10,
          ),
        ),
      );
    } else if (status == 'delivered') {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: appColor(context).green,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.done_all_rounded,
            color: appColor(context).green,
            size: 10,
          ),
        ),
      );
    } else {
      return Icon(
        Icons.check_circle_outline,
        color: appColor(context).green,
        size: 16,
      );
    }
  }
}
