import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:shieldconnect_app/view/chat_screen.dart';
import 'package:shieldconnect_app/view/group_chat_screen.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: appColor(context).white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: appColor(context).black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Archived Chats",
          style: fontStyle.clashDisplaySemiBold18.textColor(
            appColor(context).black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<ProfileController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.archivedChats.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    appColor(context).secondary,
                  ),
                ),
              );
            }

            final archivedList = controller.archivedChats;

            if (archivedList.isEmpty) {
              return RefreshIndicator(
                color: appColor(context).secondary,
                onRefresh: () => controller.fetchArchivedChats(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.archive_outlined,
                            size: 64,
                            color: appColor(context).grey300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No archived chats",
                            style: fontStyle.clashDisplaySemiBold16.textColor(
                              appColor(context).grey400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Swipe left to unarchive or pull down to refresh",
                            style: fontStyle.clashDisplayRegular12.textColor(
                              appColor(context).grey300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: appColor(context).secondary,
              onRefresh: () => controller.fetchArchivedChats(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: archivedList.length,
                        itemBuilder: (context, index) {
                          final item = archivedList[index];
                          final Map<String, dynamic> itemMap =
                              item is Map<String, dynamic>
                              ? item
                              : Map<String, dynamic>.from(item);
                          final conversation = itemMap['conversation'] ?? {};
                          final String chatId =
                              conversation['id'] ?? conversation['_id'] ?? "";

                          return Dismissible(
                            key: Key(chatId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 22.0),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: appColor(
                                  context,
                                ).secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Unarchive",
                                    style: fontStyle.clashDisplaySemiBold14
                                        .textColor(appColor(context).secondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.unarchive_rounded,
                                    color: appColor(context).secondary,
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) =>
                                controller.handleUnarchiveChat(context, chatId),
                            child: _buildChatItem(context, controller, itemMap),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    ProfileController controller,
    Map<String, dynamic> item,
  ) {
    final conversation = item['conversation'] ?? {};
    final lastMessage = item['last_message'] ?? {};
    final String chatId = conversation['id'] ?? conversation['_id'] ?? "";

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
    }

    final bool hasRing = false;
    final bool showLastSeen = conversation['show_last_seen'] as bool? ?? true;
    final bool hasStatusDot = (!isGroup && !showLastSeen)
        ? false
        : (conversation['is_online'] ?? false);
    final String msgStatus = lastMessage['status'] ?? 'none';
    final String status = msgStatus == 'read'
        ? 'read_filled'
        : (msgStatus == 'sent' ? 'read_empty' : 'none');
    final bool showProfilePic = conversation['show_profile_pic'] as bool? ?? true;
    final String? imagePath = (!isGroup && !showProfilePic)
        ? null
        : conversation['image'];

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
                isArchived: true,
                isFavorite:
                    item['is_favorite'] ??
                    item['isFavorite'] ??
                    conversation['is_favorite'] ??
                    conversation['isFavorite'] ??
                    false,
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
                isArchived: true,
                isFavorite:
                    item['is_favorite'] ??
                    item['isFavorite'] ??
                    conversation['is_favorite'] ??
                    conversation['isFavorite'] ??
                    false,
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
                                    size: 24,
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
                                    style: fontStyle.clashDisplayRegular12
                                        .textColor(
                                          appColor(context).textMediumGrey,
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
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right side (time)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: fontStyle.clashDisplayRegular10.textColor(
                    appColor(context).textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                controller.failedUnarchiveChatIds.contains(chatId)
                    ? GestureDetector(
                        onTap: () =>
                            controller.handleUnarchiveChat(context, chatId),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: appColor(context).secondary,
                          size: 20,
                        ),
                      )
                    : unread > 0
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
}
