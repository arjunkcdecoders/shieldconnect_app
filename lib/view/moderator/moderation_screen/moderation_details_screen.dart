import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/moderation_controller.dart';
import 'package:shieldconnect_app/model/moderator/moderation_item.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/view/voice_message_bubble.dart';

class ModerationDetailsScreen extends StatelessWidget {
  final ModerationItem item;

  const ModerationDetailsScreen({super.key, required this.item});

  void _showSuccessDialog(BuildContext context, String displayStatus) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        });

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2E7D32),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Success",
                  style: fontStyle.clashDisplayBold20
                      .textColor(appColor(context).black)
                      .size(18),
                ),
                const SizedBox(height: 8),
                Text(
                  "Successfully updated to $displayStatus",
                  textAlign: TextAlign.center,
                  style: fontStyle.clashDisplayRegular14
                      .textColor(appColor(context).darkText)
                      .size(13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String displayStatus,
    required String apiStatus,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isLoading = false;
        bool isFailed = false;
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: appColor(context).primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Confirm Action",
                    style: fontStyle.clashDisplayBold20
                        .textColor(appColor(context).black)
                        .size(18),
                  ),
                ],
              ),
              content: Text(
                "Are you sure you want to change the status of this item to $displayStatus?",
                style: fontStyle.clashDisplayRegular14
                    .textColor(appColor(context).darkText)
                    .size(14),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: fontStyle.clashDisplaySemiBold14
                        .textColor(appColor(context).silver)
                        .size(14),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor(context).primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                                isFailed = false;
                              });
                              final controller =
                                  Provider.of<ModerationController>(
                                    context,
                                    listen: false,
                                  );
                              final success = await controller.updateItemStatus(
                                itemId: item.id,
                                status: apiStatus,
                                isProfileUpdate: item.isProfileUpdate,
                                profileType: item.profileType,
                              );
                              if (success) {
                                if (context.mounted) {
                                  Navigator.pop(dialogContext);
                                  _showSuccessDialog(context, displayStatus);
                                  Future.delayed(
                                    const Duration(milliseconds: 1500),
                                    () {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                    isFailed = true;
                                  });
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Confirm",
                              style: fontStyle.clashDisplaySemiBold14
                                  .textColor(Colors.white)
                                  .size(14),
                            ),
                    ),
                    if (isFailed)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(String timestampStr) {
    final parsed = DateTime.tryParse(timestampStr);
    if (parsed == null) return timestampStr;
    return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
  }

  String _formatTime(String timestampStr) {
    final parsed = DateTime.tryParse(timestampStr);
    if (parsed == null) return '2:20 PM';
    final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
    final amPm = parsed.hour >= 12 ? 'PM' : 'AM';
    return "$hour:${parsed.minute.toString().padLeft(2, '0')} $amPm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: appColor(context).bgGrey,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 18,
              color: appColor(context).secondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Moderation Details',
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).black)
              .size(18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appColor(context).primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: (item.isProfileUpdate)
                            ? ((item.pendingAvatar != null &&
                                      item.pendingAvatar!.isNotEmpty)
                                  ? NetworkImage(item.pendingAvatar!)
                                  : (item.fileUrl != null &&
                                        item.fileUrl!.isNotEmpty)
                                  ? NetworkImage(item.fileUrl!)
                                  : null)
                            : ((item.senderId?.avatar != null &&
                                      item.senderId!.avatar!.isNotEmpty)
                                  ? NetworkImage(item.senderId!.avatar!)
                                  : null),
                        child: (item.isProfileUpdate)
                            ? (((item.pendingAvatar == null ||
                                          item.pendingAvatar!.isEmpty) &&
                                      (item.fileUrl == null ||
                                          item.fileUrl!.isEmpty))
                                  ? Icon(
                                      item.profileType == 'group'
                                          ? Icons.group
                                          : Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null)
                            : ((item.senderId?.avatar == null ||
                                      item.senderId!.avatar!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.id.length > 6
                            ? item.id.substring(item.id.length - 6)
                            : item.id,
                        style: fontStyle.clashDisplayMedium12
                            .textColor(Colors.white.withOpacity(0.8))
                            .size(12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.senderId?.name ?? 'Unknown',
                          style: fontStyle.clashDisplayBold30
                              .textColor(Colors.white)
                              .size(14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Detection Type',
                    style: fontStyle.clashDisplayRegular12
                        .textColor(Colors.white.withOpacity(0.6))
                        .size(11)
                        .copyWith(
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        item.isProfileUpdate
                            ? (item.profileType == 'group'
                                  ? Icons.group_outlined
                                  : Icons.person_outline)
                            : Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.isProfileUpdate
                            ? (item.profileType == 'group'
                                  ? 'Group Profile Update'
                                  : 'User Profile Update')
                            : 'Text Message',
                        style: fontStyle.clashDisplaySemiBold18
                            .textColor(Colors.white)
                            .size(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildTag(
                        context,
                        "Status: ${item.moderationStatus}",
                        Colors.white,
                        appColor(context).primary,
                        borderColor: appColor(context).primary,
                      ),
                      const SizedBox(width: 6),
                      _buildTag(
                        context,
                        item.messageType.toUpperCase(),
                        const Color(0xFFE1F5FE),
                        const Color(0xFF00A3FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _formatTimestamp(item.createdAt),
                    style: fontStyle.clashDisplayRegular12
                        .textColor(Colors.white.withOpacity(0.8))
                        .size(11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F1F1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: item.isProfileUpdate
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PROPOSED PROFILE DETAILS",
                          style: fontStyle.clashDisplayBold30
                              .textColor(appColor(context).primary)
                              .size(12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appColor(
                                    context,
                                  ).primary.withOpacity(0.2),
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: appColor(context).bgGrey,
                                backgroundImage:
                                    (item.pendingAvatar != null &&
                                        item.pendingAvatar!.isNotEmpty)
                                    ? NetworkImage(item.pendingAvatar!)
                                    : (item.fileUrl != null &&
                                          item.fileUrl!.isNotEmpty)
                                    ? NetworkImage(item.fileUrl!)
                                    : null,
                                child:
                                    ((item.pendingAvatar == null ||
                                            item.pendingAvatar!.isEmpty) &&
                                        (item.fileUrl == null ||
                                            item.fileUrl!.isEmpty))
                                    ? Icon(
                                        item.profileType == 'group'
                                            ? Icons.group
                                            : Icons.person,
                                        color: appColor(context).silver,
                                        size: 32,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.profileType == 'group'
                                        ? "Group Name"
                                        : "Display Name",
                                    style: fontStyle.clashDisplayMedium12
                                        .textColor(appColor(context).silver)
                                        .size(10),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.pendingName ?? "Unnamed",
                                    style: fontStyle.clashDisplayBold30
                                        .textColor(appColor(context).black)
                                        .size(15),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.profileType == 'group'
                                        ? "Group Description"
                                        : "Bio",
                                    style: fontStyle.clashDisplayMedium12
                                        .textColor(appColor(context).silver)
                                        .size(10),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.pendingBio ?? "None",
                                    style: fontStyle.clashDisplayRegular14
                                        .textColor(appColor(context).black)
                                        .size(12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Text(
                      item.content ?? '',
                      style: fontStyle.clashDisplayMedium12
                          .textColor(appColor(context).black)
                          .size(12)
                          .copyWith(height: 1.4),
                    ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            if (item.moderationStatus == 'Moderation')
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: appColor(context).primary,
                      textColor: Colors.white,
                      onTap: () => _showConfirmationDialog(
                        context: context,
                        displayStatus: "Approved",
                        apiStatus: "Approved",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Reject',
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFEBEBEB),
                      textColor: appColor(context).primary,
                      onTap: () => _showConfirmationDialog(
                        context: context,
                        displayStatus: "Rejected",
                        apiStatus: "Blocked",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Escalate',
                      icon: Icons.outlined_flag,
                      color: const Color(0xFFEBEBEB),
                      textColor: const Color(0xFF757575),
                      iconColor: const Color(0xFFFFDE21),
                      onTap: () => _showConfirmationDialog(
                        context: context,
                        displayStatus: "Escalate",
                        apiStatus: "Escalate",
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Detected Chat Preview (Only for chat messages)
            if (!item.isProfileUpdate) ...[
              Text(
                'Detected Chat Preview',
                style: fontStyle.clashDisplayBold30
                    .textColor(appColor(context).black)
                    .size(16),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image message (if it is an image message type)
                  if (item.messageType == 'image')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 42, bottom: 4),
                          child: Text(
                            item.senderId?.name ?? 'Sender',
                            style: fontStyle.clashDisplayMedium12
                                .textColor(appColor(context).textSecondary)
                                .size(11),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: appColor(context).bgGrey,
                              backgroundImage:
                                  (item.senderId?.avatar != null &&
                                      item.senderId!.avatar!.isNotEmpty)
                                  ? NetworkImage(item.senderId!.avatar!)
                                  : null,
                              child:
                                  (item.senderId?.avatar == null ||
                                      item.senderId!.avatar!.isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      color: appColor(context).silver,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBEBEB),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      (item.fileUrl != null &&
                                              item.fileUrl!.isNotEmpty)
                                          ? item.fileUrl!
                                          : 'https://images.unsplash.com/photo-1548142813-c348350df52b?auto=format&fit=crop&q=80&w=400',
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8,
                                      bottom: 2,
                                      top: 2,
                                    ),
                                    child: Text(
                                      '2:20 PM',
                                      style: fontStyle.clashDisplayRegular12
                                          .textColor(
                                            appColor(context).textSecondary,
                                          )
                                          .size(9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else if (item.messageType == 'audio')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 42, bottom: 4),
                          child: Text(
                            item.senderId?.name ?? 'Sender',
                            style: fontStyle.clashDisplayMedium12
                                .textColor(appColor(context).textSecondary)
                                .size(11),
                          ),
                        ),
                        VoiceMessageBubble(
                          url: item.fileUrl,
                          isOutgoing: false,
                          avatarUrl: item.senderId?.avatar,
                          time: _formatTime(item.createdAt),
                        ),
                      ],
                    )
                  else ...[
                    // 2. Chat bubble for text content
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: appColor(context).bgGrey,
                          backgroundImage:
                              (item.senderId?.avatar != null &&
                                  item.senderId!.avatar!.isNotEmpty)
                              ? NetworkImage(item.senderId!.avatar!)
                              : null,
                          child:
                              (item.senderId?.avatar == null ||
                                  item.senderId!.avatar!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  color: appColor(context).silver,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 220),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEBEB),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.content ?? '',
                                style: fontStyle.clashDisplayMedium12
                                    .textColor(appColor(context).black)
                                    .size(12)
                                    .copyWith(height: 1.3),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  '2:20pm',
                                  style: fontStyle.clashDisplayRegular12
                                      .textColor(
                                        appColor(context).textSecondary,
                                      )
                                      .size(9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String label,
    Color bgColor,
    Color textColor, {
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: fontStyle.clashDisplayBold30.textColor(textColor).size(9),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: color == appColor(context).primary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? textColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: fontStyle.clashDisplaySemiBold18
                  .textColor(textColor)
                  .size(12),
            ),
          ],
        ),
      ),
    );
  }
}
