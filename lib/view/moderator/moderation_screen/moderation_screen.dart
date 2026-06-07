import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/moderation_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/moderator/moderation_screen/moderation_details_screen.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  void _showConfirmationDialog({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String displayStatus,
    required String apiStatus,
    required ModerationController controller,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
            "Are you sure you want to change the status of this message to $displayStatus?",
            style: fontStyle.clashDisplayRegular14.textColor(appColor(context).darkText).size(14),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: fontStyle.clashDisplaySemiBold14.textColor(appColor(context).silver).size(14),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor(context).primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final itemId = item['postId'] ?? item['_id'] ?? '';
                final success = await controller.updateItemStatus(
                  itemId: itemId,
                  status: apiStatus,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Successfully updated item status to $displayStatus"
                            : "Failed to update item status. Please try again.",
                        style: fontStyle.clashDisplayRegular12.textColor(Colors.white),
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                "Confirm",
                style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white).size(14),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModerationController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: appColor(context).bgGrey,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _buildCategories(context, controller),
              _buildSearchBar(context),
              Expanded(
                child: ListView.builder(
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            onPressed: () {},
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
    Map<String, dynamic> item,
    int index,
  ) {
    bool isApproved = item['status'] == "Approved";
    bool isRejected = item['status'] == "Rejected";
    bool isEscalated = item['status'] == "Escalations";

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

  Widget _buildEscalatedCardContent(
    BuildContext context,
    Map<String, dynamic> item,
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
              item['postId'],
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(11),
            ),
            const Spacer(),
            _buildTag(
              context,
              item['statusTag'] ?? "Under Review",
              appColor(context).orangeLight,
              appColor(context).orange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item['userName'],
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).black)
              .size(14),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Reason: ",
                style: fontStyle.clashDisplayMedium12
                    .textColor(appColor(context).primary)
                    .size(11),
              ),
              TextSpan(
                text: item['reason'],
                style: fontStyle.clashDisplayMedium12
                    .textColor(appColor(context).silver)
                    .size(11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTag(
              context,
              item['riskScore'],
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
                  item['timestamp'],
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
    Map<String, dynamic> item,
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
              item['postId'],
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item['userName'],
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).black)
              .size(14),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "Reason: ",
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(11),
            ),
            Text(
              item['reason'],
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTag(
              context,
              "Risk Score: ${item['riskScore']}",
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
                  item['timestamp'],
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
    Map<String, dynamic> item,
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
              item['postId'],
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).primary)
                  .size(13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item['userName'],
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).black)
              .size(16),
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
              "Confidence: ${item['confidence']}",
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
                  item['timestamp'],
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
    Map<String, dynamic> item,
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
              item['postId'],
              style: fontStyle.clashDisplayMedium12
                  .textColor(appColor(context).silver)
                  .size(14),
            ),
            const SizedBox(width: 8),
            Text(
              item['userName'],
              style: fontStyle.clashDisplayBold30
                  .textColor(appColor(context).black)
                  .size(14),
            ),
            const Spacer(),
            Icon(Icons.expand_more, color: appColor(context).silver),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTag(
              context,
              "Risk ${item['riskScore']}",
              appColor(context).primary.withOpacity(0.1),
              appColor(context).primary,
            ),
            const SizedBox(width: 8),
            ...item['tags']
                .map<Widget>(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTag(
                      context,
                      tag,
                      const Color(0xFFE3F2FD),
                      const Color(0xFF1E88E5),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item['content'],
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).black)
              .size(13),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item['timestamp'],
              style: fontStyle.clashDisplayRegular12
                  .textColor(appColor(context).silver)
                  .size(11),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModerationDetailsScreen(item: item),
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
