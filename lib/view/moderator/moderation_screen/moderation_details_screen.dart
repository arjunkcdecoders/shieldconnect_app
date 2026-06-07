import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/moderation_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class ModerationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const ModerationDetailsScreen({super.key, required this.item});

  void _showConfirmationDialog({
    required BuildContext context,
    required String displayStatus,
    required String apiStatus,
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
                final controller = Provider.of<ModerationController>(context, listen: false);
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
                  if (success) {
                    Navigator.pop(context);
                  }
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
                      Text(
                        item['postId'] ?? 'post-007',
                        style: fontStyle.clashDisplayMedium12
                            .textColor(Colors.white.withOpacity(0.8))
                            .size(12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['userName'] ?? 'SkyRunner',
                        style: fontStyle.clashDisplayBold30
                            .textColor(Colors.white)
                            .size(14),
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
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Text',
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
                        "Risk ${item['riskScore'] ?? '0.87'}",
                        Colors.white,
                        appColor(context).primary,
                        borderColor: appColor(context).primary,
                      ),
                      const SizedBox(width: 6),
                      _buildTag(
                        context,
                        "GROOMING",
                        const Color(0xFFE1F5FE),
                        const Color(0xFF00A3FF),
                      ),
                      const SizedBox(width: 6),
                      _buildTag(
                        context,
                        "TRUST_BUILDING",
                        const Color(0xFFE1F5FE),
                        const Color(0xFF00A3FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item['timestamp'] ?? '1/15/2025  8:45:00 PM',
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
              child: Text(
                item['content'] ??
                    'You seem so mature for your age. I\'ve never met anyone who understands me like you do. Can we talk somewhere more private?',
                style: fontStyle.clashDisplayMedium12
                    .textColor(appColor(context).black)
                    .size(12)
                    .copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
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

            // Detected Chat
            Text(
              'Detected Chat',
              style: fontStyle.clashDisplayBold30
                  .textColor(appColor(context).black)
                  .size(16),
            ),
            const SizedBox(height: 16),

            // Chat Preview
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image message
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 42, bottom: 4),
                      child: Text(
                        'Phoenix Baker',
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
                          backgroundImage: NetworkImage(
                            item['userImage'] ??
                                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=100',
                          ),
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
                                  'https://images.unsplash.com/photo-1548142813-c348350df52b?auto=format&fit=crop&q=80&w=400',
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
                ),
                const SizedBox(height: 16),

                // 2. Text message "Hiii"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 42, bottom: 4),
                      child: Text(
                        'Phoenix Baker',
                        style: fontStyle.clashDisplayMedium12
                            .textColor(appColor(context).textSecondary)
                            .size(11),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 42),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEBEB),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hiii',
                                style: fontStyle.clashDisplayMedium12
                                    .textColor(appColor(context).black)
                                    .size(12),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '2:20pm',
                                style: fontStyle.clashDisplayRegular12
                                    .textColor(appColor(context).textSecondary)
                                    .size(9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Text message "Let's get lunch soon! When are you free? 🤗"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        item['userImage'] ??
                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=100',
                      ),
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
                            "Let's get lunch soon! When are you free? 🤗",
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
                                  .textColor(appColor(context).textSecondary)
                                  .size(9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            Icon(icon, color: textColor, size: 16),
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
