import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/group_chat_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';

class MessageInfoBottomSheet extends StatelessWidget {
  final String messageId;
  final String? createdAt;
  final bool isGroup;
  final Map<String, dynamic>? groupDetails;
  final String currentUserId;

  const MessageInfoBottomSheet({
    super.key,
    required this.messageId,
    required this.createdAt,
    required this.isGroup,
    this.groupDetails,
    required this.currentUserId,
  });

  static void show(
    BuildContext context, {
    required String messageId,
    required String? createdAt,
    required bool isGroup,
    Map<String, dynamic>? groupDetails,
    required String currentUserId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(
        context,
      ).white, // Matches the app's clean white surface theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MessageInfoBottomSheet(
        messageId: messageId,
        createdAt: createdAt,
        isGroup: isGroup,
        groupDetails: groupDetails,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<GroupChatController>(
        context,
        listen: false,
      ).fetchMessageInfo(messageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                appColor(context).secondary,
              ), // Uses app's primary/secondary pink
            ),
          );
        }

        if (snapshot.hasError) {
          final String errorMsg = snapshot.error is Exception
              ? (snapshot.error as Exception).toString().replaceFirst(
                  'Exception: ',
                  '',
                )
              : "Error fetching message details";

          return Container(
            height: 250,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: appColor(context).red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMsg,
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    appColor(context).darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final infoData = snapshot.data;
        return isGroup
            ? _buildGroupInfoView(context, infoData)
            : _buildPersonalInfoView(context, infoData);
      },
    );
  }

  Widget _buildPersonalInfoView(
    BuildContext context,
    Map<String, dynamic>? infoData,
  ) {
    final String status = infoData?['status']?.toString() ?? 'sent';
    final String? readAt = infoData?['read_at']?.toString();

    final String readTimeStr = (status == 'read' && readAt != null)
        ? DateHelper.formatInfoDate(readAt)
        : '—';
    final String deliveredTime = status == 'sent'
        ? 'Not delivered yet'
        : DateHelper.formatInfoDate(createdAt);

    Widget readIcon;
    Widget deliveredIcon;

    if (status == 'read') {
      readIcon = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: appColor(context).green,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.done_all_rounded, color: Colors.white, size: 13),
        ),
      );
      deliveredIcon = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appColor(context).green, width: 1.5),
        ),
        child: Center(
          child: Icon(
            Icons.done_all_rounded,
            color: appColor(context).green,
            size: 13,
          ),
        ),
      );
    } else if (status == 'delivered') {
      readIcon = Icon(
        Icons.check_circle_outline,
        color: appColor(context).grey400,
        size: 22,
      );
      deliveredIcon = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appColor(context).green, width: 1.5),
        ),
        child: Center(
          child: Icon(
            Icons.done_all_rounded,
            color: appColor(context).green,
            size: 13,
          ),
        ),
      );
    } else {
      // status == 'sent' or other
      readIcon = Icon(
        Icons.check_circle_outline,
        color: appColor(context).grey400,
        size: 22,
      );
      deliveredIcon = Icon(
        Icons.check_circle_outline,
        color: appColor(context).green,
        size: 22,
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appColor(context).grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Message Info",
                  style: fontStyle.clashDisplayBold18.textColor(
                    appColor(context).darkText,
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: appColor(context).darkText,
                  size: 22,
                ),
              ],
            ),
          ),
          Divider(color: appColor(context).grey200, height: 1),
          // 1. Read Row
          _buildInfoRow(
            context,
            icon: readIcon,
            title: "Read",
            time: readTimeStr,
          ),
          Divider(color: appColor(context).grey200, height: 1, indent: 72),
          // 2. Delivered Row
          _buildInfoRow(
            context,
            icon: deliveredIcon,
            title: "Delivered",
            time: deliveredTime,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, height: 24, child: Center(child: icon)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    appColor(context).darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: fontStyle.clashDisplayRegular14.textColor(
                    appColor(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoView(
    BuildContext context,
    Map<String, dynamic>? infoData,
  ) {
    final List<dynamic> readByRaw = infoData?['read_by'] ?? [];
    final List<Map<String, dynamic>> readBy = readByRaw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Compile list of group members
    final dynamic rawMembers = groupDetails?['members'] ?? [];
    final List<dynamic> membersList = rawMembers is List ? rawMembers : [];

    final List<Map<String, dynamic>> seenByUsers = [];
    final List<Map<String, dynamic>> deliveredToUsers = [];

    for (var m in membersList) {
      final parsed = _parseMember(m);
      final String mId = parsed['id'] ?? '';
      if (mId.isEmpty || mId == currentUserId) continue;

      // Check if they are in readBy
      final readIndex = readBy.indexWhere((r) {
        final rUser = r['user_id'];
        final String rUserId = rUser is Map
            ? (rUser['_id'] ?? rUser['id'] ?? '').toString()
            : (rUser ?? '').toString();
        return rUserId == mId;
      });

      if (readIndex != -1) {
        final rItem = readBy[readIndex];
        seenByUsers.add({
          'name': parsed['name'],
          'avatar': parsed['avatar'],
          'time': DateHelper.formatInfoDate(rItem['read_at']?.toString()),
        });
      } else {
        deliveredToUsers.add({
          'name': parsed['name'],
          'avatar': parsed['avatar'],
          'time': DateHelper.formatInfoDate(createdAt),
        });
      }
    }

    final int remainingCount = deliveredToUsers.length;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appColor(context).grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Message Info",
                  style: fontStyle.clashDisplayBold18.textColor(
                    appColor(context).darkText,
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: appColor(context).darkText,
                  size: 22,
                ),
              ],
            ),
          ),
          Divider(color: appColor(context).grey200, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Seen By Section Title
                if (seenByUsers.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    title: "Seen by",
                    iconColor: appColor(
                      context,
                    ).darkText, // Matches app theme color
                  ),
                  ...seenByUsers.map((u) => _buildUserRow(u, context)),
                  if (remainingCount > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        "$remainingCount remaining",
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).textSecondary,
                        ),
                      ),
                    ),
                  Divider(color: appColor(context).grey200, height: 24),
                ],

                // 2. Delivered To Section
                if (deliveredToUsers.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    title: "Delivered to",
                    iconColor: appColor(context).grey400,
                  ),
                  ...deliveredToUsers.map((u) => _buildUserRow(u, context)),
                ],

                if (seenByUsers.isEmpty && deliveredToUsers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "No other members in this group",
                        style: fontStyle.clashDisplayRegular14.textColor(
                          appColor(context).textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required Color iconColor,
  }) {
    final bool isDelivered = (title == "Delivered to");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: fontStyle.clashDisplaySemiBold14.textColor(
              iconColor,
            ), // Dynamic color matching iconColor for theme consistency
          ),
          isDelivered
              ? Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: appColor(context).green,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.done_all_rounded,
                      color: appColor(context).green,
                      size: 11,
                    ),
                  ),
                )
              : Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: appColor(context).green,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.done_all_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> u, BuildContext context) {
    final String name = u['name'] ?? 'Group Member';
    final String avatar = u['avatar'] ?? '';
    final String time = u['time'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: appColor(context).grey200,
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(ApiService.getImageUrl(avatar))
                : null,
            child: avatar.isEmpty
                ? Icon(Icons.person, color: appColor(context).grey500, size: 20)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseMember(dynamic member) {
    if (member is! Map) return {};
    final userIdData = member['user_id'];
    if (userIdData is Map) {
      return {
        'id': (userIdData['_id'] ?? userIdData['id'] ?? '').toString(),
        'name': (userIdData['name'] ?? '').toString(),
        'avatar': (userIdData['avatar'] ?? '').toString(),
      };
    }
    return {
      'id': (member['_id'] ?? member['id'] ?? '').toString(),
      'name': (member['name'] ?? '').toString(),
      'avatar': (member['avatar'] ?? '').toString(),
    };
  }
}
