import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/group_chat_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/media_cache_service.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/linkified_text.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/view/group_info_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';
import 'package:shieldconnect_app/view/media_viewer_screen.dart';
import 'package:shieldconnect_app/view/voice_message_bubble.dart';
import 'package:shieldconnect_app/view/forward_screen.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/view/typing_indicator_bubble.dart';
import 'package:shieldconnect_app/view/message_info_bottom_sheet.dart';

class GroupChatScreen extends StatelessWidget {
  final String groupName;
  final String? groupId;
  final bool isArchived;
  final bool isFavorite;

  GroupChatScreen({
    super.key,
    required this.groupName,
    this.groupId,
    this.isArchived = false,
    this.isFavorite = false,
  });

  final Map<String, GlobalKey> _messageKeys = {};

  Future<void> _scrollToMessage(
    GroupChatController controller,
    String msgId,
  ) async {
    final int index = controller.messages.indexWhere(
      (m) => m['id']?.toString() == msgId,
    );
    if (index == -1) return;

    final key = _messageKeys[msgId];
    if (key != null) {
      if (key.currentContext != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        controller.highlightMessage(msgId);
      } else {
        // Estimate position and animate there first to force item building
        final double estimatedOffset = index * 90.0;
        final maxScroll = controller.scrollController.position.maxScrollExtent;
        final targetOffset = estimatedOffset.clamp(0.0, maxScroll);

        await controller.scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );

        // Wait for build cycle
        await Future.delayed(const Duration(milliseconds: 150));

        if (key.currentContext != null) {
          await Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          controller.highlightMessage(msgId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<CallManager>().fetchActiveGroupCalls();
      }
    });

    return ChangeNotifierProvider<GroupChatController>(
      create: (context) {
        final controller = GroupChatController();
        if (groupId != null) {
          controller.init(groupId!, isFavorite: isFavorite);
        }
        return controller;
      },
      child: Consumer<GroupChatController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: appColor(context).white,
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Aesthetic Group Header
                  _buildHeader(context, controller),

                  // Ongoing active call banner for this group chat
                  Consumer<CallManager>(
                    builder: (context, callManager, child) {
                      final String? resolvedGroupId =
                          groupId ?? controller.groupId;
                      if (resolvedGroupId == null)
                        return const SizedBox.shrink();

                      final activeCall =
                          callManager.activeGroupCalls[resolvedGroupId];
                      if (activeCall == null) return const SizedBox.shrink();

                      // If user is already active in this call, don't show the join banner
                      final String? callId =
                          (activeCall['_id'] ?? activeCall['id'])?.toString();
                      if (callManager.state != CallState.idle &&
                          callManager.currentCallId == callId) {
                        return const SizedBox.shrink();
                      }

                      final isVideo = activeCall['call_type'] == 'video';
                      final String roomId =
                          (activeCall['_id'] ??
                                  activeCall['id'] ??
                                  activeCall['roomId'])
                              ?.toString() ??
                          '';
                      final String name =
                          controller.groupDetails?['name']?.toString() ??
                          groupName;
                      final String? image =
                          controller.groupDetails?['group_image'] ??
                          controller.groupDetails?['avatar'];
                      final String? callerId =
                          (activeCall['initiator_id'] is Map
                              ? (activeCall['initiator_id']['_id'] ??
                                        activeCall['initiator_id']['id'])
                                    ?.toString()
                              : activeCall['initiator_id']?.toString()) ??
                          activeCall['callerId']?.toString();

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
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
                                    "Ongoing Group Call",
                                    style: fontStyle.clashDisplaySemiBold14
                                        .textColor(Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isVideo
                                        ? "Tap Join Now to join the video call"
                                        : "Tap Join Now to join the voice call",
                                    style: fontStyle.clashDisplayRegular12
                                        .textColor(Colors.white60),
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
                                  groupId: resolvedGroupId,
                                  groupName: name,
                                  groupAvatar: image,
                                  callerId: callerId,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Join Now",
                                style: fontStyle.clashDisplayBold12.textColor(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 2. Dynamic Chat Body
                  Expanded(
                    child: Container(
                      decoration:
                          controller.wallpaperUrl != null &&
                              controller.wallpaperUrl!.isNotEmpty
                          ? BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  ApiService.getImageUrl(
                                    controller.wallpaperUrl,
                                  ),
                                ),
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                      child: controller.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: controller.scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount:
                                  controller.messages.length +
                                  (controller.typingUsers.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == controller.messages.length) {
                                  String? typingAvatar;
                                  if (controller.typingUsers.isNotEmpty &&
                                      controller.groupDetails != null &&
                                      controller.groupDetails!['members'] !=
                                          null) {
                                    final String firstTypingName =
                                        controller.typingUsers.first;
                                    final dynamic members =
                                        controller.groupDetails!['members'];
                                    if (members is List) {
                                      for (final dynamic m in members) {
                                        if (m is Map) {
                                          final dynamic userVal =
                                              m['user_id'] ?? m['user'] ?? m;
                                          String name = "";
                                          String avatar = "";
                                          if (userVal is Map) {
                                            name =
                                                userVal['name']?.toString() ??
                                                "";
                                            avatar =
                                                userVal['avatar']?.toString() ??
                                                "";
                                          } else {
                                            name = m['name']?.toString() ?? "";
                                            avatar =
                                                m['avatar']?.toString() ?? "";
                                          }
                                          if (name == firstTypingName) {
                                            typingAvatar = avatar;
                                            break;
                                          }
                                        }
                                      }
                                    }
                                  }
                                  final String avatarUrl = typingAvatar != null
                                      ? ApiService.getImageUrl(typingAvatar)
                                      : "";
                                  final bool hasAvatar = avatarUrl.isNotEmpty;

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: appColor(
                                            context,
                                          ).grey100,
                                          backgroundImage: hasAvatar
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                          child: hasAvatar
                                              ? null
                                              : Icon(
                                                  Icons.person,
                                                  color: appColor(
                                                    context,
                                                  ).secondary,
                                                  size: 14,
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        const TypingIndicatorBubble(),
                                      ],
                                    ),
                                  );
                                }
                                final message = controller.messages[index];
                                final String msgId =
                                    message['id']?.toString() ?? '';
                                final key = msgId.isNotEmpty
                                    ? _messageKeys.putIfAbsent(
                                        msgId,
                                        () => GlobalKey(),
                                      )
                                    : null;
                                final String type =
                                    message['type']?.toString() ?? 'text';
                                final bool isOutgoing =
                                    message['isOutgoing'] == true;
                                final String? createdAt = message['createdAt'];

                                final bool isBadge =
                                    (type == 'system' || type == 'status') &&
                                    (() {
                                      final String msgText =
                                          message['text'] ?? "";
                                      final String msgLower = msgText
                                          .toLowerCase();
                                      return msgLower.contains("created") ||
                                          msgLower.contains(
                                            "system_group_created",
                                          ) ||
                                          msgLower.contains("added") ||
                                          msgLower.contains("joined") ||
                                          msgLower.contains("left") ||
                                          msgLower.contains("removed");
                                    })();

                                // Calculate if we need to show the date header
                                bool showDateHeader = false;
                                String dateHeaderStr = "";
                                if (createdAt != null) {
                                  final String currentDayStr =
                                      DateHelper.formatMessageDate(createdAt);
                                  if (index == 0) {
                                    showDateHeader = true;
                                    dateHeaderStr = currentDayStr;
                                  } else {
                                    final prevMsg =
                                        controller.messages[index - 1];
                                    final String? prevCreatedAt =
                                        prevMsg['createdAt'];
                                    if (prevCreatedAt != null) {
                                      final String prevDayStr =
                                          DateHelper.formatMessageDate(
                                            prevCreatedAt,
                                          );
                                      if (currentDayStr != prevDayStr) {
                                        showDateHeader = true;
                                        dateHeaderStr = currentDayStr;
                                      }
                                    } else {
                                      showDateHeader = true;
                                      dateHeaderStr = currentDayStr;
                                    }
                                  }
                                }

                                Widget messageWidget;

                                if (type == 'system' || type == 'status') {
                                  final String msgText = message['text'] ?? "";
                                  final String msgLower = msgText.toLowerCase();
                                  if (msgLower.contains("created") ||
                                      msgLower.contains(
                                        "system_group_created",
                                      ) ||
                                      msgLower.contains("added") ||
                                      msgLower.contains("joined") ||
                                      msgLower.contains("left") ||
                                      msgLower.contains("removed")) {
                                    String displayStr = msgText;
                                    if (msgLower.contains("created") ||
                                        msgLower.contains(
                                          "system_group_created",
                                        )) {
                                      displayStr = 'Group "$groupName" created';
                                    } else if (msgText.startsWith(
                                      "system_member_added:",
                                    )) {
                                      final parts = msgText.split(':');
                                      final name = parts.length >= 3
                                          ? parts[2]
                                          : (parts.length == 2
                                                ? parts[1]
                                                : "A member");
                                      displayStr = "$name added to group";
                                    } else if (msgText.startsWith(
                                      "system_member_removed:",
                                    )) {
                                      final parts = msgText.split(':');
                                      final name = parts.length >= 3
                                          ? parts[2]
                                          : (parts.length == 2
                                                ? parts[1]
                                                : "A member");
                                      displayStr = "$name removed from group";
                                    } else if (msgText.startsWith(
                                      "system_member_joined:",
                                    )) {
                                      final parts = msgText.split(':');
                                      final name = parts.length >= 3
                                          ? parts[2]
                                          : (parts.length == 2
                                                ? parts[1]
                                                : "A member");
                                      displayStr = "$name joined the group";
                                    } else if (msgText.startsWith(
                                      "system_member_left:",
                                    )) {
                                      final parts = msgText.split(':');
                                      final memberId = parts.length >= 2
                                          ? parts[1]
                                          : '';
                                      if (memberId ==
                                          (controller.userId ?? '')) {
                                        displayStr = "You left the group";
                                      } else {
                                        final name = parts.length >= 3
                                            ? parts[2]
                                            : (parts.length == 2
                                                  ? parts[1]
                                                  : "A member");
                                        displayStr = "$name left the group";
                                      }
                                    }
                                    messageWidget = Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: appColor(context).grey100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              displayStr,
                                              style: fontStyle
                                                  .clashDisplaySemiBold12
                                                  .textColor(
                                                    appColor(context).grey600,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  } else {
                                    messageWidget = Column(
                                      children: [
                                        _buildStatusBubble(
                                          context,
                                          asset: ImageAssets.approved,
                                          title: "System Update",
                                          subtitle: msgText,
                                          titleColor: const Color(0xFF2E7D32),
                                          bgColor: const Color(
                                            0xFFE8F5E9,
                                          ).withValues(alpha: 0.5),
                                          time: message['time'] ?? "",
                                          isOutgoing: isOutgoing,
                                          avatar: message['avatar']?.toString(),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }
                                } else {
                                  final String msgType =
                                      message['type']?.toString() ?? 'text';
                                  final String? fileUrl = message['url']
                                      ?.toString();
                                  final String avatarPath =
                                      message['avatar']?.toString() ?? '';
                                  final String senderName =
                                      message['sender'] ?? "Unknown";
                                  final String msgText = message['text'] ?? "";
                                  final String msgTime = message['time'] ?? "";

                                  messageWidget = Column(
                                    children: [
                                      _buildMediaMessageBubble(
                                        context,
                                        type: msgType,
                                        text: msgText,
                                        time: msgTime,
                                        url: fileUrl,
                                        isOutgoing: isOutgoing,
                                        senderName: senderName,
                                        avatar: avatarPath,
                                        fileName: message['file_name']
                                            ?.toString(),
                                        replyTo: message['replyTo']?.toString(),
                                        replyToSender: message['replyToSender']
                                            ?.toString(),
                                        parentMessageId:
                                            message['parent_message_id']
                                                ?.toString(),
                                        onReplyTap: (parentMsgId) =>
                                            _scrollToMessage(
                                              controller,
                                              parentMsgId,
                                            ),
                                        isForwarded:
                                            message['is_forwarded'] == true,
                                        isEdited: message['isEdited'] == true,
                                      ),
                                      SizedBox(height: isOutgoing ? 8 : 16),
                                    ],
                                  );
                                }

                                final itemWidget = showDateHeader
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Center(
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              child: Text(
                                                dateHeaderStr,
                                                style: fontStyle
                                                    .clashDisplayBold14
                                                    .textColor(
                                                      appColor(context).black,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          messageWidget,
                                        ],
                                      )
                                    : messageWidget;

                                final bool isSelected =
                                    controller.selectedMessageForOptions !=
                                        null &&
                                    controller
                                            .selectedMessageForOptions!['id'] ==
                                        message['id'];
                                final bool isHighlighted =
                                    controller.highlightedMessageId ==
                                    message['id'];

                                return GestureDetector(
                                  key: key,
                                  behavior: HitTestBehavior.opaque,
                                  onLongPress: isBadge
                                      ? null
                                      : () {
                                          controller.selectMessageForOptions(
                                            message,
                                          );
                                        },
                                  onTap: () {
                                    if (controller.selectedMessageForOptions !=
                                        null) {
                                      controller.selectMessageForOptions(null);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    color: isSelected
                                        ? appColor(
                                            context,
                                          ).secondary.withValues(alpha: 0.12)
                                        : (isHighlighted
                                              ? appColor(context).secondary
                                                    .withValues(alpha: 0.22)
                                              : Colors.transparent),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: AbsorbPointer(
                                      absorbing:
                                          controller
                                              .selectedMessageForOptions !=
                                          null,
                                      child: Dismissible(
                                        key: Key(
                                          'reply_${message['id'] ?? index}',
                                        ),
                                        direction: isBadge
                                            ? DismissDirection.none
                                            : DismissDirection.startToEnd,
                                        confirmDismiss: (direction) async {
                                          controller.selectReplyMessage(
                                            message,
                                          );
                                          return false;
                                        },
                                        background: isBadge
                                            ? null
                                            : Container(
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.only(
                                                  left: 16,
                                                ),
                                                child: Icon(
                                                  Icons.reply_rounded,
                                                  color: appColor(
                                                    context,
                                                  ).secondary,
                                                  size: 24,
                                                ),
                                              ),
                                        child: itemWidget,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // 3. Footer Toolbar
                  _buildComposer(context, controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMemberNames(Map<String, dynamic>? groupDetails) {
    if (groupDetails == null) return "Loading members...";
    final List<dynamic>? membersList = groupDetails['members'];
    if (membersList == null || membersList.isEmpty) return "No members";

    final List<String> names = [];
    for (final dynamic item in membersList) {
      if (item is Map<String, dynamic>) {
        final dynamic userIdVal = item['user_id'];
        if (userIdVal is Map<String, dynamic>) {
          final String name = userIdVal['name']?.toString() ?? "";
          if (name.isNotEmpty) names.add(name);
        } else if (item['name'] != null) {
          names.add(item['name'].toString());
        }
      }
    }

    if (names.isEmpty) return "Alice, Bob, You"; // Fallback
    return names.join(", ");
  }

  /// Structuring navigation bar with group profile avatar and shortcuts
  Widget _buildHeader(BuildContext context, GroupChatController controller) {
    if (controller.selectedMessageForOptions != null) {
      final msg = controller.selectedMessageForOptions!;
      final bool isMsgOutgoing = msg['isOutgoing'] == true;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: appColor(context).white,
          border: Border(
            bottom: BorderSide(color: appColor(context).grey100, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: appColor(context).secondary),
                  onPressed: () => controller.selectMessageForOptions(null),
                ),
                const SizedBox(width: 8),
                Text(
                  "1",
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    appColor(context).black,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMsgOutgoing) ...[
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: appColor(context).secondary,
                      size: 22,
                    ),
                    onPressed: () {
                      final String messageId = (msg['_id'] ?? msg['id'] ?? '')
                          .toString();
                      final String? createdAt = msg['createdAt']?.toString();
                      controller.selectMessageForOptions(null);
                      if (messageId.isNotEmpty) {
                        MessageInfoBottomSheet.show(
                          context,
                          messageId: messageId,
                          createdAt: createdAt,
                          isGroup: true,
                          groupDetails: controller.groupDetails,
                          currentUserId: controller.userId ?? '',
                        );
                      }
                    },
                  ),
                  if ((msg['type'] == null ||
                          msg['type'] == 'text' ||
                          msg['type'] == '') &&
                      _isMessageWithinEditLimit(msg))
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: appColor(context).secondary,
                        size: 22,
                      ),
                      onPressed: () {
                        _showEditOverlay(context, controller);
                      },
                    ),
                ],
                IconButton(
                  icon: Icon(
                    Icons.reply_rounded,
                    color: appColor(context).secondary,
                    size: 22,
                  ),
                  onPressed: () {
                    controller.selectReplyMessage(msg);
                    controller.selectMessageForOptions(null);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: appColor(context).secondary,
                    size: 22,
                  ),
                  onPressed: () {
                    _showDeleteConfirmation(context, controller);
                  },
                ),

                IconButton(
                  icon: Icon(
                    Icons.forward,
                    color: appColor(context).secondary,
                    size: 22,
                  ),
                  onPressed: () {
                    final msgId = msg['_id'] ?? msg['id'] ?? "";
                    controller.selectMessageForOptions(null);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ForwardScreen(messageId: msgId.toString()),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    final groupDetails = controller.groupDetails;
    final String name = groupDetails?['name']?.toString() ?? groupName;
    final String? groupImage =
        groupDetails?['group_image'] ?? groupDetails?['avatar'];
    final String membersText = _getMemberNames(groupDetails);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: appColor(context).grey100, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back trigger
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: appColor(context).secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Tap target area linking to Group Info
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!controller.isUserMemberOfGroup || controller.isSuspended)
                  return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: controller,
                      child: GroupInfoScreen(
                        groupName: name,
                        groupId: controller.groupId ?? groupId ?? "",
                      ),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: appColor(context).grey100,
                    backgroundImage: groupImage != null && groupImage.isNotEmpty
                        ? NetworkImage(
                            groupImage.startsWith('http')
                                ? groupImage
                                : 'http://localhost:5001/uploads/$groupImage',
                          )
                        : null,
                    child: groupImage == null || groupImage.isEmpty
                        ? Icon(
                            Icons.group,
                            color: appColor(context).grey400,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: fontStyle.clashDisplaySemiBold16.textColor(
                            appColor(context).black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          membersText,
                          style: fontStyle.clashDisplayRegular12.textColor(
                            appColor(context).grey400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Call shortcuts
          if (controller.isUserMemberOfGroup && !controller.isSuspended) ...[
            GestureDetector(
              onTap: () {
                final List<String> memberIds = [];
                final gDetails = controller.groupDetails;
                final List<String> previousMemberIds = [];
                if (gDetails != null && gDetails['previous_members'] != null) {
                  final prevList = gDetails['previous_members'];
                  if (prevList is List) {
                    for (var pm in prevList) {
                      if (pm is Map) {
                        final userIdData = pm['user_id'];
                        String? pmId;
                        if (userIdData is Map) {
                          pmId = (userIdData['_id'] ?? userIdData['id'])?.toString();
                        } else if (userIdData != null) {
                          pmId = userIdData.toString();
                        } else {
                          pmId = (pm['_id'] ?? pm['id'])?.toString();
                        }
                        if (pmId != null && pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      } else if (pm != null) {
                        final pmId = pm.toString();
                        if (pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      }
                    }
                  }
                }

                if (gDetails != null && gDetails['members'] != null) {
                  final membersList = gDetails['members'];
                  if (membersList is List) {
                    final myId = context.read<CallManager>().myUserId;
                    for (var m in membersList) {
                      if (m is Map) {
                        final userIdData = m['user_id'];
                        String? mId;
                        if (userIdData is Map) {
                          mId = (userIdData['_id'] ?? userIdData['id'])
                              ?.toString();
                        } else if (userIdData != null) {
                          mId = userIdData.toString();
                        } else {
                          mId = (m['_id'] ?? m['id'])?.toString();
                        }
                        if (mId != null &&
                            mId.isNotEmpty &&
                            mId != myId &&
                            !previousMemberIds.contains(mId)) {
                          memberIds.add(mId);
                        }
                      }
                    }
                  }
                }
                context.read<CallManager>().startCall(
                  groupId ?? '',
                  groupName,
                  isVideo: false,
                  recipientAvatar: groupImage,
                  isGroup: true,
                  groupMemberIds: memberIds,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoiceCallingScreen(
                      userName: groupName,
                      avatarUrl: groupImage,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Image.asset(
                  ImageAssets.phone,
                  width: 22,
                  height: 22,
                  color: appColor(context).secondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                final List<String> memberIds = [];
                final gDetails = controller.groupDetails;
                final List<String> previousMemberIds = [];
                if (gDetails != null && gDetails['previous_members'] != null) {
                  final prevList = gDetails['previous_members'];
                  if (prevList is List) {
                    for (var pm in prevList) {
                      if (pm is Map) {
                        final userIdData = pm['user_id'];
                        String? pmId;
                        if (userIdData is Map) {
                          pmId = (userIdData['_id'] ?? userIdData['id'])?.toString();
                        } else if (userIdData != null) {
                          pmId = userIdData.toString();
                        } else {
                          pmId = (pm['_id'] ?? pm['id'])?.toString();
                        }
                        if (pmId != null && pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      } else if (pm != null) {
                        final pmId = pm.toString();
                        if (pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      }
                    }
                  }
                }

                if (gDetails != null && gDetails['members'] != null) {
                  final membersList = gDetails['members'];
                  if (membersList is List) {
                    final myId = context.read<CallManager>().myUserId;
                    for (var m in membersList) {
                      if (m is Map) {
                        final userIdData = m['user_id'];
                        String? mId;
                        if (userIdData is Map) {
                          mId = (userIdData['_id'] ?? userIdData['id'])
                              ?.toString();
                        } else if (userIdData != null) {
                          mId = userIdData.toString();
                        } else {
                          mId = (m['_id'] ?? m['id'])?.toString();
                        }
                        if (mId != null &&
                            mId.isNotEmpty &&
                            mId != myId &&
                            !previousMemberIds.contains(mId)) {
                          memberIds.add(mId);
                        }
                      }
                    }
                  }
                }
                context.read<CallManager>().startCall(
                  groupId ?? '',
                  groupName,
                  isVideo: true,
                  recipientAvatar: groupImage,
                  isGroup: true,
                  groupMemberIds: memberIds,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoCallingScreen(userName: groupName),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Image.asset(
                  ImageAssets.videoRecorder,
                  width: 24,
                  height: 24,
                  color: appColor(context).secondary,
                ),
              ),
            ),
          ],
          if (controller.isUserMemberOfGroup && !controller.isSuspended) ...[
            const SizedBox(width: 4),

            // Three-dot popup menu
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: appColor(context).white,
              icon: Icon(Icons.more_vert, color: appColor(context).secondary),
              onSelected: (value) async {
                if (value == "Archive") {
                  final success = await controller.archiveChat();
                  if (success && context.mounted) {
                    ToastHelper.showToast(context, "Chat archived");
                    Provider.of<HomeScreenController>(
                      context,
                      listen: false,
                    ).fetchRecentChats(updateLoadingState: false);
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ToastHelper.showToast(context, "Failed to archive chat");
                  }
                } else if (value == "Unarchive") {
                  final success = await Provider.of<ProfileController>(
                    context,
                    listen: false,
                  ).unarchiveChat(groupId ?? "");
                  if (success && context.mounted) {
                    ToastHelper.showToast(context, "Chat unarchived");
                    Provider.of<HomeScreenController>(
                      context,
                      listen: false,
                    ).fetchRecentChats(updateLoadingState: false);
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ToastHelper.showToast(context, "Failed to unarchive chat");
                  }
                } else if (value == "Favorite" || value == "Unfavorite") {
                  final newFavStatus = !controller.isFavorite;
                  final success = await controller.toggleFavorite(newFavStatus);
                  if (success && context.mounted) {
                    ToastHelper.showToast(
                      context,
                      newFavStatus
                          ? "Added to favorites"
                          : "Removed from favorites",
                    );
                    Provider.of<HomeScreenController>(
                      context,
                      listen: false,
                    ).fetchRecentChats(updateLoadingState: false);
                  } else if (context.mounted) {
                    ToastHelper.showToast(
                      context,
                      "Failed to update favorite status",
                    );
                  }
                } else if (value == "Clear Chat") {
                  _showClearChatConfirmation(context, controller);
                } else if (value == "Delete Chat") {
                  _showDeleteChatConfirmation(context, controller);
                } else if (value == "Report Group") {
                  _showReportDialog(context, controller, groupName);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  isArchived
                      ? _buildPopupMenuItem(
                          context,
                          "Unarchive",
                          ImageAssets.archive,
                        )
                      : _buildPopupMenuItem(
                          context,
                          "Archive",
                          ImageAssets.archive,
                        ),
                  _buildPopupMenuItem(
                    context,
                    "Clear Chat",
                    ImageAssets.clearChat,
                  ),
                  _buildPopupMenuItem(
                    context,
                    "Delete Chat",
                    ImageAssets.deleteChat,
                  ),
                  _buildPopupMenuItem(
                    context,
                    controller.isFavorite ? "Unfavorite" : "Favorite",
                    ImageAssets.favorite,
                  ),
                  _buildPopupMenuItem(
                    context,
                    "Report Group",
                    ImageAssets.report,
                  ),
                ];
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext outerContext,
    GroupChatController controller,
  ) {
    final msg = controller.selectedMessageForOptions;
    if (msg == null) return;
    final String messageId = msg['id']?.toString() ?? "";
    final bool isMsgOutgoing = msg['isOutgoing'] == true;

    showDialog(
      context: outerContext,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appColor(context).white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: appColor(context).secondary, width: 1.5),
          ),
          title: Text(
            "Delete Message?",
            style: fontStyle.clashDisplayBold18.textColor(
              appColor(context).black,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this message?",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: fontStyle.clashDisplayMedium14.textColor(
                  appColor(context).grey400,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.deleteForMeApi(outerContext, messageId);
                controller.selectMessageForOptions(null);
              },
              child: Text(
                "Delete for me",
                style: fontStyle.clashDisplayBold14.textColor(
                  appColor(context).secondary,
                ),
              ),
            ),
            if (isMsgOutgoing)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColor(context).secondary,
                  foregroundColor: appColor(context).white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  controller.deleteForEveryoneApi(outerContext, messageId);
                  controller.selectMessageForOptions(null);
                },
                child: Text(
                  "Delete for everyone",
                  style: fontStyle.clashDisplayBold14.textColor(
                    appColor(context).white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showEditOverlay(BuildContext context, GroupChatController controller) {
    final msg = controller.selectedMessageForOptions;
    if (msg == null) return;
    final bool isOutgoing = msg['isOutgoing'] == true;
    if (!isOutgoing) {
      ToastHelper.showToast(context, "Only the sender can edit this message");
      return;
    }
    if (!_isMessageWithinEditLimit(msg)) {
      ToastHelper.showToast(
        context,
        "Messages can only be edited within 24 hours of sending",
      );
      return;
    }
    final String messageId = msg['id']?.toString() ?? "";
    final String oldText = msg['text']?.toString() ?? "";

    final TextEditingController editController = TextEditingController(
      text: oldText,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Edit Message",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: appColor(context).white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: appColor(context).secondary,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: editController,
                        autofocus: true,
                        cursorColor: appColor(context).secondary,
                        style: fontStyle.clashDisplayRegular14.textColor(
                          appColor(context).black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Edit message...",
                          hintStyle: fontStyle.clashDisplayRegular14.textColor(
                            appColor(context).grey400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final newText = editController.text.trim();
                        if (newText.isNotEmpty && newText != oldText) {
                          controller.editMessageApi(
                            context,
                            messageId,
                            newText,
                          );
                        }
                        controller.selectMessageForOptions(null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: appColor(context).secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: appColor(context).white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isMessageWithinEditLimit(Map<String, dynamic> msg) {
    if (msg['createdAt'] == null) return true;
    try {
      final DateTime createdAt = DateTime.parse(msg['createdAt'].toString());
      final DateTime now = DateTime.now().toUtc();
      final difference = now.difference(createdAt.toUtc());
      return difference.inHours < 24;
    } catch (e) {
      return true;
    }
  }

  /// Creates high-stadium, visually unified popup row items driven by specific branding image assets
  PopupMenuItem<String> _buildPopupMenuItem(
    BuildContext context,
    String title,
    String asset,
  ) {
    return PopupMenuItem<String>(
      value: title,
      height: 46,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 20,
            height: 20,
            color: appColor(context).secondary,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: fontStyle.clashDisplaySemiBold14.textColor(
              appColor(context).black,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders Outgoing text widgets
  Widget _buildOutgoingText(
    BuildContext context,
    String text,
    String time, {
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    bool isForwarded = false,
    bool isEdited = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: appColor(context).secondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isForwarded) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scaleX: -1,
                        child: Icon(
                          Icons.reply_rounded,
                          size: 13,
                          color: appColor(context).white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Forwarded",
                        style: fontStyle.clashDisplayRegular10
                            .italic()
                            .textColor(
                              appColor(context).white.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (replyTo != null) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (onReplyTap != null && parentMessageId != null) {
                        onReplyTap(parentMessageId);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: appColor(context).white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: appColor(context).white,
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            replyToSender ?? "Reply",
                            style: fontStyle.clashDisplayBold12.textColor(
                              appColor(context).white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyTo,
                            style: fontStyle.clashDisplayRegular12.textColor(
                              appColor(context).white.withValues(alpha: 0.95),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                LinkifiedText(
                  text: text,
                  style: fontStyle.clashDisplayMedium14.textColor(
                    appColor(context).white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: fontStyle.clashDisplayMedium10.textColor(
                        appColor(context).white.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isEdited) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: appColor(
                            context,
                          ).white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Edited',
                          style: fontStyle.clashDisplayMedium10.textColor(
                            appColor(context).white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildGreenTick(context),
      ],
    );
  }

  Widget _buildGreenTick(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: appColor(context).green,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.done_all_rounded,
          color: appColor(context).white,
          size: 11,
        ),
      ),
    );
  }

  /// Incoming message block with Sender Name
  Widget _buildIncomingText(
    BuildContext context, {
    required String senderName,
    required String text,
    required String time,
    required String avatar,
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    bool isForwarded = false,
    bool isEdited = false,
  }) {
    final String imageUrl = ApiService.getImageUrl(avatar);
    final bool hasImage = imageUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: appColor(context).grey100,
          backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
          child: hasImage
              ? null
              : Icon(
                  Icons.person,
                  color: appColor(context).secondary,
                  size: 14,
                ),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: appColor(context).grey100,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topLeft: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                senderName,
                style: fontStyle.clashDisplayBold12.textColor(
                  appColor(context).secondary,
                ),
              ),
              if (isForwarded) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scaleX: -1,
                      child: Icon(
                        Icons.reply_rounded,
                        size: 13,
                        color: appColor(
                          context,
                        ).secondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Forwarded",
                      style: fontStyle.clashDisplayRegular10.italic().textColor(
                        appColor(context).secondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
              if (replyTo != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (onReplyTap != null && parentMessageId != null) {
                      onReplyTap(parentMessageId);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appColor(
                        context,
                      ).secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: appColor(context).secondary,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replyToSender ?? "Reply",
                          style: fontStyle.clashDisplayBold12.textColor(
                            appColor(context).secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyTo,
                          style: fontStyle.clashDisplayRegular12.textColor(
                            appColor(context).black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: LinkifiedText(
                      text: text,
                      style: fontStyle.clashDisplayMedium14.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).grey400,
                    ),
                  ),
                  if (isEdited) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: appColor(context).black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Edited',
                        style: fontStyle.clashDisplayMedium10.textColor(
                          appColor(context).black54,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaMessageBubble(
    BuildContext context, {
    required String type,
    required String text,
    required String time,
    required String? url,
    required bool isOutgoing,
    required String senderName,
    required String avatar,
    String? fileName,
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    bool isForwarded = false,
    bool isEdited = false,
  }) {
    if (type == 'image') {
      return _buildImageBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        senderName,
        avatar,
        isForwarded: isForwarded,
      );
    } else if (type == 'video') {
      return _buildVideoBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        senderName,
        avatar,
        isForwarded: isForwarded,
      );
    } else if (type == 'file' || type == 'document') {
      return _buildDocumentBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        senderName,
        avatar,
        fileName,
        isForwarded: isForwarded,
      );
    } else if (type == 'audio') {
      return _buildAudioBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        senderName,
        avatar,
        isForwarded: isForwarded,
      );
    } else if (type == 'sticker') {
      return _buildStickerBubble(
        context,
        url,
        time,
        isOutgoing,
        senderName,
        avatar,
        isForwarded: isForwarded,
      );
    } else {
      return isOutgoing
          ? _buildOutgoingText(
              context,
              text,
              time,
              replyTo: replyTo,
              replyToSender: replyToSender,
              parentMessageId: parentMessageId,
              onReplyTap: onReplyTap,
              isForwarded: isForwarded,
              isEdited: isEdited,
            )
          : _buildIncomingText(
              context,
              senderName: senderName,
              text: text,
              time: time,
              avatar: avatar,
              replyTo: replyTo,
              replyToSender: replyToSender,
              parentMessageId: parentMessageId,
              onReplyTap: onReplyTap,
              isForwarded: isForwarded,
              isEdited: isEdited,
            );
    }
  }

  Widget _buildImageBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String senderName,
    String avatar, {
    bool isForwarded = false,
  }) {
    final bubbleColor = isOutgoing
        ? appColor(context).secondary
        : appColor(context).grey100;
    final textColor = isOutgoing
        ? appColor(context).white
        : appColor(context).black;
    final String avatarUrl = ApiService.getImageUrl(avatar);
    final bool hasAvatar = avatarUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: appColor(context).grey100,
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
            child: hasAvatar
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 14,
                  ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () {
            if (url != null && url.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaViewerScreen(
                    url: url,
                    type: 'image',
                    fileName: text.isNotEmpty ? text : 'image.jpg',
                  ),
                ),
              );
            }
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.48,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
                bottomLeft: const Radius.circular(20),
                topLeft: isOutgoing
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isForwarded) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scaleX: -1,
                          child: Icon(
                            Icons.reply_rounded,
                            size: 13,
                            color: isOutgoing
                                ? appColor(context).white.withValues(alpha: 0.7)
                                : appColor(
                                    context,
                                  ).secondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Forwarded",
                          style: fontStyle.clashDisplayRegular10
                              .italic()
                              .textColor(
                                isOutgoing
                                    ? appColor(
                                        context,
                                      ).white.withValues(alpha: 0.7)
                                    : appColor(
                                        context,
                                      ).secondary.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isOutgoing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      senderName,
                      style: fontStyle.clashDisplayBold12.textColor(
                        appColor(context).secondary,
                      ),
                    ),
                  ),
                if (url != null && url.isNotEmpty)
                  FutureBuilder<File?>(
                    future: MediaCacheService().getCachedMedia(url),
                    builder: (context, snapshot) {
                      final file = snapshot.data;
                      if (file != null) {
                        return Image.file(
                          file,
                          fit: BoxFit.cover,
                          height: 120,
                        );
                      }
                      return Image.network(
                        url,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 110,
                            color: appColor(context).grey200,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 110,
                          color: appColor(context).grey200,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: appColor(context).grey400,
                              size: 28,
                            ),
                          ),
                        ),
                        fit: BoxFit.cover,
                        height: 120,
                      );
                    },
                  )
                else
                  Container(
                    height: 110,
                    color: appColor(context).grey200,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: appColor(context).grey400,
                        size: 28,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (text.isNotEmpty &&
                          text != 'Check out this photo!' &&
                          text != 'Check out this video!') ...[
                        Flexible(
                          child: Text(
                            text,
                            style: fontStyle.clashDisplayMedium14.textColor(
                              textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        time,
                        style: fontStyle.clashDisplayMedium10.textColor(
                          isOutgoing
                              ? appColor(context).white.withValues(alpha: 0.7)
                              : appColor(context).grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOutgoing) ...[const SizedBox(width: 8), _buildGreenTick(context)],
      ],
    );
  }

  Widget _buildVideoBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String senderName,
    String avatar, {
    bool isForwarded = false,
  }) {
    final bubbleColor = isOutgoing
        ? appColor(context).secondary
        : appColor(context).grey100;
    final textColor = isOutgoing
        ? appColor(context).white
        : appColor(context).black;
    final String avatarUrl = ApiService.getImageUrl(avatar);
    final bool hasAvatar = avatarUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: appColor(context).grey100,
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
            child: hasAvatar
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 14,
                  ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () {
            if (url != null && url.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaViewerScreen(
                    url: url,
                    type: 'video',
                    fileName: text.isNotEmpty ? text : 'video.mp4',
                  ),
                ),
              );
            }
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.48,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
                bottomLeft: const Radius.circular(20),
                topLeft: isOutgoing
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isForwarded) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scaleX: -1,
                          child: Icon(
                            Icons.reply_rounded,
                            size: 13,
                            color: isOutgoing
                                ? appColor(context).white.withValues(alpha: 0.7)
                                : appColor(
                                    context,
                                  ).secondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Forwarded",
                          style: fontStyle.clashDisplayRegular10
                              .italic()
                              .textColor(
                                isOutgoing
                                    ? appColor(
                                        context,
                                      ).white.withValues(alpha: 0.7)
                                    : appColor(
                                        context,
                                      ).secondary.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isOutgoing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      senderName,
                      style: fontStyle.clashDisplayBold12.textColor(
                        appColor(context).secondary,
                      ),
                    ),
                  ),
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOutgoing
                          ? [const Color(0xFFE91E63), const Color(0xFFC2185B)]
                          : [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOutgoing
                            ? appColor(context).white.withValues(alpha: 0.2)
                            : appColor(context).black.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: isOutgoing
                            ? appColor(context).white
                            : appColor(context).secondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (text.isNotEmpty &&
                          text != 'Check out this photo!' &&
                          text != 'Check out this video!') ...[
                        Flexible(
                          child: Text(
                            text,
                            style: fontStyle.clashDisplayMedium14.textColor(
                              textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        time,
                        style: fontStyle.clashDisplayMedium10.textColor(
                          isOutgoing
                              ? appColor(context).white.withValues(alpha: 0.7)
                              : appColor(context).grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOutgoing) ...[const SizedBox(width: 8), _buildGreenTick(context)],
      ],
    );
  }

  Widget _buildDocumentBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String senderName,
    String avatar,
    String? fileName, {
    bool isForwarded = false,
  }) {
    final bubbleColor = isOutgoing
        ? appColor(context).secondary
        : appColor(context).grey100;
    final textColor = isOutgoing
        ? appColor(context).white
        : appColor(context).black;
    final subtitleColor = isOutgoing
        ? appColor(context).white.withValues(alpha: 0.7)
        : appColor(context).grey500;

    final String resolvedFileName = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : ((url != null && url.isNotEmpty)
              ? url.split('/').last
              : (text.isNotEmpty ? text : "DOCUMENT"));

    final String extension = resolvedFileName.contains('.')
        ? resolvedFileName.split('.').last.toUpperCase()
        : "DOC";

    String sizeStr = "120 kB";
    final extLower = extension.toLowerCase();
    if (extLower == 'pdf') {
      sizeStr = "2.4 MB";
    } else if (extLower == 'png') {
      sizeStr = "419 kB";
    } else if (extLower == 'jpg' || extLower == 'jpeg') {
      sizeStr = "850 kB";
    } else if (extLower == 'mp3') {
      sizeStr = "4.1 MB";
    } else if (extLower == 'docx' || extLower == 'doc') {
      sizeStr = "84 kB";
    } else if (extLower == 'zip') {
      sizeStr = "12.5 MB";
    }

    final String avatarUrl = ApiService.getImageUrl(avatar);
    final bool hasAvatar = avatarUrl.isNotEmpty;

    // Define state variables here so they persist perfectly across local StatefulBuilder rebuilds!
    bool isDownloading = false;
    bool isCancelled = false;
    double progress = 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: appColor(context).grey100,
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
            child: hasAvatar
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 14,
                  ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.58,
          ),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topRight: const Radius.circular(20),
              bottomRight: const Radius.circular(20),
              bottomLeft: const Radius.circular(20),
              topLeft: isOutgoing
                  ? const Radius.circular(20)
                  : const Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isForwarded) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scaleX: -1,
                      child: Icon(
                        Icons.reply_rounded,
                        size: 13,
                        color: isOutgoing
                            ? appColor(context).white.withValues(alpha: 0.7)
                            : appColor(
                                context,
                              ).secondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Forwarded",
                      style: fontStyle.clashDisplayRegular10.italic().textColor(
                        isOutgoing
                            ? appColor(context).white.withValues(alpha: 0.7)
                            : appColor(
                                context,
                              ).secondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        Future<void> downloadAndOpen() async {
                          if (url == null || url.isEmpty) return;

                          setState(() {
                            isDownloading = true;
                            isCancelled = false;
                            progress = 0.0;
                          });

                          try {
                            final absoluteUrl = ApiService.getImageUrl(url);
                            final dio = Dio();
                            final cancelToken = CancelToken();
                            final dir = await getTemporaryDirectory();
                            final sanitizedFileName = resolvedFileName
                                .replaceAll(RegExp(r'[^\w\.\-]'), '_');
                            final savePath = '${dir.path}/$sanitizedFileName';

                            final downloadFuture = dio.download(
                              absoluteUrl,
                              savePath,
                              cancelToken: cancelToken,
                            );

                            for (int i = 1; i <= 20; i++) {
                              if (isCancelled) {
                                cancelToken.cancel();
                                return;
                              }
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              if (isCancelled) {
                                cancelToken.cancel();
                                return;
                              }
                              setState(() {
                                progress = i / 20.0;
                              });
                            }

                            await downloadFuture;

                            if (isCancelled) return;

                            setState(() {
                              isDownloading = false;
                            });

                            final uri = Uri.file(savePath);
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (!isCancelled) {
                              debugPrint(
                                "Error downloading/opening document: $e",
                              );
                              try {
                                final absoluteUrl = ApiService.getImageUrl(url);
                                final remoteUri = Uri.parse(absoluteUrl);
                                await launchUrl(
                                  remoteUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (err) {
                                debugPrint("Error launching remote URL: $err");
                              }
                            }
                            setState(() {
                              isDownloading = false;
                            });
                          }
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isOutgoing
                                    ? appColor(
                                        context,
                                      ).white.withValues(alpha: 0.15)
                                    : appColor(
                                        context,
                                      ).black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    color: textColor.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    extension,
                                    style: fontStyle.clashDisplayBold10
                                        .copyWith(fontSize: 7)
                                        .textColor(
                                          textColor.withValues(alpha: 0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isOutgoing) ...[
                                    Text(
                                      senderName,
                                      style: fontStyle.clashDisplayBold12
                                          .textColor(
                                            appColor(context).secondary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    resolvedFileName.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: fontStyle.clashDisplayBold12
                                        .textColor(textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "$extension • $sizeStr",
                                    style: fontStyle.clashDisplayMedium10
                                        .textColor(subtitleColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: isDownloading
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isCancelled = true;
                                          isDownloading = false;
                                        });
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 2.5,
                                            backgroundColor: textColor
                                                .withValues(alpha: 0.15),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  isOutgoing
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                          ),
                                          Icon(
                                            Icons.close,
                                            color: textColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: downloadAndOpen,
                                      child: Icon(
                                        Icons.download_rounded,
                                        color: textColor.withValues(alpha: 0.8),
                                        size: 22,
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Text(
                      time,
                      style: fontStyle.clashDisplayMedium10.textColor(
                        subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isOutgoing) ...[const SizedBox(width: 8), _buildGreenTick(context)],
      ],
    );
  }

  Widget _buildAudioBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String senderName,
    String avatar, {
    bool isForwarded = false,
  }) {
    return VoiceMessageBubble(
      url: url,
      isOutgoing: isOutgoing,
      avatarUrl: avatar,
      time: time,
      isForwarded: isForwarded,
    );
  }

  Widget _buildStickerBubble(
    BuildContext context,
    String? url,
    String time,
    bool isOutgoing,
    String senderName,
    String avatar, {
    bool isForwarded = false,
  }) {
    final String imageUrl = ApiService.getImageUrl(url);
    final String avatarUrl = ApiService.getImageUrl(avatar);
    final bool hasAvatar = avatarUrl.isNotEmpty;

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: appColor(context).grey100,
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
            child: hasAvatar
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 14,
                  ),
          ),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (isForwarded) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scaleX: -1,
                    child: Icon(
                      Icons.reply_rounded,
                      size: 13,
                      color: appColor(context).textMediumGrey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Forwarded",
                    style: fontStyle.clashDisplayRegular10.italic().textColor(
                      appColor(context).textMediumGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 150,
                    height: 150,
                    color: Colors.transparent,
                    child: Image.network(
                      imageUrl,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: appColor(context).grey400,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (isOutgoing) ...[const SizedBox(width: 8), _buildGreenTick(context)],
      ],
    );
  }

  Widget _buildStatusBubble(
    BuildContext context, {
    required String asset,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color bgColor,
    required String time,
    bool isOutgoing = true,
    String? avatar,
  }) {
    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: appColor(context).grey100,
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(ApiService.getImageUrl(avatar))
                : null,
            child: (avatar != null && avatar.isNotEmpty)
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 14,
                  ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isOutgoing ? 40 : 0,
              right: isOutgoing ? 0 : 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: fontStyle.clashDisplaySemiBold12
                            .textColor(titleColor)
                            .copyWith(fontStyle: ui.FontStyle.italic),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).black.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          time,
                          style: fontStyle.clashDisplayMedium10.textColor(
                            appColor(context).grey400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOutgoing) ...[const SizedBox(width: 8), _buildGreenTick(context)],
      ],
    );
  }

  /// Integrated Footer Composer incorporating real interactive TextFields and conditional action bars
  Widget _buildComposer(BuildContext context, GroupChatController controller) {
    if (controller.isLoading || controller.userId == null) {
      return const SizedBox.shrink();
    }
    if (controller.isSuspended) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: appColor(context).white,
          border: Border(
            top: BorderSide(color: appColor(context).grey100, width: 1),
          ),
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Center(
              child: Text(
                "This group has been suspended by admin",
                style: fontStyle.clashDisplayMedium14.textColor(
                  Colors.red.shade800,
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (!controller.isUserMemberOfGroup) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: appColor(context).white,
          border: Border(
            top: BorderSide(color: appColor(context).grey100, width: 1),
          ),
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Center(
              child: Text(
                "You are no longer a member of this group",
                style: fontStyle.clashDisplayMedium14.textColor(
                  Colors.red.shade800,
                ),
              ),
            ),
          ),
        ),
      );
    }

    bool isAttachmentOpen = false;
    const bool isNewChat = false; // Groups usually start as established
    bool isRecording = false;
    bool isRecordingPaused = false;
    int recordingSeconds = 0;
    int recordingTicks = 0;
    Timer? recordingTimer;
    AudioRecorder? audioRecorder;
    String? recordedFilePath;

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        Future<void> startRecording() async {
          try {
            audioRecorder ??= AudioRecorder();
            if (await audioRecorder!.hasPermission()) {
              final Directory tempDir = await getTemporaryDirectory();
              recordedFilePath =
                  '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

              await audioRecorder!.start(
                const RecordConfig(encoder: AudioEncoder.aacLc),
                path: recordedFilePath!,
              );

              recordingSeconds = 0;
              recordingTicks = 0;
              recordingTimer?.cancel();
              recordingTimer = Timer.periodic(
                const Duration(milliseconds: 100),
                (timer) {
                  setState(() {
                    recordingTicks++;
                    if (recordingTicks % 10 == 0) {
                      recordingSeconds++;
                    }
                  });
                },
              );

              setState(() {
                isRecording = true;
                isRecordingPaused = false;
              });
            } else {
              ToastHelper.showToast(
                context,
                "Microphone permission is required to record voice messages.",
              );
            }
          } catch (e) {
            debugPrint("Error starting recording: $e");
          }
        }

        Future<void> pauseRecording() async {
          try {
            if (audioRecorder != null && isRecording && !isRecordingPaused) {
              await audioRecorder!.pause();
              recordingTimer?.cancel();
              setState(() {
                isRecordingPaused = true;
              });
            }
          } catch (e) {
            debugPrint("Error pausing recording: $e");
          }
        }

        Future<void> resumeRecording() async {
          try {
            if (audioRecorder != null && isRecording && isRecordingPaused) {
              await audioRecorder!.resume();
              recordingTimer = Timer.periodic(
                const Duration(milliseconds: 100),
                (timer) {
                  setState(() {
                    recordingTicks++;
                    if (recordingTicks % 10 == 0) {
                      recordingSeconds++;
                    }
                  });
                },
              );
              setState(() {
                isRecordingPaused = false;
              });
            }
          } catch (e) {
            debugPrint("Error resuming recording: $e");
          }
        }

        Future<void> sendRecording() async {
          try {
            recordingTimer?.cancel();
            if (audioRecorder != null && isRecording) {
              final path = await audioRecorder!.stop();
              setState(() {
                isRecording = false;
                isRecordingPaused = false;
                recordingSeconds = 0;
                recordingTicks = 0;
              });
              if (path != null && path.isNotEmpty) {
                await controller.sendMediaMessage(
                  path,
                  "voice_${DateTime.now().millisecondsSinceEpoch}.m4a",
                  "audio",
                  content: "Voice Message",
                );
              }
            }
          } catch (e) {
            debugPrint("Error sending recording: $e");
          }
        }

        Future<void> discardRecording() async {
          try {
            recordingTimer?.cancel();
            if (audioRecorder != null && isRecording) {
              await audioRecorder!.stop();
              setState(() {
                isRecording = false;
                isRecordingPaused = false;
                recordingSeconds = 0;
                recordingTicks = 0;
              });
              try {
                if (recordedFilePath != null) {
                  final file = File(recordedFilePath!);
                  if (await file.exists()) {
                    await file.delete();
                  }
                }
              } catch (_) {}
            }
          } catch (e) {
            debugPrint("Error discarding recording: $e");
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: appColor(context).white,
            border: Border(
              top: BorderSide(color: appColor(context).grey100, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.selectedReplyMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: appColor(context).secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: appColor(context).secondary,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.selectedReplyMessage!["sender"]
                                      ?.toString() ??
                                  "",
                              style: fontStyle.clashDisplayBold12.textColor(
                                appColor(context).secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              controller.selectedReplyMessage!["text"]
                                      ?.toString() ??
                                  "",
                              style: fontStyle.clashDisplayRegular14.textColor(
                                appColor(context).black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.selectReplyMessage(null),
                        child: Icon(
                          Icons.close_rounded,
                          color: appColor(context).grey500,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isRecording) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: appColor(context).white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: appColor(context).secondary,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDuration(Duration(seconds: recordingSeconds)),
                            style: fontStyle.clashDisplayBold18.textColor(
                              appColor(context).secondary,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(15, (index) {
                              final List<double> baseHeights = [
                                6.0,
                                14.0,
                                20.0,
                                12.0,
                                16.0,
                                10.0,
                                14.0,
                                20.0,
                                12.0,
                                16.0,
                                10.0,
                                14.0,
                                8.0,
                                12.0,
                                10.0,
                              ];
                              final int shift = isRecordingPaused
                                  ? 0
                                  : recordingTicks;
                              final double h =
                                  baseHeights[(index + shift) %
                                      baseHeights.length];
                              return Container(
                                width: 3,
                                height: isRecordingPaused ? 4.0 : h,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: appColor(context).grey400,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: appColor(context).black54,
                              size: 26,
                            ),
                            onPressed: discardRecording,
                          ),
                          IconButton(
                            icon: Icon(
                              isRecordingPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: appColor(context).secondary,
                              size: 32,
                            ),
                            onPressed: isRecordingPaused
                                ? resumeRecording
                                : pauseRecording,
                          ),
                          GestureDetector(
                            onTap: sendRecording,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: appColor(context).secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.send_rounded,
                                color: appColor(context).white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        cursorColor: appColor(context).primary,
                        style: fontStyle.clashDisplayRegular14.textColor(
                          appColor(context).black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Type here...",
                          hintStyle: fontStyle.clashDisplayRegular14.textColor(
                            appColor(context).grey400,
                          ),
                          filled: true,
                          fillColor: appColor(context).grey50,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: appColor(context).grey200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: appColor(context).secondary,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Transform.rotate(
                      angle: -0.2,
                      child: GestureDetector(
                        onTap: () => controller.sendMessage(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Image.asset(
                            ImageAssets.send,
                            width: 22,
                            height: 22,
                            color: appColor(context).secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isNewChat && !controller.isSuspended) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              controller.pickCameraMedia(context: context),
                          child: Image.asset(
                            ImageAssets.cam,
                            width: 22,
                            height: 22,
                            color: appColor(context).black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showStickersBottomSheet(context),
                          child: Image.asset(
                            ImageAssets.stickers,
                            width: 22,
                            height: 22,
                            color: appColor(context).black87,
                          ),
                        ),
                        GestureDetector(
                          onLongPress: startRecording,
                          onTap: () {
                            ToastHelper.showToast(
                              context,
                              "Long-press to record voice message!",
                            );
                          },
                          child: Image.asset(
                            ImageAssets.recorder,
                            width: 22,
                            height: 22,
                            color: appColor(context).black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isAttachmentOpen = !isAttachmentOpen;
                            });
                          },
                          child: Image.asset(
                            isAttachmentOpen
                                ? ImageAssets.clipActive
                                : ImageAssets.paperclip,
                            width: 22,
                            height: 22,
                            color: isAttachmentOpen
                                ? null
                                : appColor(context).black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAttachmentOpen) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAttachmentOption(
                            context,
                            title: "Gallery",
                            asset: ImageAssets.gallery,
                            color: Colors.purple.shade700,
                            onTap: () async {
                              setState(() {
                                isAttachmentOpen = false;
                              });
                              await controller.pickMedia(context);
                            },
                          ),
                          _buildAttachmentOption(
                            context,
                            title: "Document",
                            asset: ImageAssets.file,
                            color: Colors.blue.shade700,
                            onTap: () async {
                              setState(() {
                                isAttachmentOpen = false;
                              });
                              await controller.pickDocument(context: context);
                            },
                          ),
                          // _buildAttachmentOption(
                          //   context,
                          //   title: "Location",
                          //   asset: ImageAssets.map,
                          //   color: Colors.green.shade800,
                          //   onTap: () async {
                          //     setState(() {
                          //       isAttachmentOpen = false;
                          //     });
                          //     await controller.sendLocation();
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required String title,
    required String asset,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: appColor(context).white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: appColor(context).black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(asset, width: 22, height: 22, color: color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: fontStyle.clashDisplayBold12.textColor(
              appColor(context).black,
            ),
          ),
        ],
      ),
    );
  }

  void _showStickersBottomSheet(BuildContext context) {
    final chatController = Provider.of<GroupChatController>(
      context,
      listen: false,
    );
    chatController.fetchStickers();

    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String activeTab = "Stickers";
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ChangeNotifierProvider<GroupChatController>.value(
              value: chatController,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            activeTab,
                            style: fontStyle.clashDisplayBold18.textColor(
                              appColor(context).black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: appColor(context).grey100,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: appColor(context).grey500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Chips Row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                activeTab = "Stickers";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: activeTab == "Stickers"
                                    ? appColor(context).secondary
                                    : appColor(context).grey100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Stickers",
                                style: fontStyle.clashDisplaySemiBold12
                                    .textColor(
                                      activeTab == "Stickers"
                                          ? appColor(context).white
                                          : appColor(context).black,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                activeTab = "Emojis";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: activeTab == "Emojis"
                                    ? appColor(context).secondary
                                    : appColor(context).grey100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Emojis",
                                style: fontStyle.clashDisplaySemiBold12
                                    .textColor(
                                      activeTab == "Emojis"
                                          ? appColor(context).white
                                          : appColor(context).black,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: activeTab == "Stickers"
                            ? Consumer<GroupChatController>(
                                builder: (context, controller, child) {
                                  if (controller.isLoadingStickers) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              appColor(context).secondary,
                                            ),
                                      ),
                                    );
                                  }

                                  final stickers = controller.stickers;
                                  if (stickers.isEmpty) {
                                    return Center(
                                      child: Text(
                                        "No stickers available.",
                                        style: fontStyle.clashDisplayMedium12
                                            .textColor(
                                              appColor(context).grey400,
                                            ),
                                      ),
                                    );
                                  }

                                  return GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                        ),
                                    itemCount: stickers.length,
                                    itemBuilder: (context, index) {
                                      final sticker = stickers[index];
                                      final relativePath =
                                          sticker['sticker_image'] ??
                                          sticker['file_url'] ??
                                          "";
                                      final imageUrl = ApiService.getImageUrl(
                                        relativePath,
                                      );

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          controller.sendStickerMessage(
                                            relativePath,
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: appColor(context).grey50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                              loadingBuilder:
                                                  (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: appColor(
                                                      context,
                                                    ).grey400,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            : Consumer<GroupChatController>(
                                builder: (context, controller, child) {
                                  return GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 7,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                    itemCount: _emojisList.length,
                                    itemBuilder: (context, index) {
                                      final emoji = _emojisList[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          final tempText =
                                              controller.messageController.text;
                                          controller.messageController.text =
                                              emoji;
                                          controller.sendMessage();
                                          controller.messageController.text =
                                              tempText;
                                        },
                                        child: Center(
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 28,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showClearChatConfirmation(
    BuildContext outerContext,
    GroupChatController controller,
  ) {
    showDialog(
      context: outerContext,
      builder: (context) {
        bool isClearing = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: appColor(context).white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: appColor(context).secondary,
                  width: 1.5,
                ),
              ),
              title: Text(
                "Clear Chat?",
                style: fontStyle.clashDisplayBold18.textColor(
                  appColor(context).black,
                ),
              ),
              content: Text(
                "Are you sure you want to clear all messages in this group? This action cannot be undone.",
                style: fontStyle.clashDisplayMedium14.textColor(
                  appColor(context).textSecondary,
                ),
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: isClearing ? null : () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: fontStyle.clashDisplayMedium14.textColor(
                      appColor(context).textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isClearing
                      ? null
                      : () async {
                          setState(() {
                            isClearing = true;
                          });
                          final success = await controller.clearChat();
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ToastHelper.showToast(
                                context,
                                "Group chat cleared successfully",
                              );
                            } else {
                              ToastHelper.showToast(
                                context,
                                "Failed to clear group chat",
                              );
                            }
                          }
                        },
                  child: isClearing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Clear",
                          style: fontStyle.clashDisplayBold14.textColor(
                            appColor(context).secondary,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteChatConfirmation(
    BuildContext outerContext,
    GroupChatController controller,
  ) {
    showDialog(
      context: outerContext,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: appColor(context).white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: appColor(context).secondary,
                  width: 1.5,
                ),
              ),
              title: Text(
                "Delete Group Chat?",
                style: fontStyle.clashDisplayBold18.textColor(
                  appColor(context).black,
                ),
              ),
              content: Text(
                "Are you sure you want to delete this group chat? All messages and history will be permanently deleted.",
                style: fontStyle.clashDisplayMedium14.textColor(
                  appColor(context).textSecondary,
                ),
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: fontStyle.clashDisplayMedium14.textColor(
                      appColor(context).textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() {
                            isDeleting = true;
                          });
                          final success = await controller.deleteChat();
                          if (context.mounted) {
                            Navigator.pop(context); // Close warning dialog
                            if (success) {
                              // Pop the chat screen to return to the home screen
                              Navigator.pop(outerContext);
                              // Refresh the homescreen recent chats
                              try {
                                Provider.of<HomeScreenController>(
                                  outerContext,
                                  listen: false,
                                ).fetchRecentChats(updateLoadingState: false);
                              } catch (_) {}
                            } else {
                              ToastHelper.showToast(
                                context,
                                "Failed to delete group chat",
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Delete",
                          style: fontStyle.clashDisplayBold14.textColor(
                            appColor(context).secondary,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportDialog(
    BuildContext outerContext,
    GroupChatController controller,
    String groupName,
  ) {
    String selectedReason = "Select a reason";
    final TextEditingController descriptionController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: outerContext,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: appColor(context).white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Report Group",
                            style: fontStyle.clashDisplayBold20.textColor(
                              appColor(context).darkText,
                            ),
                          ),
                          GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              color: appColor(context).textSecondary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      RichText(
                        text: TextSpan(
                          style: fontStyle.clashDisplayRegular14.textColor(
                            appColor(context).textSecondary,
                          ),
                          children: [
                            const TextSpan(text: "You are reporting "),
                            TextSpan(
                              text: groupName,
                              style: fontStyle.clashDisplayBold14.textColor(
                                appColor(context).black,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ". Please tell us why you are reporting this group.",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Reason Dropdown Label
                      Text(
                        "Reason for reporting",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).textMediumGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dropdown Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: appColor(context).white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: appColor(context).grey300,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedReason,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: appColor(context).secondary,
                            ),
                            style: fontStyle.clashDisplayMedium14.textColor(
                              selectedReason == "Select a reason"
                                  ? appColor(context).textGrey
                                  : appColor(context).black,
                            ),
                            dropdownColor: appColor(context).white,
                            onChanged: isSubmitting
                                ? null
                                : (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedReason = newValue;
                                      });
                                    }
                                  },
                            items:
                                <String>[
                                  "Select a reason",
                                  "Spam",
                                  "Harassment",
                                  "Inappropriate Content",
                                  "Other",
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Description Label
                      Text(
                        "Description (Optional)",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).textMediumGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description Textarea Container
                      Container(
                        decoration: BoxDecoration(
                          color: appColor(context).white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: appColor(context).grey300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: descriptionController,
                          enabled: !isSubmitting,
                          maxLines: 4,
                          minLines: 4,
                          style: fontStyle.clashDisplayRegular14.textColor(
                            appColor(context).black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Provide more details...",
                            hintStyle: fontStyle.clashDisplayRegular14
                                .textColor(appColor(context).textGrey),
                            contentPadding: const EdgeInsets.all(12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Button Actions Row
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColor(context).grey100,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style: fontStyle.clashDisplayBold14.textColor(
                                  appColor(context).textMediumGrey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Submit Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColor(context).secondary,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (selectedReason == "Select a reason") {
                                        ToastHelper.showToast(
                                          context,
                                          "Please select a reason for reporting",
                                        );
                                        return;
                                      }
                                      setState(() {
                                        isSubmitting = true;
                                      });
                                      final success = await controller
                                          .reportGroup(
                                            reason: selectedReason,
                                            description: descriptionController
                                                .text
                                                .trim(),
                                          );
                                      if (context.mounted) {
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                        if (success) {
                                          ToastHelper.showToast(
                                            context,
                                            "Report submitted successfully",
                                          );
                                          Navigator.pop(context);
                                        } else {
                                          ToastHelper.showToast(
                                            context,
                                            "Failed to submit report",
                                          );
                                        }
                                      }
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Submit Report",
                                      style: fontStyle.clashDisplayBold14
                                          .textColor(appColor(context).white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

const List<String> _emojisList = [
  // Smileys & Emotion
  '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
  '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
  '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
  '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
  '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
  '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
  '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
  '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
  '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈',
  '👿', '👹', '👺', '🤡', '💩', '👻', '💀', '☠️', '👽', '👾',
  '🤖', '🎃', '😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿',
  '😾',
  // Hearts & Hands
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
  '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟',
  '👍', '👎', '✊', '👊', '🤛', '🤜', '🤝', '🙌', '👏', '🙏',
  '✍️', '💅', '🤳', '💪', '🦾', '🦵', '🦿', '👂', '🦻', '👃',
  '🧠', '🦷', '🦴', '👀', '👁️', '👅', '👄', '💋', '🩸',
  // Animals & Nature
  '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
  '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒',
  '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇',
  '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
  '🦟', '🦗', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎', '🐙', '🦑',
  '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊',
  '🐅', '🐆', '🦓', '🦍', '🦧', '🦣', '🐘', '🦛', '🦏', '🐪',
  '🐫', '🦒', '🦘', '🦬', '🐃', '🐂', '🐄', '🐎', '🐖', '🐏',
  '🐑', '🦙', '🐐', '🦌', '🐕', '🐩', '🦮', '🐕‍🦺', '🐈', '🐈‍⬛',
  '🐓', '🦃', '🦚', '🦜', '🦢', '🦩', '🕊️', '🐇', '🦝', '🦨',
  '🦡', '🦫', '🦦', '🦥', '🐁', '🐀', '🐿️', '🦔', '🐾', '🐉',
  '🐲', '🌵', '🎄', '🌲', '🌳', '🌴', '🌱', '🌿', '☘️', '🍀',
  '🍁', '🍂', '🍃',
  // Food & Drink
  '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐',
  '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑',
  '🥦', '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕', '🧅', '🧄',
  '🍄', '🥜', '🌰', '🍞', '🥐', '🥖', '🥨', '🥯', '🥞',
  '🫑', '🧀', '🍖', '🍗', '🥩', '🥓', '🍔', '🍟', '🍕', '🌭',
  '🥪', '🌮', '🌯', '🫔', '🥙', '🧆', '🍳', '🥘', '🍲', '🫕',
  '🥣', '🥗', '🍿', '🍟', '🧂', '🥫', '🍱', '🍘', '🍙', '🍚',
  '🍛', '🍜', '🍝', '🍠', '🍢', '🍣', '🍤', '🍥', '🥮', '🍡',
  '🥟', '🥠', '🥡', '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰',
  '🧁', '🥧', '🍫', '🍬', '🍭', '🍮', '🍯', '🍼', '🥛', '☕',
  '🫖', '🍵', '🍶', '🍾', '🍷', '🍸', '🍹', '🍺', '🍻', '🥂',
  '🥃', '🥤', '🧋', '🧃', '🧉', '🧊',
];
