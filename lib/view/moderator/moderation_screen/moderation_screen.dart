import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/moderation_controller.dart';
import 'package:shieldconnect_app/model/moderator/moderation_item.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/moderator/moderation_screen/moderation_details_screen.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

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
    required ModerationController controller,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: appColor(context).primary, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    "Confirm Action",
                    style: fontStyle.clashDisplayBold20.textColor(appColor(context).black).size(18),
                  ),
                ],
              ),
              content: Text(
                "Are you sure you want to change the status of this item to $displayStatus?",
                style: fontStyle.clashDisplayRegular14.textColor(appColor(context).darkText).size(14),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: fontStyle.clashDisplaySemiBold14.textColor(appColor(context).silver).size(14),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor(context).primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white).size(14),
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
    return Consumer<ModerationController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: appColor(context).bgGrey,
          appBar: _buildAppBar(context, controller),
          body: Column(
            children: [
              _buildCategories(context, controller),
              _buildSearchBar(context),
              Expanded(
                child: controller.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: appColor(context).secondary,
                        ),
                      )
                    : controller.moderationItems.isEmpty
                        ? Center(
                            child: Text(
                              "No moderation data available",
                              style: fontStyle.clashDisplayMedium12
                                  .textColor(appColor(context).silver)
                                  .size(14),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: controller.filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = controller.filteredItems[index];
                              return _buildModerationCard(
                                context,
                                controller,
                                item,
                                index,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ModerationController controller) {
    return AppBar(
      backgroundColor: appColor(context).white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: appColor(context).transparent,
      toolbarHeight: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Image.asset(ImageAssets.appIcon, height: 40, width: 40),
      ),
      leadingWidth: 60,
      title: Text(
        "Moderation",
        style: fontStyle.clashDisplayBold30
            .textColor(appColor(context).black)
            .size(20),
      ),
      centerTitle: false,
      actions: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: appColor(context).white,
            border: Border.all(color: appColor(context).bgGrey, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.filter_list,
              color: appColor(context).black,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: appColor(context).primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: () => controller.fetchHistory(),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(
    BuildContext context,
    ModerationController controller,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: controller.categories.map((category) {
          bool isSelected = controller.selectedCategory == category;
          return GestureDetector(
            onTap: () => controller.changeCategory(category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? appColor(context).primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? appColor(context).primary
                      : appColor(context).bgGrey.withOpacity(0.8),
                ),
              ),
              child: Text(
                category,
                style: fontStyle.clashDisplayMedium12
                    .textColor(
                      isSelected ? Colors.white : appColor(context).silver,
                    )
                    .size(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search...",
          hintStyle: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).silver)
              .size(14),
          prefixIcon: Icon(
            Icons.search,
            color: appColor(context).primary,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildModerationCard(
    BuildContext context,
    ModerationController controller,
    ModerationItem item,
    int index,
  ) {
    if (item.isProfileUpdate) {
      if (item.profileType == 'group') {
        return _buildGroupUpdateCard(context, controller, item);
      } else {
        return _buildUserUpdateCard(context, controller, item);
      }
    }

    bool isApproved = item.moderationStatus == "Approved";
    bool isRejected = item.moderationStatus == "Blocked";
    bool isEscalated = item.moderationStatus == "Escalate";

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.all((isRejected || isEscalated) ? 12 : 16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isApproved
          ? _buildApprovedCardContent(context, item)
          : isRejected
          ? _buildRejectedCardContent(context, item)
          : isEscalated
          ? _buildEscalatedCardContent(context, item)
          : _buildStandardCardContent(context, controller, item, index),
    );
  }

  Widget _buildGroupUpdateCard(
    BuildContext context,
    ModerationController controller,
    ModerationItem item,
  ) {
    bool isApproved = item.moderationStatus == "Approved";
    bool isRejected = item.moderationStatus == "Blocked";
    bool isEscalated = item.moderationStatus == "Escalate";
    bool isPending = item.moderationStatus == "Moderation";

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
              if (isApproved)
                _buildTag(
                  context,
                  "Safe",
                  const Color(0xFFE8F5E9),
                  const Color(0xFF2E7D32),
                )
              else if (isRejected)
                _buildTag(
                  context,
                  "Rejected",
                  appColor(context).bgGrey,
                  appColor(context).red,
                )
              else if (isEscalated)
                _buildTag(
                  context,
                  "Under Review",
                  appColor(context).orangeLight,
                  appColor(context).orange,
                )
              else
                _buildTag(
                  context,
                  "Pending",
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                )
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
                    if (item.pendingBio != null && item.pendingBio!.isNotEmpty) ...[
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTimestamp(item.createdAt),
                style: fontStyle.clashDisplayRegular12
                    .textColor(appColor(context).silver)
                    .size(9),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: ModerationDetailsScreen(item: item),
                      ),
                    ),
                  );
                },
                child: Text(
                  "View Details",
                  style: fontStyle.clashDisplaySemiBold18
                      .textColor(appColor(context).primary)
                      .size(11)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    "Approve",
                    appColor(context).primary,
                    Colors.white,
                    () => _showConfirmationDialog(
                      context: context,
                      item: item,
                      displayStatus: "Approved",
                      apiStatus: "Approved",
                      controller: controller,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    "Reject",
                    appColor(context).bgGrey,
                    appColor(context).red,
                    () => _showConfirmationDialog(
                      context: context,
                      item: item,
                      displayStatus: "Rejected",
                      apiStatus: "Blocked",
                      controller: controller,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserUpdateCard(
    BuildContext context,
    ModerationController controller,
    ModerationItem item,
  ) {
    bool isApproved = item.moderationStatus == "Approved";
    bool isRejected = item.moderationStatus == "Blocked";
    bool isEscalated = item.moderationStatus == "Escalate";
    bool isPending = item.moderationStatus == "Moderation";

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
              if (isApproved)
                _buildTag(
                  context,
                  "Safe",
                  const Color(0xFFE8F5E9),
                  const Color(0xFF2E7D32),
                )
              else if (isRejected)
                _buildTag(
                  context,
                  "Rejected",
                  appColor(context).bgGrey,
                  appColor(context).red,
                )
              else if (isEscalated)
                _buildTag(
                  context,
                  "Under Review",
                  appColor(context).orangeLight,
                  appColor(context).orange,
                )
              else
                _buildTag(
                  context,
                  "Pending",
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                )
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
                    if (item.pendingBio != null && item.pendingBio!.isNotEmpty) ...[
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTimestamp(item.createdAt),
                style: fontStyle.clashDisplayRegular12
                    .textColor(appColor(context).silver)
                    .size(9),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: ModerationDetailsScreen(item: item),
                      ),
                    ),
                  );
                },
                child: Text(
                  "View Details",
                  style: fontStyle.clashDisplaySemiBold18
                      .textColor(appColor(context).primary)
                      .size(11)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    "Approve",
                    appColor(context).primary,
                    Colors.white,
                    () => _showConfirmationDialog(
                      context: context,
                      item: item,
                      displayStatus: "Approved",
                      apiStatus: "Approved",
                      controller: controller,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    "Reject",
                    appColor(context).bgGrey,
                    appColor(context).red,
                    () => _showConfirmationDialog(
                      context: context,
                      item: item,
                      displayStatus: "Rejected",
                      apiStatus: "Blocked",
                      controller: controller,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEscalatedCardContent(
    BuildContext context,
    ModerationItem item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Escalation ID: ",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(11),
            ),
            Text(
              item.id.length > 6 ? item.id.substring(item.id.length - 6) : item.id,
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(11),
            ),
            const Spacer(),
            _buildTag(
              context,
              "Under Review",
              appColor(context).orangeLight,
              appColor(context).orange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSenderRecipientRow(context, item),
        const SizedBox(height: 8),
        Text(
          item.content ?? '',
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).black)
              .size(13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTag(
              context,
              item.messageType.toUpperCase(),
              appColor(context).primary.withOpacity(0.1),
              appColor(context).primary,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Escalated At",
                  style: fontStyle.clashDisplayBold30
                      .textColor(appColor(context).black)
                      .size(10),
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
      ],
    );
  }

  Widget _buildRejectedCardContent(
    BuildContext context,
    ModerationItem item,
  ) {
    return Column(
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
            const SizedBox(width: 8),
            Text(
              "Post ID: ",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(11),
            ),
            Text(
              item.id.length > 6 ? item.id.substring(item.id.length - 6) : item.id,
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSenderRecipientRow(context, item),
        const SizedBox(height: 8),
        Text(
          item.content ?? '',
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).black)
              .size(13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTag(
              context,
              item.messageType.toUpperCase(),
              appColor(context).primary.withOpacity(0.1),
              appColor(context).primary,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Rejected At",
                  style: fontStyle.clashDisplayBold30
                      .textColor(appColor(context).black)
                      .size(10),
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
      ],
    );
  }

  Widget _buildApprovedCardContent(
    BuildContext context,
    ModerationItem item,
  ) {
    return Column(
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
            const SizedBox(width: 8),
            Text(
              "Post ID: ",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(13),
            ),
            Text(
              item.id.length > 6 ? item.id.substring(item.id.length - 6) : item.id,
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSenderRecipientRow(context, item),
        const SizedBox(height: 12),
        Text(
          item.content ?? '',
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).black)
              .size(13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTag(
              context,
              "Safe",
              const Color(0xFFE8F5E9),
              const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 8),
            _buildTag(
              context,
              item.messageType.toUpperCase(),
              const Color(0xFFE3F2FD),
              const Color(0xFF1E88E5),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Approved At",
                  style: fontStyle.clashDisplayBold30
                      .textColor(appColor(context).black)
                      .size(11),
                ),
                Text(
                  _formatTimestamp(item.createdAt),
                  style: fontStyle.clashDisplayRegular12
                      .textColor(appColor(context).silver)
                      .size(10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardCardContent(
    BuildContext context,
    ModerationController controller,
    ModerationItem item,
    int index,
  ) {
    return Column(
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
            const SizedBox(width: 8),
            Text(
              item.id.length > 6 ? item.id.substring(item.id.length - 6) : item.id,
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(14),
            ),
            const SizedBox(width: 8),
            _buildTag(
              context,
              item.messageType.toUpperCase(),
              const Color(0xFFE3F2FD),
              const Color(0xFF1E88E5),
            ),
            const Spacer(),
            Icon(Icons.expand_more, color: appColor(context).silver),
          ],
        ),
        const SizedBox(height: 12),
        _buildSenderRecipientRow(context, item),
        const SizedBox(height: 12),
        Text(
          item.content ?? '',
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).black)
              .size(13),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTimestamp(item.createdAt),
              style: fontStyle.clashDisplayRegular12
                  .textColor(appColor(context).silver)
                  .size(11),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: ModerationDetailsScreen(item: item),
                    ),
                  ),
                );
              },
              child: Text(
                "View Details",
                style: fontStyle.clashDisplaySemiBold18
                    .textColor(appColor(context).primary)
                    .size(11)
                    .copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                "Approve",
                appColor(context).primary,
                Colors.white,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Approved",
                  apiStatus: "Approved",
                  controller: controller,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                "Reject",
                appColor(context).bgGrey,
                appColor(context).red,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Rejected",
                  apiStatus: "Blocked",
                  controller: controller,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                "Escalate",
                appColor(context).bgGrey,
                appColor(context).black,
                () => _showConfirmationDialog(
                  context: context,
                  item: item,
                  displayStatus: "Escalate",
                  apiStatus: "Escalate",
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSenderRecipientRow(BuildContext context, ModerationItem item) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: appColor(context).bgGrey,
          backgroundImage: (item.senderId?.avatar != null && item.senderId!.avatar!.isNotEmpty)
              ? NetworkImage(item.senderId!.avatar!)
              : null,
          child: (item.senderId?.avatar == null || item.senderId!.avatar!.isEmpty)
              ? Icon(Icons.person, size: 8, color: appColor(context).silver)
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          item.senderId?.name ?? 'Unknown',
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).black)
              .size(11),
        ),
        if (item.recipientId != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 10, color: appColor(context).silver),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 10,
            backgroundColor: appColor(context).bgGrey,
            backgroundImage: (item.recipientId!.avatar != null && item.recipientId!.avatar!.isNotEmpty)
                ? NetworkImage(item.recipientId!.avatar!)
                : null,
            child: (item.recipientId!.avatar == null || item.recipientId!.avatar!.isEmpty)
                ? Icon(Icons.person, size: 8, color: appColor(context).silver)
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
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
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
        text,
        style: fontStyle.clashDisplayBold30.textColor(textColor).size(10),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: fontStyle.clashDisplaySemiBold18.textColor(textColor).size(14),
        ),
      ),
    );
  }
}
