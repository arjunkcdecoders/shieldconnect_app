import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/bottomnav_controller.dart';
import 'package:shieldconnect_app/controller/moderator/moderator_home_controller.dart';
import 'package:shieldconnect_app/model/moderator/moderation_item.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    required ModerationItem item,
    required String displayStatus,
    required String apiStatus,
    required ModeratorHomeController controller,
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
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
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
                            Icons.close,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ModeratorHomeController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: appColor(context).white,
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context, controller),
                const SizedBox(height: 24),
                controller.isLoadingStats
                    ? SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: appColor(context).secondary,
                          ),
                        ),
                      )
                    : _buildStatsGrid(context, controller.dashboardStats),
                const SizedBox(height: 32),
                _buildSectionHeader(context, "Moderations"),
                const SizedBox(height: 16),
                _buildModerationList(context, controller),
                const SizedBox(height: 32),
                const SizedBox(height: 32),
                _buildSectionHeader(context, "Message Activity"),
                const SizedBox(height: 16),
                _buildActivityChart(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appColor(context).white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: appColor(context).transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Image.asset(ImageAssets.appIcon, height: 28, width: 28),
      ),
      leadingWidth: 56,
      title: Text(
        "Dashboard",
        style: fontStyle.clashDisplayBold30
            .textColor(appColor(context).black)
            .size(20),
      ),
      centerTitle: false,
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    ModeratorHomeController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome ${controller.moderatorName}",
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).primary)
              .size(18),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening in your chat app today",
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).grey600)
              .size(12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    List<Map<String, dynamic>> stats,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: appColor(context).black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['value'],
                style: fontStyle.clashDisplayBold30
                    .textColor(stat['color'])
                    .size(20),
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'],
                textAlign: TextAlign.center,
                style: fontStyle.clashDisplayMedium12
                    .textColor(appColor(context).black)
                    .size(10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModerationList(
    BuildContext context,
    ModeratorHomeController controller,
  ) {
    if (controller.isLoadingHistory) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: appColor(context).secondary),
        ),
      );
    }

    if (controller.moderationHistoryItems.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          "No moderation data available",
          style: fontStyle.clashDisplayMedium12
              .textColor(appColor(context).silver)
              .size(13),
        ),
      );
    }

    return Column(
      children: [
        ...controller.moderationHistoryItems.map((item) {
          if (item.isProfileUpdate) {
            if (item.profileType == 'group') {
              return _buildGroupUpdateCard(context, controller, item);
            } else {
              return _buildUserUpdateCard(context, controller, item);
            }
          } else {
            return _buildMessageCard(context, controller, item);
          }
        }),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              Provider.of<BottomnavController>(context, listen: false).changeIndex(2);
            },
            child: Text(
              "View All",
              style: fontStyle.clashDisplaySemiBold18
                  .textColor(appColor(context).primary)
                  .size(14)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupUpdateCard(
    BuildContext context,
    ModeratorHomeController controller,
    ModerationItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: appColor(context).primary, size: 18),
              const SizedBox(width: 6),
              Text(
                "GROUP PROFILE UPDATE",
                style: fontStyle.clashDisplayBold30
                    .textColor(appColor(context).black)
                    .size(10),
              ),
              const Spacer(),
              _buildActionButton(
                context,
                Icons.close,
                appColor(context).bgGrey,
                appColor(context).red,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Reject",
                  apiStatus: "Blocked",
                  controller: controller,
                ),
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                context,
                Icons.check,
                appColor(context).primary,
                appColor(context).white,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Approve",
                  apiStatus: "Approved",
                  controller: controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: appColor(context).bgGrey,
                backgroundImage: (item.pendingAvatar != null &&
                        item.pendingAvatar!.isNotEmpty)
                    ? NetworkImage(item.pendingAvatar!)
                    : (item.fileUrl != null && item.fileUrl!.isNotEmpty)
                        ? NetworkImage(item.fileUrl!)
                        : null,
                child: ((item.pendingAvatar == null || item.pendingAvatar!.isEmpty) &&
                        (item.fileUrl == null || item.fileUrl!.isEmpty))
                    ? Icon(
                        Icons.group,
                        color: appColor(context).silver,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pendingName ?? "Unnamed Group",
                      style: fontStyle.clashDisplayBold30
                          .textColor(appColor(context).black)
                          .size(13),
                    ),
                    if (item.pendingBio != null &&
                        item.pendingBio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.pendingBio!,
                        style: fontStyle.clashDisplayRegular14
                            .textColor(appColor(context).silver)
                            .size(11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTag(
                context,
                "Profile Check",
                const Color(0xFFFFF3E0),
                const Color(0xFFE65100),
              ),
              Text(
                _formatTimestamp(item.createdAt),
                style: fontStyle.clashDisplayRegular12
                    .textColor(appColor(context).silver)
                    .size(9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserUpdateCard(
    BuildContext context,
    ModeratorHomeController controller,
    ModerationItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: appColor(context).primary, size: 18),
              const SizedBox(width: 6),
              Text(
                "USER PROFILE UPDATE",
                style: fontStyle.clashDisplayBold30
                    .textColor(appColor(context).black)
                    .size(10),
              ),
              const Spacer(),
              _buildActionButton(
                context,
                Icons.close,
                appColor(context).bgGrey,
                appColor(context).red,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Reject",
                  apiStatus: "Blocked",
                  controller: controller,
                ),
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                context,
                Icons.check,
                appColor(context).primary,
                appColor(context).white,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Approve",
                  apiStatus: "Approved",
                  controller: controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: appColor(context).bgGrey,
                backgroundImage: (item.pendingAvatar != null &&
                        item.pendingAvatar!.isNotEmpty)
                    ? NetworkImage(item.pendingAvatar!)
                    : (item.fileUrl != null && item.fileUrl!.isNotEmpty)
                        ? NetworkImage(item.fileUrl!)
                        : null,
                child: ((item.pendingAvatar == null || item.pendingAvatar!.isEmpty) &&
                        (item.fileUrl == null || item.fileUrl!.isEmpty))
                    ? Icon(
                        Icons.person,
                        color: appColor(context).silver,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pendingName ?? "Unnamed User",
                      style: fontStyle.clashDisplayBold30
                          .textColor(appColor(context).black)
                          .size(13),
                    ),
                    if (item.pendingBio != null &&
                        item.pendingBio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.pendingBio!,
                        style: fontStyle.clashDisplayRegular14
                            .textColor(appColor(context).silver)
                            .size(11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTag(
                context,
                "Profile Check",
                const Color(0xFFE8F5E9),
                const Color(0xFF2E7D32),
              ),
              Text(
                _formatTimestamp(item.createdAt),
                style: fontStyle.clashDisplayRegular12
                    .textColor(appColor(context).silver)
                    .size(9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    ModeratorHomeController controller,
    ModerationItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                ImageAssets.messagedots,
                color: appColor(context).primary,
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 6),
              Text(
                item.id.length > 6
                    ? item.id.substring(item.id.length - 6)
                    : item.id,
                style: fontStyle.clashDisplayMedium12
                    .textColor(appColor(context).silver)
                    .size(10),
              ),
              const SizedBox(width: 8),
              _buildTag(
                context,
                item.messageType.toUpperCase(),
                const Color(0xFFE3F2FD),
                const Color(0xFF1E88E5),
              ),
              const Spacer(),
              _buildActionButton(
                context,
                Icons.close,
                appColor(context).bgGrey,
                appColor(context).red,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Reject",
                  apiStatus: "Blocked",
                  controller: controller,
                ),
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                context,
                Icons.check,
                appColor(context).primary,
                appColor(context).white,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Approve",
                  apiStatus: "Approved",
                  controller: controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
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
                        size: 8,
                        color: appColor(context).silver,
                      )
                    : null,
              ),
              const SizedBox(width: 4),
              Text(
                item.senderId?.name ?? 'mani',
                style: fontStyle.clashDisplayBold30
                    .textColor(appColor(context).black)
                    .size(11),
              ),
              if (item.recipientId != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 10,
                  color: appColor(context).silver,
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: appColor(context).bgGrey,
                  backgroundImage:
                      (item.recipientId!.avatar != null &&
                          item.recipientId!.avatar!.isNotEmpty)
                      ? NetworkImage(item.recipientId!.avatar!)
                      : null,
                  child:
                      (item.recipientId!.avatar == null ||
                          item.recipientId!.avatar!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 8,
                          color: appColor(context).silver,
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Text(
                  item.recipientId!.name,
                  style: fontStyle.clashDisplayBold30
                      .textColor(appColor(context).black)
                      .size(11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content ?? '',
            style: fontStyle.clashDisplayRegular14
                .textColor(appColor(context).black)
                .size(11),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTimestamp(item.createdAt),
            style: fontStyle.clashDisplayRegular12
                .textColor(appColor(context).silver)
                .size(9),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: fontStyle.clashDisplaySemiBold18.textColor(textColor).size(9),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: fontStyle.clashDisplayBold30
          .textColor(appColor(context).black)
          .size(16),
    );
  }

  Widget _buildRecentRegistrations(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: appColor(context).bgGrey),
      ),
      child: Column(
        children: [
          ...users.take(3).map((user) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: appColor(context).white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: appColor(context).black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(user['image']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                user['name'],
                                style: fontStyle.clashDisplayBold30
                                    .textColor(appColor(context).black)
                                    .size(14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user['country'],
                                  style: fontStyle.clashDisplaySemiBold18
                                      .textColor(appColor(context).textGrey)
                                      .size(9),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  ImageAssets.usFlag,
                                  height: 14,
                                  width: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user['email'],
                          style: fontStyle.clashDisplayRegular12
                              .textColor(appColor(context).textGrey)
                              .size(11),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user['phone'],
                          style: fontStyle.clashDisplayRegular12
                              .textColor(appColor(context).textMediumGrey)
                              .size(11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "View More",
              style: fontStyle.clashDisplaySemiBold18
                  .textColor(appColor(context).primary)
                  .size(12)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColor(context).bgGrey),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(painter: ChartPainter(appColor(context).primary)),
    );
  }
}

class ChartPainter extends CustomPainter {
  final Color color;
  ChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.4,
      size.width * 0.2,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.5,
      size.width * 0.4,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.9,
      size.width,
      size.height * 0.5,
    );

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
