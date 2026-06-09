import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:shieldconnect_app/model/settings_model.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';
import 'package:shieldconnect_app/controller/personal_chat_controller.dart';
import 'package:shieldconnect_app/controller/group_chat_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/linkified_text.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/view/contact_info_screen.dart';
import 'package:shieldconnect_app/view/group_info_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';
import 'package:shieldconnect_app/view/media_viewer_screen.dart';
import 'package:shieldconnect_app/view/voice_message_bubble.dart';
import 'package:shieldconnect_app/view/forward_screen.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/view/message_info_bottom_sheet.dart';
import 'package:shieldconnect_app/view/typing_indicator_bubble.dart';

class ChatScreen extends StatelessWidget {
  final String userName;
  final bool isNewChat; // Enables conditionality for blank/new chat structures
  final bool isGroup;

  final bool isRequest;
  final String? recipientId;
  final bool isArchived;
  final bool isFavorite;

  ChatScreen({
    super.key,
    required this.userName,
    this.isNewChat = false,
    this.isGroup = false,
    this.isRequest = false,
    this.recipientId,
    this.isArchived = false,
    this.isFavorite = false,
  });

  final Map<String, GlobalKey> _messageKeys = {};

  Future<void> _scrollToMessage(
    PersonalChatController controller,
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
    return ChangeNotifierProvider<PersonalChatController>(
      create: (context) => PersonalChatController()
        ..init(
          recipientId ?? userName,
          isGroup: isGroup,
          isRequest: isRequest,
          isNewChat: isNewChat,
          isFavorite: isFavorite,
        ),
      child: Consumer<PersonalChatController>(
        builder: (context, controller, child) {
          final String titleName =
              controller.headerDetails?['name'] ?? userName;
          final bool showProfilePic = isGroup || (controller.headerDetails?['show_profile_pic'] as bool? ?? true);
          final String? avatarUrl = showProfilePic ? (controller.headerDetails?['avatar'] as String?) : null;
          final bool showLastSeen = isGroup || (controller.headerDetails?['show_last_seen'] as bool? ?? true);
          final String statusText =
              (showLastSeen && (isGroup || controller.relationshipStatus == 'accepted'))
              ? (controller.headerDetails?['status'] ??
                    (isGroup ? '' : 'Offline'))
              : '';

          return PopScope(
            canPop: !controller.isAttachmentOpen && !controller.isRecording,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (controller.isAttachmentOpen) {
                controller.setAttachmentOpen(false);
              } else if (controller.isRecording) {
                controller.onCancelRecording?.call();
              }
            },
            child: Scaffold(
              backgroundColor: appColor(context).white,
              body: SafeArea(
                child: Column(
                  children: [
                    // 1. Aesthetic Chat Header
                    _buildHeader(
                      context,
                      titleName,
                      avatarUrl,
                      statusText,
                      controller,
                    ),

                    // 2. Dynamic Chat Body
                    Expanded(
                      child: Container(
                        width: double.infinity,
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
                            : (controller.isRequest
                                  ? _buildRequestChatView(
                                      context,
                                      titleName,
                                      avatarUrl,
                                      controller,
                                    )
                                  : (controller.isNewChat
                                        ? _buildNewChatWelcome(
                                            context,
                                            titleName,
                                            avatarUrl,
                                          )
                                        : ListView.builder(
                                            controller:
                                                controller.scrollController,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount:
                                                controller.messages.length +
                                                (controller.isRecipientTyping
                                                    ? 1
                                                    : 0),
                                            itemBuilder: (context, index) {
                                              if (index ==
                                                  controller.messages.length) {
                                                return const Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: 12.0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      TypingIndicatorBubble(),
                                                    ],
                                                  ),
                                                );
                                              }
                                              final msg =
                                                  controller.messages[index];
                                              final String msgId =
                                                  msg['id']?.toString() ?? '';
                                              final bool isFirst =
                                                  controller.messages
                                                      .indexWhere(
                                                        (m) =>
                                                            m['id']
                                                                ?.toString() ==
                                                            msgId,
                                                      ) ==
                                                  index;
                                              final key =
                                                  (msgId.isNotEmpty && isFirst)
                                                  ? _messageKeys.putIfAbsent(
                                                      msgId,
                                                      () => GlobalKey(),
                                                    )
                                                  : null;
                                              final String modStatus =
                                                  msg['moderation_status'] ??
                                                  'Approved';
                                              final bool isOutgoing =
                                                  msg['isOutgoing'] ?? false;
                                              final String text =
                                                  msg['text'] ?? '';
                                              final String time =
                                                  msg['time'] ?? '';
                                              final String? createdAt =
                                                  msg['createdAt'];

                                              // Calculate if we need to show the date header
                                              bool showDateHeader = false;
                                              String dateHeaderStr = "";
                                              if (createdAt != null) {
                                                final String currentDayStr =
                                                    DateHelper.formatMessageDate(
                                                      createdAt,
                                                    );
                                                if (index == 0) {
                                                  showDateHeader = true;
                                                  dateHeaderStr = currentDayStr;
                                                } else {
                                                  final prevMsg = controller
                                                      .messages[index - 1];
                                                  final String? prevCreatedAt =
                                                      prevMsg['createdAt'];
                                                  if (prevCreatedAt != null) {
                                                    final String prevDayStr =
                                                        DateHelper.formatMessageDate(
                                                          prevCreatedAt,
                                                        );
                                                    if (currentDayStr !=
                                                        prevDayStr) {
                                                      showDateHeader = true;
                                                      dateHeaderStr =
                                                          currentDayStr;
                                                    }
                                                  } else {
                                                    showDateHeader = true;
                                                    dateHeaderStr =
                                                        currentDayStr;
                                                  }
                                                }
                                              }

                                              final String? moderatedBy =
                                                  msg['moderated_by'] is Map
                                                  ? (msg['moderated_by']['name']
                                                            ?.toString() ??
                                                        msg['moderated_by']['_id']
                                                            ?.toString())
                                                  : msg['moderated_by']
                                                        ?.toString();

                                              Widget messageWidget;
                                              if (modStatus == 'Approved' &&
                                                  moderatedBy != null &&
                                                  moderatedBy != 'RoseShield') {
                                                if (isOutgoing) {
                                                  messageWidget = Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    child: _buildStatusBubble(
                                                      context,
                                                      asset: ImageAssets.ok,
                                                      title:
                                                          "Your message is now approved",
                                                      subtitle: text,
                                                      titleColor: const Color(
                                                        0xFF2E7D32,
                                                      ),
                                                      bgColor: const Color(
                                                        0xFFE8F5E9,
                                                      ),
                                                      time: time,
                                                      isOutgoing: isOutgoing,
                                                      imageUrl: msg['url']
                                                          ?.toString(),
                                                    ),
                                                  );
                                                } else {
                                                  final String msgType =
                                                      msg['type'] ?? 'text';
                                                  final String? fileUrl =
                                                      msg['url'];
                                                  final String? avatarPath = showProfilePic
                                                      ? (msg['avatar']?.toString() ?? avatarUrl)
                                                      : null;

                                                  messageWidget = Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: _buildMediaMessageBubble(
                                                      context,
                                                      type: msgType,
                                                      text: text,
                                                      time: time,
                                                      url: fileUrl,
                                                      isOutgoing: isOutgoing,
                                                      avatarUrl: avatarPath,
                                                      fileName: msg['file_name']
                                                          ?.toString(),
                                                      replyTo: msg['replyTo']
                                                          ?.toString(),
                                                      replyToSender:
                                                          msg['replyToSender']
                                                              ?.toString(),
                                                      replyToType:
                                                          msg['replyToType']
                                                              ?.toString(),
                                                      replyToUrl:
                                                          msg['replyToUrl']
                                                              ?.toString(),
                                                      parentMessageId:
                                                          msg['parent_message_id']
                                                              ?.toString(),
                                                      onReplyTap:
                                                          (parentMsgId) =>
                                                              _scrollToMessage(
                                                                controller,
                                                                parentMsgId,
                                                              ),
                                                      isForwarded:
                                                          msg['is_forwarded'] ==
                                                          true,
                                                      isEdited:
                                                          msg['isEdited'] ==
                                                          true,
                                                      status:
                                                          msg['status'] ??
                                                          'sent',
                                                    ),
                                                  );
                                                }
                                              } else if (modStatus ==
                                                  'Moderation') {
                                                if (isOutgoing) {
                                                  messageWidget = Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    child: _buildStatusBubble(
                                                      context,
                                                      asset: ImageAssets.pause,
                                                      title:
                                                          "Your message is under review",
                                                      subtitle:
                                                          "We're reviewing your message to keep everyone safe and respectful.",
                                                      titleColor: const Color(
                                                        0xFFE65100,
                                                      ),
                                                      bgColor: const Color(
                                                        0xFFFFF8E1,
                                                      ),
                                                      time: time,
                                                      isOutgoing: isOutgoing,
                                                    ),
                                                  );
                                                } else {
                                                  messageWidget =
                                                      const SizedBox.shrink();
                                                }
                                              } else if (modStatus ==
                                                  'Blocked') {
                                                if (isOutgoing) {
                                                  final bool isAppealing =
                                                      msg['isAppealing'] ==
                                                      true;
                                                  final bool appealFailed =
                                                      msg['appealFailed'] ==
                                                      true;
                                                  messageWidget = Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    child: _buildStatusBubble(
                                                      context,
                                                      asset: ImageAssets.appeal,
                                                      title:
                                                          "Your message is blocked",
                                                      subtitle:
                                                          "This message may contain inappropriate content that could make others uncomfortable.",
                                                      titleColor: const Color(
                                                        0xFFC62828,
                                                      ),
                                                      bgColor: const Color(
                                                        0xFFFFF2F2,
                                                      ),
                                                      time: time,
                                                      isOutgoing: isOutgoing,
                                                      messageId: msg['id']
                                                          ?.toString(),
                                                      isAppealing: isAppealing,
                                                      appealFailed:
                                                          appealFailed,
                                                    ),
                                                  );
                                                } else {
                                                  messageWidget =
                                                      const SizedBox.shrink();
                                                }
                                              } else {
                                                final String msgType =
                                                    msg['type'] ?? 'text';
                                                final String? fileUrl =
                                                    msg['url'];
                                                final String? avatarPath = showProfilePic
                                                    ? (msg['avatar']?.toString() ?? avatarUrl)
                                                    : null;

                                                messageWidget = Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: _buildMediaMessageBubble(
                                                    context,
                                                    type: msgType,
                                                    text: text,
                                                    time: time,
                                                    url: fileUrl,
                                                    isOutgoing: isOutgoing,
                                                    avatarUrl: avatarPath,
                                                    fileName: msg['file_name']
                                                        ?.toString(),
                                                    replyTo: msg['replyTo']
                                                        ?.toString(),
                                                    replyToSender:
                                                        msg['replyToSender']
                                                            ?.toString(),
                                                    replyToType:
                                                        msg['replyToType']
                                                            ?.toString(),
                                                    replyToUrl:
                                                        msg['replyToUrl']
                                                            ?.toString(),
                                                    parentMessageId:
                                                        msg['parent_message_id']
                                                            ?.toString(),
                                                    onReplyTap: (parentMsgId) =>
                                                        _scrollToMessage(
                                                          controller,
                                                          parentMsgId,
                                                        ),
                                                    isForwarded:
                                                        msg['is_forwarded'] ==
                                                        true,
                                                    isEdited:
                                                        msg['isEdited'] == true,
                                                    status:
                                                        msg['status'] ?? 'sent',
                                                  ),
                                                );
                                              }

                                              final itemWidget = showDateHeader
                                                  ? Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
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
                                                                    appColor(
                                                                      context,
                                                                    ).black,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        messageWidget,
                                                      ],
                                                    )
                                                  : messageWidget;

                                              final bool isSelected =
                                                  controller
                                                          .selectedMessageForOptions !=
                                                      null &&
                                                  controller
                                                          .selectedMessageForOptions!['id'] ==
                                                      msg['id'];
                                              final bool isHighlighted =
                                                  controller
                                                      .highlightedMessageId ==
                                                  msg['id'];

                                              return GestureDetector(
                                                key: key,
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onLongPress: () {
                                                  if (modStatus ==
                                                          'Moderation' ||
                                                      modStatus == 'Blocked' ||
                                                      msg['isDeleted'] ==
                                                          true) {
                                                    return;
                                                  }
                                                  controller
                                                      .selectMessageForOptions(
                                                        msg,
                                                      );
                                                },
                                                onTap: () {
                                                  if (controller
                                                          .selectedMessageForOptions !=
                                                      null) {
                                                    controller
                                                        .selectMessageForOptions(
                                                          null,
                                                        );
                                                  }
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  color: isSelected
                                                      ? appColor(
                                                          context,
                                                        ).secondary.withValues(
                                                          alpha: 0.12,
                                                        )
                                                      : (isHighlighted
                                                            ? appColor(context)
                                                                  .secondary
                                                                  .withValues(
                                                                    alpha: 0.22,
                                                                  )
                                                            : Colors
                                                                  .transparent),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  child: AbsorbPointer(
                                                    absorbing:
                                                        controller
                                                            .selectedMessageForOptions !=
                                                        null,
                                                    child: Dismissible(
                                                      key: Key(
                                                        'reply_${msg['id'] ?? index}',
                                                      ),
                                                      direction:
                                                          (modStatus ==
                                                                  'Moderation' ||
                                                              modStatus ==
                                                                  'Blocked' ||
                                                              msg['isDeleted'] ==
                                                                  true)
                                                          ? DismissDirection
                                                                .none
                                                          : DismissDirection
                                                                .startToEnd,
                                                      confirmDismiss:
                                                          (direction) async {
                                                            controller
                                                                .selectReplyMessage(
                                                                  msg,
                                                                );
                                                            return false;
                                                          },
                                                      background: Container(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        padding:
                                                            const EdgeInsets.only(
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
                                          ))),
                      ),
                    ),

                    // 3. Footer Toolbar / Consent Drawer
                    () {
                      if (controller.relationshipStatus == 'blocked') {
                        if (controller.blockedBy.contains(controller.userId)) {
                          return _buildBlockerPanel(
                            context,
                            controller,
                            titleName,
                          );
                        } else {
                          return _buildBlockedPanel(context, titleName);
                        }
                      } else if (controller.relationshipStatus == 'pending' &&
                          controller.requestedBy == controller.recipientId) {
                        return _buildRequestConsentPanel(
                          context,
                          controller,
                          titleName,
                        );
                      } else if (controller.isRequest) {
                        return _buildRequestConsentPanel(
                          context,
                          controller,
                          titleName,
                        );
                      } else {
                        return _buildComposer(context, controller);
                      }
                    }(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Displays large Welcome card for brand-new chat streams initiated from suggestions list
  Widget _buildNewChatWelcome(
    BuildContext context,
    String titleName,
    String? avatarUrl,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          // Large circular branding avatar seen centered on mockup
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColor(context).grey100,
              image: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(ApiService.getImageUrl(avatarUrl)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 54,
                  ),
          ),
          const SizedBox(height: 20),

          // Primary header name
          Text(
            titleName,
            style: fontStyle.clashDisplaySemiBold20.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 4),

          // Normalized descriptive email tagline
          Text(
            "${titleName.replaceAll(' ', '').toLowerCase()}@gmail.com",
            style: fontStyle.clashDisplayRegular14.textColor(
              appColor(context).grey600,
            ),
          ),
          const SizedBox(height: 24),

          // Reactive Follow Button Component
          _FollowButton(recipientId: recipientId ?? ""),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(
    BuildContext context,
    PersonalChatController controller,
  ) {
    final int totalMatches = controller.searchMatchMessageIds.length;
    final int currentMatchIndex = controller.currentSearchMatchIndex;
    final String countText = totalMatches > 0
        ? "${currentMatchIndex + 1} of $totalMatches"
        : "0 of 0";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appColor(context).secondary,
        border: Border(
          bottom: BorderSide(color: appColor(context).grey100, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => controller.toggleSearchActive(false),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              autofocus: true,
              style: fontStyle.clashDisplayMedium14.textColor(Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: fontStyle.clashDisplayRegular14.textColor(
                  Colors.white70,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) {
                controller.setSearchQuery(val);
              },
            ),
          ),
          if (controller.searchQuery.isNotEmpty) ...[
            Text(
              countText,
              style: fontStyle.clashDisplayMedium12.textColor(Colors.white),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (controller.searchMatchMessageIds.isNotEmpty) {
                  controller.prevSearchMatch();
                  final String? targetId = controller.currentMatchedMessageId;
                  if (targetId != null) {
                    await _scrollToMessage(controller, targetId);
                  }
                }
              },
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (controller.searchMatchMessageIds.isNotEmpty) {
                  controller.nextSearchMatch();
                  final String? targetId = controller.currentMatchedMessageId;
                  if (targetId != null) {
                    await _scrollToMessage(controller, targetId);
                  }
                }
              },
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
    bool isSearchActive,
    TextStyle normalStyle,
  ) {
    return LinkifiedText(
      text: text,
      style: normalStyle,
      query: query,
      isSearchActive: isSearchActive,
    );
  }

  /// Structuring navigation bar with profile avatars and conditional call routes
  Widget _buildHeader(
    BuildContext context,
    String titleName,
    String? avatarUrl,
    String statusText,
    PersonalChatController controller,
  ) {
    if (controller.isSearchActive) {
      return _buildSearchHeader(context, controller);
    }

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
                          isGroup: false,
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
                    Icons.arrow_forward_rounded,
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

          // Tap target area enclosing Avatar and Name linking to Contact / Group Info screens
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isGroup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<GroupChatController>(
                            create: (context) => GroupChatController()
                              ..init(
                                controller.recipientId ??
                                    recipientId ??
                                    userName,
                              ),
                            child: GroupInfoScreen(
                              groupName: titleName,
                              groupId:
                                  controller.recipientId ??
                                  recipientId ??
                                  userName,
                            ),
                          ),
                    ),
                  );
                } else {
                  final String recId =
                      controller.recipientId ?? recipientId ?? userName;
                  controller.fetchPersonalChatDetails(recId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<PersonalChatController>.value(
                            value: controller,
                            child: ContactInfoScreen(
                              name: titleName,
                              recipientId: recId,
                            ),
                          ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  // Circular mini avatar representing connection
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: appColor(context).grey100,
                    backgroundImage: isGroup
                        ? const NetworkImage(
                                "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                              )
                              as ImageProvider
                        : (avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(ApiService.getImageUrl(avatarUrl))
                                    as ImageProvider
                              : null),
                    child:
                        (isGroup || (avatarUrl != null && avatarUrl.isNotEmpty))
                        ? null
                        : Icon(
                            Icons.person,
                            color: appColor(context).secondary,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Contact Name Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titleName,
                          style: fontStyle.clashDisplaySemiBold16.textColor(
                            appColor(context).black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (statusText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: fontStyle.clashDisplayMedium10.textColor(
                              statusText == "Online"
                                  ? appColor(context).green
                                  : appColor(context).grey400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Conditional shortcuts - Omit action bars for non-connected personal chats
          if (isGroup || controller.relationshipStatus == 'accepted') ...[
            GestureDetector(
              onTap: () {
                final targetId = recipientId ?? controller.recipientId ?? '';
                context.read<CallManager>().startCall(
                  targetId,
                  titleName,
                  isVideo: false,
                  recipientAvatar: avatarUrl,
                  isGroup: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VoiceCallingScreen(
                          userName: titleName,
                          avatarUrl: avatarUrl,
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
                final targetId = recipientId ?? controller.recipientId ?? '';
                context.read<CallManager>().startCall(
                  targetId,
                  titleName,
                  isVideo: true,
                  recipientAvatar: avatarUrl,
                  isGroup: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoCallingScreen(userName: titleName),
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
            Theme(
              data: Theme.of(context).copyWith(
                splashColor: appColor(context).transparent,
                highlightColor: appColor(context).transparent,
              ),
              child: PopupMenuButton<String>(
                icon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.more_vert,
                    color: appColor(context).secondary,
                    size: 22,
                  ),
                ),
                padding: EdgeInsets.zero,
                color: appColor(context).white,
                surfaceTintColor: appColor(context).white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                offset: const Offset(
                  0,
                  46,
                ), // Places the card elegantly floating below the icon anchor
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
                    ).unarchiveChat(recipientId ?? userName);
                    if (success && context.mounted) {
                      ToastHelper.showToast(context, "Chat unarchived");
                      Provider.of<HomeScreenController>(
                        context,
                        listen: false,
                      ).fetchRecentChats(updateLoadingState: false);
                      Navigator.pop(context);
                    } else if (context.mounted) {
                      ToastHelper.showToast(
                        context,
                        "Failed to unarchive chat",
                      );
                    }
                  } else if (value == "Favorite" || value == "Unfavorite") {
                    final newFavStatus = !controller.isFavorite;
                    final success = await controller.toggleFavorite(
                      newFavStatus,
                    );
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
                  } else if (value == "Search") {
                    controller.toggleSearchActive(true);
                  } else if (value == "Report") {
                    _showReportDialog(context, controller, titleName);
                  } else if (value == "Clear Chat") {
                    _showClearChatConfirmation(context, controller);
                  } else if (value == "Delete Chat") {
                    _showDeleteChatConfirmation(context, controller);
                  } else if (value == "Block") {
                    await controller.blockUser(recipientId ?? userName);
                  }
                },
                itemBuilder: (BuildContext context) => [
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
                    "Search",
                    ImageAssets.searchIcon,
                  ),
                  _buildPopupMenuItem(context, "Block", ImageAssets.block),
                  _buildPopupMenuItem(context, "Report", ImageAssets.report),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog(
    BuildContext outerContext,
    PersonalChatController controller,
    String userName,
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
                            "Report Account",
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
                              text: userName,
                              style: fontStyle.clashDisplayBold14.textColor(
                                appColor(context).black,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ". Please tell us why you are reporting this account.",
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
                                          .reportUser(
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

  void _showClearChatConfirmation(
    BuildContext outerContext,
    PersonalChatController controller,
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
                "Are you sure you want to clear all messages in this chat? This action cannot be undone.",
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
                                "Chat cleared successfully",
                              );
                            } else {
                              ToastHelper.showToast(
                                context,
                                "Failed to clear chat",
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
    PersonalChatController controller,
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
                "Delete Chat?",
                style: fontStyle.clashDisplayBold18.textColor(
                  appColor(context).black,
                ),
              ),
              content: Text(
                "Are you sure you want to delete this chat? All messages and history will be permanently deleted.",
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
                                "Failed to delete chat",
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

  void _showDeleteConfirmation(
    BuildContext outerContext,
    PersonalChatController controller,
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

  void _showEditOverlay(
    BuildContext context,
    PersonalChatController controller,
  ) {
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

  /// Renders Outgoing text widgets matching custom corner curves + status badge overlays
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
    String status = 'sent',
    String? replyToType,
    String? replyToUrl,
  }) {
    final controller = Provider.of<PersonalChatController>(
      context,
      listen: false,
    );
    final isSearchActive = controller.isSearchActive;
    final searchQuery = controller.searchQuery;

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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
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
                                Row(
                                  children: [
                                    if (replyToType == 'image') ...[
                                      const Icon(
                                        Icons.photo_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                    ] else if (replyToType == 'sticker') ...[
                                      const Icon(
                                        Icons.emoji_emotions_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                    ] else if (replyToType == 'video') ...[
                                      const Icon(
                                        Icons.videocam_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                    ] else if (replyToType == 'audio') ...[
                                      const Icon(
                                        Icons.mic_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        (replyToType == 'image' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty ||
                                                    replyTo ==
                                                        'Check out this photo!'))
                                            ? "Photo"
                                            : (replyToType == 'video' &&
                                                  (replyTo == null ||
                                                      replyTo.isEmpty ||
                                                      replyTo ==
                                                          'Check out this video!'))
                                            ? "Video"
                                            : (replyToType == 'audio' &&
                                                  (replyTo == null ||
                                                      replyTo.isEmpty))
                                            ? "Voice Message"
                                            : (replyToType == 'sticker' &&
                                                  (replyTo == null ||
                                                      replyTo.isEmpty))
                                            ? "Sticker"
                                            : replyTo,
                                        style: fontStyle.clashDisplayRegular12
                                            .textColor(
                                              appColor(
                                                context,
                                              ).white.withValues(alpha: 0.95),
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
                          if ((replyToType == 'image' ||
                                  replyToType == 'sticker') &&
                              replyToUrl != null &&
                              replyToUrl.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                replyToUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                _buildHighlightedText(
                  context,
                  text,
                  searchQuery,
                  isSearchActive,
                  fontStyle.clashDisplayMedium14.textColor(
                    appColor(context).white,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      time,
                      style: fontStyle.clashDisplayMedium10.textColor(
                        appColor(context).white.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isEdited)
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
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildGreenTick(context, status: status),
      ],
    );
  }

  /// Renders high-fidelity vibrant green delivery tick mirroring zoom reference
  Widget _buildGreenTick(BuildContext context, {String status = 'sent'}) {
    if (status == 'read') {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: appColor(context).green,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.done_all_rounded, color: Colors.white, size: 11),
        ),
      );
    } else if (status == 'delivered') {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appColor(context).green, width: 1.5),
        ),
        child: Center(
          child: Icon(
            Icons.done_all_rounded,
            color: appColor(context).green,
            size: 11,
          ),
        ),
      );
    } else {
      return Icon(
        Icons.check_circle_outline,
        color: appColor(context).green,
        size: 18,
      );
    }
  }

  /// Custom Voice Call Outgoing Bubble block
  Widget _buildOutgoingVoiceCall(
    BuildContext context,
    String duration,
    String time,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 170,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appColor(context).secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appColor(context).white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      ImageAssets.outgoingCall,
                      width: 18,
                      height: 18,
                      color: appColor(context).secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Voice Call",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).white,
                        ),
                      ),
                      Text(
                        duration,
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: fontStyle.clashDisplayMedium10.textColor(
                  appColor(context).white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Adding alignment spacing for the right badge stack column alignment
        const SizedBox(width: 24),
      ],
    );
  }

  /// Unified status bubble constructor delivering dynamic 3D animal status overlays
  Widget _buildStatusBubble(
    BuildContext context, {
    required String asset,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color bgColor,
    required String time,
    bool isOutgoing = true,
    String? messageId,
    bool isAppealing = false,
    bool appealFailed = false,
    String? imageUrl,
  }) {
    final controller = Provider.of<PersonalChatController>(
      context,
      listen: false,
    );
    final bool showAppealButton =
        isOutgoing &&
        messageId != null &&
        title.toLowerCase().contains("blocked");

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isOutgoing ? 40 : 0,
              right: isOutgoing ? 0 : 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(asset, width: 48, height: 48, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: fontStyle.clashDisplaySemiBold14
                            .textColor(titleColor)
                            .copyWith(
                              fontStyle: ui.FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).black.withValues(alpha: 0.8),
                        ),
                      ),
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MediaViewerScreen(
                                  url: imageUrl,
                                  type: 'image',
                                  fileName: subtitle.isNotEmpty
                                      ? subtitle
                                      : 'image.jpg',
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: appColor(context).grey100,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 150,
                                      color: appColor(context).grey100,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      ],
                      if (showAppealButton) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isAppealing
                              ? null
                              : () {
                                  controller.appealMessageApi(
                                    context,
                                    messageId,
                                  );
                                },
                          icon: isAppealing
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      titleColor,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  ImageAssets.appeal,
                                  width: 14,
                                  height: 14,
                                  color: titleColor,
                                ),
                          label: Text(
                            isAppealing ? "Appealing..." : "Appeal Message",
                            style: fontStyle.clashDisplaySemiBold12.textColor(
                              titleColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: titleColor, width: 1),
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.transparent,
                            foregroundColor: titleColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        if (appealFailed) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Appeal failed. Please try again.",
                            style: fontStyle.clashDisplayRegular10.textColor(
                              titleColor,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 6),
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

  /// Handcrafting complex Waveform Audio Players inside incoming message streams
  Widget _buildIncomingVoicePlayer(
    BuildContext context,
    String duration,
    String time,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appColor(context).secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: appColor(context).white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reactive layout simulating high-fidelity Audio Frequency waveforms
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(13, (index) {
                        final double height = [
                          6.0,
                          12.0,
                          18.0,
                          10.0,
                          6.0,
                          16.0,
                          22.0,
                          18.0,
                          10.0,
                          14.0,
                          10.0,
                          6.0,
                          12.0,
                        ][index];
                        final bool isActive =
                            index < 5; // Simulated playback bounds
                        return Container(
                          width: 2,
                          height: height,
                          decoration: BoxDecoration(
                            color: isActive
                                ? appColor(context).black87
                                : appColor(context).grey300,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$duration •",
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).black54,
                    ),
                  ),
                  Text(
                    time,
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).grey400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingText(
    BuildContext context,
    String text,
    String time,
    String? avatarUrl, {
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    bool isForwarded = false,
    bool isEdited = false,
    String? replyToType,
    String? replyToUrl,
  }) {
    final controller = Provider.of<PersonalChatController>(
      context,
      listen: false,
    );
    final isSearchActive = controller.isSearchActive;
    final searchQuery = controller.searchQuery;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
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
              if (isForwarded) ...[
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
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
                              Row(
                                children: [
                                  if (replyToType == 'image') ...[
                                    Icon(
                                      Icons.photo_rounded,
                                      size: 14,
                                      color: appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ] else if (replyToType == 'sticker') ...[
                                    Icon(
                                      Icons.emoji_emotions_rounded,
                                      size: 14,
                                      color: appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ] else if (replyToType == 'video') ...[
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 14,
                                      color: appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ] else if (replyToType == 'audio') ...[
                                    Icon(
                                      Icons.mic_rounded,
                                      size: 14,
                                      color: appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      (replyToType == 'image' &&
                                              (replyTo == null ||
                                                  replyTo.isEmpty ||
                                                  replyTo ==
                                                      'Check out this photo!'))
                                          ? "Photo"
                                          : (replyToType == 'video' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty ||
                                                    replyTo ==
                                                        'Check out this video!'))
                                          ? "Video"
                                          : (replyToType == 'audio' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty))
                                          ? "Voice Message"
                                          : (replyToType == 'sticker' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty))
                                          ? "Sticker"
                                          : replyTo,
                                      style: fontStyle.clashDisplayRegular12
                                          .textColor(appColor(context).black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if ((replyToType == 'image' ||
                                replyToType == 'sticker') &&
                            replyToUrl != null &&
                            replyToUrl.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              replyToUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: _buildHighlightedText(
                      context,
                      text,
                      searchQuery,
                      isSearchActive,
                      fontStyle.clashDisplayMedium14.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        time,
                        style: fontStyle.clashDisplayMedium10.textColor(
                          appColor(context).grey400,
                        ),
                      ),
                      if (isEdited)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: appColor(
                              context,
                            ).black.withValues(alpha: 0.06),
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
                  ),
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
    String? avatarUrl,
    String? fileName,
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    bool isForwarded = false,
    bool isEdited = false,
    String status = 'sent',
    String? replyToType,
    String? replyToUrl,
  }) {
    if (type == 'image') {
      return _buildImageBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        avatarUrl,
        isForwarded: isForwarded,
        status: status,
        replyTo: replyTo,
        replyToSender: replyToSender,
        parentMessageId: parentMessageId,
        onReplyTap: onReplyTap,
        replyToType: replyToType,
        replyToUrl: replyToUrl,
      );
    } else if (type == 'video') {
      return _buildVideoBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        avatarUrl,
        isForwarded: isForwarded,
        status: status,
        replyTo: replyTo,
        replyToSender: replyToSender,
        parentMessageId: parentMessageId,
        onReplyTap: onReplyTap,
        replyToType: replyToType,
        replyToUrl: replyToUrl,
      );
    } else if (type == 'file' || type == 'document') {
      return _buildDocumentBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        avatarUrl,
        fileName,
        isForwarded: isForwarded,
        status: status,
        replyTo: replyTo,
        replyToSender: replyToSender,
        parentMessageId: parentMessageId,
        onReplyTap: onReplyTap,
        replyToType: replyToType,
        replyToUrl: replyToUrl,
      );
    } else if (type == 'audio') {
      return _buildAudioBubble(
        context,
        url,
        text,
        time,
        isOutgoing,
        avatarUrl,
        isForwarded: isForwarded,
        status: status,
        replyTo: replyTo,
        replyToSender: replyToSender,
        parentMessageId: parentMessageId,
        onReplyTap: onReplyTap,
        replyToType: replyToType,
        replyToUrl: replyToUrl,
      );
    } else if (type == 'sticker') {
      return _buildStickerBubble(
        context,
        url,
        time,
        isOutgoing,
        avatarUrl,
        isForwarded: isForwarded,
        status: status,
        replyTo: replyTo,
        replyToSender: replyToSender,
        parentMessageId: parentMessageId,
        onReplyTap: onReplyTap,
        replyToType: replyToType,
        replyToUrl: replyToUrl,
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
              status: status,
              replyToType: replyToType,
              replyToUrl: replyToUrl,
            )
          : _buildIncomingText(
              context,
              text,
              time,
              avatarUrl,
              replyTo: replyTo,
              replyToSender: replyToSender,
              parentMessageId: parentMessageId,
              onReplyTap: onReplyTap,
              isForwarded: isForwarded,
              isEdited: isEdited,
              replyToType: replyToType,
              replyToUrl: replyToUrl,
            );
    }
  }

  Widget _buildImageBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String? avatarUrl, {
    bool isForwarded = false,
    String status = 'sent',
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    String? replyToType,
    String? replyToUrl,
  }) {
    final bubbleColor = isOutgoing
        ? appColor(context).secondary
        : appColor(context).grey100;
    final textColor = isOutgoing
        ? appColor(context).white
        : appColor(context).black;

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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
                if (replyTo != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 8,
                      bottom: 4,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (onReplyTap != null && parentMessageId != null) {
                          onReplyTap(parentMessageId);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOutgoing
                              ? Colors.white.withValues(alpha: 0.18)
                              : appColor(
                                  context,
                                ).secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isOutgoing
                                  ? Colors.white
                                  : appColor(context).secondary,
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    replyToSender ?? "Reply",
                                    style: fontStyle.clashDisplayBold12
                                        .textColor(
                                          isOutgoing
                                              ? Colors.white
                                              : appColor(context).secondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (replyToType == 'image') ...[
                                        Icon(
                                          Icons.photo_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (replyToType == 'sticker') ...[
                                        Icon(
                                          Icons.emoji_emotions_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (replyToType == 'video') ...[
                                        Icon(
                                          Icons.videocam_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (replyToType == 'audio') ...[
                                        Icon(
                                          Icons.mic_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          (replyToType == 'image' &&
                                                  (replyTo == null ||
                                                      replyTo.isEmpty ||
                                                      replyTo ==
                                                          'Check out this photo!'))
                                              ? "Photo"
                                              : (replyToType == 'video' &&
                                                    (replyTo == null ||
                                                        replyTo.isEmpty ||
                                                        replyTo ==
                                                            'Check out this video!'))
                                              ? "Video"
                                              : (replyToType == 'audio' &&
                                                    (replyTo == null ||
                                                        replyTo.isEmpty))
                                              ? "Voice Message"
                                              : (replyToType == 'sticker' &&
                                                    (replyTo == null ||
                                                        replyTo.isEmpty))
                                              ? "Sticker"
                                              : replyTo,
                                          style: fontStyle.clashDisplayRegular12
                                              .textColor(
                                                isOutgoing
                                                    ? Colors.white.withValues(
                                                        alpha: 0.95,
                                                      )
                                                    : appColor(
                                                        context,
                                                      ).black.withValues(
                                                        alpha: 0.8,
                                                      ),
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
                            if ((replyToType == 'image' ||
                                    replyToType == 'sticker') &&
                                replyToUrl != null &&
                                replyToUrl.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  replyToUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                if (url != null && url.isNotEmpty)
                  Image.network(
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
                    horizontal: 10,
                    vertical: 4,
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
                            style: fontStyle.clashDisplayMedium12.textColor(
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
        if (isOutgoing) ...[
          const SizedBox(width: 8),
          _buildGreenTick(context, status: status),
        ],
      ],
    );
  }

  Widget _buildVideoBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String? avatarUrl, {
    bool isForwarded = false,
    String status = 'sent',
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    String? replyToType,
    String? replyToUrl,
  }) {
    final bubbleColor = isOutgoing
        ? appColor(context).secondary
        : appColor(context).grey100;
    final textColor = isOutgoing
        ? appColor(context).white
        : appColor(context).black;

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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
                if (replyTo != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 8,
                      bottom: 4,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (onReplyTap != null && parentMessageId != null) {
                          onReplyTap(parentMessageId);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOutgoing
                              ? Colors.white.withValues(alpha: 0.18)
                              : appColor(
                                  context,
                                ).secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isOutgoing
                                  ? Colors.white
                                  : appColor(context).secondary,
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    replyToSender ?? "Reply",
                                    style: fontStyle.clashDisplayBold12
                                        .textColor(
                                          isOutgoing
                                              ? Colors.white
                                              : appColor(context).secondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (replyToType == 'image') ...[
                                        Icon(
                                          Icons.photo_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (replyToType == 'sticker') ...[
                                        Icon(
                                          Icons.emoji_emotions_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (replyToType == 'video') ...[
                                        Icon(
                                          Icons.videocam_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (replyToType == 'audio') ...[
                                        Icon(
                                          Icons.mic_rounded,
                                          size: 14,
                                          color: isOutgoing
                                              ? Colors.white70
                                              : appColor(context).grey600,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          (replyToType == 'image' &&
                                                  (replyTo == null ||
                                                      replyTo.isEmpty ||
                                                      replyTo ==
                                                          'Check out this photo!'))
                                              ? "Photo"
                                              : (replyToType == 'video' &&
                                                    (replyTo == null ||
                                                        replyTo.isEmpty ||
                                                        replyTo ==
                                                            'Check out this video!'))
                                              ? "Video"
                                              : (replyToType == 'audio' &&
                                                    (replyTo == null ||
                                                        replyTo.isEmpty))
                                              ? "Voice Message"
                                              : (replyToType == 'sticker' &&
                                                    (replyTo == null ||
                                                        replyTo.isEmpty))
                                              ? "Sticker"
                                              : replyTo,
                                          style: fontStyle.clashDisplayRegular12
                                              .textColor(
                                                isOutgoing
                                                    ? Colors.white.withValues(
                                                        alpha: 0.95,
                                                      )
                                                    : appColor(
                                                        context,
                                                      ).black.withValues(
                                                        alpha: 0.8,
                                                      ),
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
                            if ((replyToType == 'image' ||
                                    replyToType == 'sticker') &&
                                replyToUrl != null &&
                                replyToUrl.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  replyToUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                    horizontal: 10,
                    vertical: 4,
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
                            style: fontStyle.clashDisplayMedium12.textColor(
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
        if (isOutgoing) ...[
          const SizedBox(width: 8),
          _buildGreenTick(context, status: status),
        ],
      ],
    );
  }

  Widget _buildDocumentBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String? avatarUrl,
    String? fileName, {
    bool isForwarded = false,
    String status = 'sent',
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    String? replyToType,
    String? replyToUrl,
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
    // Define state variables here so they persist perfectly across local StatefulBuilder rebuilds!
    bool isDownloading = false;
    bool isCancelled = false;
    double progress = 0.0;

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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
                      color: isOutgoing
                          ? Colors.white.withValues(alpha: 0.18)
                          : appColor(context).secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isOutgoing
                              ? Colors.white
                              : appColor(context).secondary,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyToSender ?? "Reply",
                                style: fontStyle.clashDisplayBold12.textColor(
                                  isOutgoing
                                      ? Colors.white
                                      : appColor(context).secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (replyToType == 'image') ...[
                                    Icon(
                                      Icons.photo_rounded,
                                      size: 14,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ] else if (replyToType == 'sticker') ...[
                                    Icon(
                                      Icons.emoji_emotions_rounded,
                                      size: 14,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ] else if (replyToType == 'video') ...[
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 14,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ] else if (replyToType == 'audio') ...[
                                    Icon(
                                      Icons.mic_rounded,
                                      size: 14,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      (replyToType == 'image' &&
                                              (replyTo == null ||
                                                  replyTo.isEmpty ||
                                                  replyTo ==
                                                      'Check out this photo!'))
                                          ? "Photo"
                                          : (replyToType == 'video' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty ||
                                                    replyTo ==
                                                        'Check out this video!'))
                                          ? "Video"
                                          : (replyToType == 'audio' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty))
                                          ? "Voice Message"
                                          : (replyToType == 'sticker' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty))
                                          ? "Sticker"
                                          : replyTo,
                                      style: fontStyle.clashDisplayRegular12
                                          .textColor(
                                            isOutgoing
                                                ? Colors.white.withValues(
                                                    alpha: 0.95,
                                                  )
                                                : appColor(context).black
                                                      .withValues(alpha: 0.8),
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
                        if ((replyToType == 'image' ||
                                replyToType == 'sticker') &&
                            replyToUrl != null &&
                            replyToUrl.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              replyToUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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
              if (text.isNotEmpty &&
                  !text.startsWith("Shared a document:")) ...[
                StatefulBuilder(
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
                        final sanitizedFileName = resolvedFileName.replaceAll(
                          RegExp(r'[^\w\.\-]'),
                          '_',
                        );
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
                          debugPrint("Error downloading/opening document: $e");
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
                              Text(
                                resolvedFileName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: fontStyle.clashDisplayBold12.textColor(
                                  textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$extension • $sizeStr",
                                style: fontStyle.clashDisplayMedium10.textColor(
                                  subtitleColor,
                                ),
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
                                        backgroundColor: textColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isOutgoing
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                      ),
                                      Icon(
                                        Icons.close,
                                        color: textColor.withValues(alpha: 0.8),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        text,
                        style: fontStyle.clashDisplayMedium12.textColor(
                          textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: fontStyle.clashDisplayMedium10.textColor(
                        subtitleColor,
                      ),
                    ),
                  ],
                ),
              ] else ...[
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
                                  final absoluteUrl = ApiService.getImageUrl(
                                    url,
                                  );
                                  final remoteUri = Uri.parse(absoluteUrl);
                                  await launchUrl(
                                    remoteUri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (err) {
                                  debugPrint(
                                    "Error launching remote URL: $err",
                                  );
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
                                          color: textColor.withValues(
                                            alpha: 0.8,
                                          ),
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
            ],
          ),
        ),
        if (isOutgoing) ...[
          const SizedBox(width: 8),
          _buildGreenTick(context, status: status),
        ],
      ],
    );
  }

  Widget _buildAudioBubble(
    BuildContext context,
    String? url,
    String text,
    String time,
    bool isOutgoing,
    String? avatarUrl, {
    bool isForwarded = false,
    String status = 'sent',
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    String? replyToType,
    String? replyToUrl,
  }) {
    return VoiceMessageBubble(
      url: url,
      isOutgoing: isOutgoing,
      avatarUrl: avatarUrl,
      time: time,
      isForwarded: isForwarded,
      status: status,
      replyTo: replyTo,
      replyToSender: replyToSender,
      parentMessageId: parentMessageId,
      onReplyTap: onReplyTap,
      replyToType: replyToType,
      replyToUrl: replyToUrl,
    );
  }

  Widget _buildStickerBubble(
    BuildContext context,
    String? url,
    String time,
    bool isOutgoing,
    String? avatarUrl, {
    bool isForwarded = false,
    String status = 'sent',
    String? replyTo,
    String? replyToSender,
    String? parentMessageId,
    ValueChanged<String>? onReplyTap,
    String? replyToType,
    String? replyToUrl,
  }) {
    final String imageUrl = ApiService.getImageUrl(url);

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (replyTo != null) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (onReplyTap != null && parentMessageId != null) {
                    onReplyTap(parentMessageId);
                  }
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOutgoing
                        ? appColor(context).secondary
                        : appColor(context).grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOutgoing
                          ? Colors.white.withValues(alpha: 0.18)
                          : appColor(context).secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isOutgoing
                              ? Colors.white
                              : appColor(context).secondary,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyToSender ?? "Reply",
                                style: fontStyle.clashDisplayBold10.textColor(
                                  isOutgoing
                                      ? Colors.white
                                      : appColor(context).secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (replyToType == 'image') ...[
                                    Icon(
                                      Icons.photo_rounded,
                                      size: 11,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 3),
                                  ] else if (replyToType == 'sticker') ...[
                                    Icon(
                                      Icons.emoji_emotions_rounded,
                                      size: 11,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 3),
                                  ] else if (replyToType == 'video') ...[
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 11,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 3),
                                  ] else if (replyToType == 'audio') ...[
                                    Icon(
                                      Icons.mic_rounded,
                                      size: 11,
                                      color: isOutgoing
                                          ? Colors.white70
                                          : appColor(context).grey600,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Expanded(
                                    child: Text(
                                      (replyToType == 'image' &&
                                              (replyTo == null ||
                                                  replyTo.isEmpty ||
                                                  replyTo ==
                                                      'Check out this photo!'))
                                          ? "Photo"
                                          : (replyToType == 'video' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty ||
                                                    replyTo ==
                                                        'Check out this video!'))
                                          ? "Video"
                                          : (replyToType == 'audio' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty))
                                          ? "Voice Message"
                                          : (replyToType == 'sticker' &&
                                                (replyTo == null ||
                                                    replyTo.isEmpty))
                                          ? "Sticker"
                                          : replyTo,
                                      style: fontStyle.clashDisplayRegular10
                                          .textColor(
                                            isOutgoing
                                                ? Colors.white.withValues(
                                                    alpha: 0.95,
                                                  )
                                                : appColor(context).black
                                                      .withValues(alpha: 0.8),
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
                        if ((replyToType == 'image' ||
                                replyToType == 'sticker') &&
                            replyToUrl != null &&
                            replyToUrl.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              replyToUrl,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
        if (isOutgoing) ...[
          const SizedBox(width: 8),
          _buildGreenTick(context, status: status),
        ],
      ],
    );
  }

  /// Integrated Footer Composer incorporating real interactive TextFields and conditional action bars
  Widget _buildComposer(
    BuildContext context,
    PersonalChatController controller,
  ) {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final bool isRecording = controller.isRecording;
        final bool isRecordingPaused = controller.isRecordingPaused;
        final int recordingSeconds = controller.recordingSeconds;
        final int recordingTicks = controller.recordingTicks;
        final Timer? recordingTimer = controller.recordingTimer;
        final AudioRecorder? audioRecorder = controller.audioRecorder;
        final String? recordedFilePath = controller.recordedFilePath;

        Future<void> discardRecording() async {
          try {
            controller.recordingTimer?.cancel();
            if (controller.audioRecorder != null && controller.isRecording) {
              await controller.audioRecorder!.stop();
              setState(() {
                controller.isRecording = false;
                controller.isRecordingPaused = false;
                controller.recordingSeconds = 0;
                controller.recordingTicks = 0;
              });
              controller.onCancelRecording = null;
              try {
                if (controller.recordedFilePath != null) {
                  final file = File(controller.recordedFilePath!);
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

        Future<void> startRecording() async {
          try {
            controller.audioRecorder ??= AudioRecorder();
            if (await controller.audioRecorder!.hasPermission()) {
              final Directory tempDir = await getTemporaryDirectory();
              controller.recordedFilePath =
                  '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

              await controller.audioRecorder!.start(
                const RecordConfig(encoder: AudioEncoder.aacLc),
                path: controller.recordedFilePath!,
              );

              controller.recordingSeconds = 0;
              controller.recordingTicks = 0;
              controller.recordingTimer?.cancel();
              controller.recordingTimer = Timer.periodic(
                const Duration(milliseconds: 100),
                (timer) {
                  setState(() {
                    controller.recordingTicks++;
                    if (controller.recordingTicks % 10 == 0) {
                      controller.recordingSeconds++;
                    }
                  });
                },
              );

              setState(() {
                controller.isRecording = true;
                controller.isRecordingPaused = false;
              });
              controller.onCancelRecording = () {
                discardRecording();
              };
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
            if (controller.audioRecorder != null &&
                controller.isRecording &&
                !controller.isRecordingPaused) {
              await controller.audioRecorder!.pause();
              controller.recordingTimer?.cancel();
              setState(() {
                controller.isRecordingPaused = true;
              });
            }
          } catch (e) {
            debugPrint("Error pausing recording: $e");
          }
        }

        Future<void> resumeRecording() async {
          try {
            if (controller.audioRecorder != null &&
                controller.isRecording &&
                controller.isRecordingPaused) {
              await controller.audioRecorder!.resume();
              controller.recordingTimer = Timer.periodic(
                const Duration(milliseconds: 100),
                (timer) {
                  setState(() {
                    controller.recordingTicks++;
                    if (controller.recordingTicks % 10 == 0) {
                      controller.recordingSeconds++;
                    }
                  });
                },
              );
              setState(() {
                controller.isRecordingPaused = false;
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
                controller.isRecording = false;
                controller.isRecordingPaused = false;
                controller.recordingSeconds = 0;
                controller.recordingTicks = 0;
              });
              controller.onCancelRecording = null;
              if (path != null && path.isNotEmpty) {
                final int audioSize = await File(path).length();
                final settings = await SettingsModel.loadActiveSettings();
                if (audioSize > settings.getAudioLimitBytes()) {
                  if (context.mounted) {
                    ToastHelper.showWarningDialog(
                      context,
                      "Audio Too Large",
                      "Recorded audio cannot exceed ${settings.audioLimit ?? '15MB'}. Your recorded audio is ${SettingsModel.formatBytes(audioSize)}.",
                    );
                  }
                  return;
                }
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
                        onChanged: (_) => controller.handleTyping(),
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
                    GestureDetector(
                      onTap: () => controller.sendMessage(),
                      child: Transform.rotate(
                        angle: -0.2,
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
                if (isGroup ||
                    (controller.relationshipStatus == 'accepted' &&
                        !controller.isNewChat)) ...[
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
                            controller.toggleAttachmentOpen();
                          },
                          child: Image.asset(
                            controller.isAttachmentOpen
                                ? ImageAssets.clipActive
                                : ImageAssets.paperclip,
                            width: 22,
                            height: 22,
                            color: controller.isAttachmentOpen
                                ? null
                                : appColor(context).black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.isAttachmentOpen) ...[
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
                              controller.setAttachmentOpen(false);
                              await controller.pickMedia(context);
                            },
                          ),
                          _buildAttachmentOption(
                            context,
                            title: "Document",
                            asset: ImageAssets.file,
                            color: Colors.blue.shade700,
                            onTap: () async {
                              controller.setAttachmentOpen(false);
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

  /// Helper UI building the Stadium Circle options in the expanded attachment drawer
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

  /// Render SPECIAL Message Request Intro containing Centered Large Avatar Stack and one text bubble
  Widget _buildRequestChatView(
    BuildContext context,
    String titleName,
    String? avatarUrl,
    PersonalChatController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 24),
        // Large central user branding avatar seen centered on mockup
        Center(
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColor(context).grey100,
              image: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(ApiService.getImageUrl(avatarUrl)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? null
                : Icon(
                    Icons.person,
                    color: appColor(context).secondary,
                    size: 54,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Bold Large contact name
        Center(
          child: Text(
            titleName,
            style: fontStyle.clashDisplaySemiBold20.textColor(
              appColor(context).black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Normalized contact email subtitle
        Center(
          child: Text(
            "${titleName.replaceAll(' ', '').toLowerCase()}@gmail.com",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Render the actual fetched messages
        ...() {
          final list = <Widget>[];
          for (int i = 0; i < controller.messages.length; i++) {
            final msg = controller.messages[i];
            final String modStatus = msg['moderation_status'] ?? 'Approved';
            final bool isOutgoing = msg['isOutgoing'] ?? false;
            final String text = msg['text'] ?? '';
            final String time = msg['time'] ?? '';
            final String? createdAt = msg['createdAt'];

            // Calculate if we need to show the date header
            bool showDateHeader = false;
            String dateHeaderStr = "";
            if (createdAt != null) {
              final String currentDayStr = DateHelper.formatMessageDate(
                createdAt,
              );
              if (i == 0) {
                showDateHeader = true;
                dateHeaderStr = currentDayStr;
              } else {
                final prevMsg = controller.messages[i - 1];
                final String? prevCreatedAt = prevMsg['createdAt'];
                if (prevCreatedAt != null) {
                  final String prevDayStr = DateHelper.formatMessageDate(
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

            final String? moderatedBy = msg['moderated_by'] is Map
                ? (msg['moderated_by']['name']?.toString() ??
                      msg['moderated_by']['_id']?.toString())
                : msg['moderated_by']?.toString();

            Widget messageWidget;
            if (modStatus == 'Approved' &&
                moderatedBy != null &&
                moderatedBy != 'RoseShield') {
              if (isOutgoing) {
                messageWidget = Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStatusBubble(
                    context,
                    asset: ImageAssets.ok,
                    title: "Approved After Review",
                    subtitle: text,
                    titleColor: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    time: time,
                    isOutgoing: isOutgoing,
                    imageUrl: msg['url']?.toString(),
                  ),
                );
              } else {
                final String msgType = msg['type'] ?? 'text';
                final String? fileUrl = msg['url'];

                messageWidget = Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMediaMessageBubble(
                    context,
                    type: msgType,
                    text: text,
                    time: time,
                    url: fileUrl,
                    isOutgoing: isOutgoing,
                    avatarUrl: avatarUrl,
                    fileName: msg['file_name']?.toString(),
                    replyTo: msg['replyTo']?.toString(),
                    replyToSender: msg['replyToSender']?.toString(),
                    replyToType: msg['replyToType']?.toString(),
                    replyToUrl: msg['replyToUrl']?.toString(),
                    parentMessageId: msg['parent_message_id']?.toString(),
                    onReplyTap: (parentMsgId) =>
                        _scrollToMessage(controller, parentMsgId),
                    isForwarded: msg['is_forwarded'] == true,
                    isEdited: msg['isEdited'] == true,
                    status: msg['status'] ?? 'sent',
                  ),
                );
              }
            } else if (modStatus == 'Moderation') {
              if (isOutgoing) {
                messageWidget = Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStatusBubble(
                    context,
                    asset: ImageAssets.appeal,
                    title: "Your message is under review",
                    subtitle:
                        "We're reviewing your message to keep everyone safe and respectful.",
                    titleColor: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF8E1),
                    time: time,
                    isOutgoing: isOutgoing,
                  ),
                );
              } else {
                messageWidget = const SizedBox.shrink();
              }
            } else if (modStatus == 'Blocked') {
              if (isOutgoing) {
                final bool isAppealing = msg['isAppealing'] == true;
                final bool appealFailed = msg['appealFailed'] == true;
                messageWidget = Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStatusBubble(
                    context,
                    asset: ImageAssets.pause,
                    title: "Your message is blocked",
                    subtitle:
                        "This message may contain inappropriate content that could make others uncomfortable.",
                    titleColor: const Color(0xFFC62828),
                    bgColor: const Color(0xFFFFF2F2),
                    time: time,
                    isOutgoing: isOutgoing,
                    messageId: msg['id']?.toString(),
                    isAppealing: isAppealing,
                    appealFailed: appealFailed,
                  ),
                );
              } else {
                messageWidget = const SizedBox.shrink();
              }
            } else {
              final String msgType = msg['type'] ?? 'text';
              final String? fileUrl = msg['url'];

              messageWidget = Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMediaMessageBubble(
                  context,
                  type: msgType,
                  text: text,
                  time: time,
                  url: fileUrl,
                  isOutgoing: isOutgoing,
                  avatarUrl: avatarUrl,
                  fileName: msg['file_name']?.toString(),
                  replyTo: msg['replyTo']?.toString(),
                  replyToSender: msg['replyToSender']?.toString(),
                  replyToType: msg['replyToType']?.toString(),
                  replyToUrl: msg['replyToUrl']?.toString(),
                  parentMessageId: msg['parent_message_id']?.toString(),
                  onReplyTap: (parentMsgId) =>
                      _scrollToMessage(controller, parentMsgId),
                  isForwarded: msg['is_forwarded'] == true,
                  isEdited: msg['isEdited'] == true,
                  status: msg['status'] ?? 'sent',
                ),
              );
            }

            if (showDateHeader) {
              list.add(
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      dateHeaderStr,
                      style: fontStyle.clashDisplayBold14.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                ),
              );
            }
            list.add(messageWidget);
          }
          return list;
        }(),
      ],
    );
  }

  /// Anchored Bottom Message Request acceptance / block drawer replacing standard composer input block
  Widget _buildRequestConsentPanel(
    BuildContext context,
    PersonalChatController controller,
    String titleName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: BoxDecoration(color: appColor(context).white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The bold pink main query
          Text(
            "Accept message request from\n$titleName?",
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayBold16.textColor(
              appColor(context).secondary,
            ),
          ),
          const SizedBox(height: 16),

          // Consent conditions tag
          Text(
            "If you accept, they will also be able to call you and see info such as your activity status and when you've read messages.",
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayRegular12.textColor(
              appColor(context).black.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 32),

          // 3 Dynamic Actions Stadium Cards: Block, Reject, Accept
          Row(
            children: [
              Expanded(
                child: _buildRequestActionCard(
                  context,
                  label: "Block",
                  textColor: appColor(context).black,
                  bgColor: appColor(context).grey200,
                  isLoading:
                      controller.isResponding &&
                      controller.respondingAction == 'blocked',
                  onTap: () => controller.respondToConnectionRequest(
                    'blocked',
                    context: context,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRequestActionCard(
                  context,
                  label: "Reject",
                  textColor: const Color(0xFFB71C44),
                  bgColor: appColor(context).grey200,
                  isLoading:
                      controller.isResponding &&
                      controller.respondingAction == 'rejected',
                  onTap: () => controller.respondToConnectionRequest(
                    'rejected',
                    context: context,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRequestActionCard(
                  context,
                  label: "Accept",
                  textColor: appColor(context).white,
                  bgColor: appColor(context).secondary,
                  isLoading:
                      controller.isResponding &&
                      controller.respondingAction == 'accepted',
                  onTap: () => controller.respondToConnectionRequest(
                    'accepted',
                    context: context,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Blocker panel for the receiver side of the block, offering an Unblock button
  Widget _buildBlockerPanel(
    BuildContext context,
    PersonalChatController controller,
    String titleName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: BoxDecoration(color: appColor(context).white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "You blocked $titleName",
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayBold16.textColor(
              appColor(context).secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You won't receive messages or calls from this contact until you unblock them.",
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayRegular12.textColor(
              appColor(context).black.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: controller.isResponding
                ? null
                : () => controller.unblockUser(),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: appColor(context).secondary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB71C44),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: controller.isResponding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Unblock",
                      style: fontStyle.clashDisplaySemiBold14.textColor(
                        appColor(context).white,
                      ),
                    ),
            ),
          ),
          if (controller.unblockError != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.unblockError!,
              style: fontStyle.clashDisplayRegular12.textColor(
                const Color(0xFFB71C44),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Blocked panel for the sender side of the block, hiding composition
  Widget _buildBlockedPanel(BuildContext context, String titleName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      decoration: BoxDecoration(
        color: appColor(context).grey50,
        border: Border(
          top: BorderSide(color: appColor(context).grey100, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        "This chat is blocked",
        style: fontStyle.clashDisplayBold16.textColor(
          appColor(context).grey500,
        ),
      ),
    );
  }

  /// Generates stadium rounded cards mirroring custom tactile 3D action buttons
  Widget _buildRequestActionCard(
    BuildContext context, {
    required String label,
    required Color textColor,
    required Color bgColor,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final bool isPink = bgColor == appColor(context).secondary;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            // Base sharp 3D tactile offset base
            BoxShadow(
              color: isPink ? const Color(0xFFB71C44) : const Color(0xFFCDCDCD),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            // Soft blur drop shade below
            BoxShadow(
              color: isPink
                  ? appColor(context).secondary.withValues(alpha: 0.2)
                  : appColor(context).black.withValues(alpha: 0.05),
              offset: const Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Text(
                  label,
                  style: fontStyle.clashDisplaySemiBold14.textColor(textColor),
                ),
        ),
      ),
    );
  }

  void _showStickersBottomSheet(BuildContext context) {
    final chatController = Provider.of<PersonalChatController>(
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
            return ChangeNotifierProvider<PersonalChatController>.value(
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
                            ? Consumer<PersonalChatController>(
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
                            : Consumer<PersonalChatController>(
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
}

/// Dedicated internal component delivering dual-state toggle configuration for follow triggers
class _FollowButton extends StatelessWidget {
  final String recipientId;

  const _FollowButton({required this.recipientId});

  @override
  Widget build(BuildContext context) {
    if (recipientId.isEmpty) return const SizedBox.shrink();

    return Consumer<AddNewChatController>(
      builder: (context, controller, child) {
        final user = controller.allUsers.firstWhere(
          (u) => u['_id'] == recipientId,
          orElse: () => null,
        );
        if (user == null) return const SizedBox.shrink();

        final relationship = user['relationship'];
        final bool isIncoming =
            relationship != null &&
            relationship['status'] == 'pending' &&
            relationship['requested_by'] == recipientId;

        if (isIncoming) {
          return const SizedBox.shrink();
        }

        final bool isRequested =
            relationship != null &&
            relationship['status'] == 'pending' &&
            relationship['requested_by'] != recipientId;
        final String status = relationship?['status'] ?? '';

        if (status == 'accepted') {
          return Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: appColor(context).white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: appColor(context).green, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: appColor(context).green, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Connected",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).green,
                  ),
                ),
              ],
            ),
          );
        }

        final bool isLoadingButton = controller.loadingUserIds.contains(
          recipientId,
        );

        if (!isRequested) {
          // Show "Connect" button
          return GestureDetector(
            onTap: () {
              if (isLoadingButton) return;
              controller.connectUser(recipientId);
            },
            child: Container(
              height: 36,
              width: 110,
              decoration: BoxDecoration(
                color: appColor(context).secondary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFB71C44), // Solid 3D pink base
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: appColor(context).secondary.withValues(alpha: 0.2),
                    offset: const Offset(0, 6),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: isLoadingButton
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: appColor(context).white,
                          ),
                        )
                      : Text(
                          "Connect",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).white,
                          ),
                        ),
                ),
              ),
            ),
          );
        } else {
          // Show "Requested" badge & "Cancel" button
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: appColor(context).white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: appColor(context).secondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: appColor(context).black, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Requested",
                      style: fontStyle.clashDisplaySemiBold14.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (isLoadingButton) return;
                  controller.cancelConnection(recipientId);
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: appColor(context).grey200,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0xFFCDCDCD), // Solid 3D grey base
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: appColor(context).black.withValues(alpha: 0.05),
                        offset: const Offset(0, 6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: isLoadingButton
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: appColor(context).black,
                              ),
                            )
                          : Text(
                              "Cancel",
                              style: fontStyle.clashDisplaySemiBold14.textColor(
                                appColor(context).black,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
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
  '🥣', '🥗', '🍿', '🧈', '🧂', '🥫', '🍱', '🍘', '🍙', '🍚',
  '🍛', '🍜', '🍝', '🍠', '🍢', '🍣', '🍤', '🍥', '🥮', '🍡',
  '🥟', '🥠', '🥡', '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰',
  '🧁', '🥧', '🍫', '🍬', '🍭', '🍮', '🍯', '🍼', '🥛', '☕',
  '🫖', '🍵', '🍶', '🍾', '🍷', '🍸', '🍹', '🍺', '🍻', '🥂',
  '🥃', '🥤', '🧋', '🧃', '🧉', '🧊',
];
