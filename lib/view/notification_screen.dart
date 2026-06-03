import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationController>(context, listen: false)
          .fetchNotificationsInBackground();
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom App Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appColor(context).grey100,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left,
                          color: appColor(context).secondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Notifications",
                    style: fontStyle.clashDisplaySemiBold18.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const Spacer(),
                  Consumer<NotificationController>(
                    builder: (context, controller, child) {
                      if (controller.ticketNotifications.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: () => controller.clearAllNotifications(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appColor(context).grey100,
                          ),
                          child: Center(
                            child: controller.isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: appColor(context).secondary,
                                    ),
                                  )
                                : Image.asset(
                                    ImageAssets.deleteChat,
                                    width: 18,
                                    height: 18,
                                    color: appColor(context).secondary,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today Sub-header
              Text(
                "Recent",
                style: fontStyle.clashDisplayRegular12.textColor(
                  appColor(context).grey500,
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic compact notifications list
              Expanded(
                child: Consumer<NotificationController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return Center(child: CircularProgressIndicator(color: appColor(context).secondary));
                    }

                    // Combine and sort
                    final allItems = [
                      ...controller.ticketNotifications.map((n) => {...n.toJson(), "ui_type": "support_update", "sort_date": n.createdAt?.toIso8601String() ?? ""}),
                      ...controller.connectionRequests.map((r) => {...r, "ui_type": "request_received", "sort_date": r["updated_at"] ?? r["updatedAt"] ?? r["created_at"] ?? r["createdAt"] ?? ""}),
                    ];

                    allItems.sort((a, b) => b["sort_date"].toString().compareTo(a["sort_date"].toString()));

                    if (allItems.isEmpty) {
                      return Center(
                        child: Text(
                          "No notifications yet",
                          style: fontStyle.clashDisplayMedium14.textColor(appColor(context).grey400),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          context,
                          Map<String, dynamic>.from(allItems[index]),
                          controller,
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
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> item,
    NotificationController controller,
  ) {
    final String uiType = item["ui_type"] ?? "info";
    final String title = uiType == "support_update" 
        ? (item["title"] ?? "Support Update")
        : "New Friend Request";
    
    // Robust parsing for user details
    Map<String, dynamic>? userDetails;
    if (item["user_id"] is Map) {
      userDetails = Map<String, dynamic>.from(item["user_id"]);
    } else if (item["sender"] is Map) {
      userDetails = Map<String, dynamic>.from(item["sender"]);
    } else if (item["sender_id"] is Map) {
      userDetails = Map<String, dynamic>.from(item["sender_id"]);
    } else {
      userDetails = item;
    }

    final String? senderName = userDetails["name"]?.toString() ?? 
                               userDetails["displayName"]?.toString();
    
    final String? avatar = userDetails["avatar"]?.toString() ?? 
                           userDetails["profilePic"]?.toString() ?? 
                           userDetails["avatarUrl"]?.toString();

    final String subtitle = uiType == "support_update"
        ? (item["message"] ?? "")
        : "${senderName ?? "Someone"} sent you a friend request";
        
    final String time = DateHelper.formatTime(item["sort_date"]?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColor(context).grey100, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small Compact Avatar / Icon
              (avatar != null && avatar.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        ApiService.getImageUrl(avatar),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => uiType == "support_update"
                            ? _buildSupportFallback(context)
                            : _buildPersonFallback(context),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColor(context).grey100,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: appColor(context).secondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : uiType == "support_update"
                      ? _buildSupportFallback(context)
                      : _buildPersonFallback(context),
              const SizedBox(width: 12),
              // Notification Info Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: fontStyle.clashDisplaySemiBold14.textColor(
                        appColor(context).black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: fontStyle.clashDisplayRegular12.textColor(
                        appColor(context).textMediumGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: fontStyle.clashDisplayRegular12.textColor(
                        appColor(context).grey500,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (uiType == "support_update")
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appColor(context).grey100,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      color: appColor(context).grey500,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          if (uiType == "request_received") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                 Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final bool isRejectLoading = controller.loadingRejectRequestIds.contains(item["_id"]?.toString());
                      final bool isAcceptLoading = controller.loadingAcceptRequestIds.contains(item["_id"]?.toString());
                      if (isRejectLoading || isAcceptLoading) return;

                      final String? senderId = userDetails?["_id"]?.toString() ?? userDetails?["id"]?.toString();
                      final String? requestId = item["_id"]?.toString();
                      if (senderId != null && requestId != null) {
                        Provider.of<NotificationController>(context, listen: false)
                            .rejectConnection(requestId, senderId);
                      }
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: appColor(context).grey100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: controller.loadingRejectRequestIds.contains(item["_id"]?.toString())
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: appColor(context).black,
                                ),
                              )
                            : Text(
                                "Reject",
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  appColor(context).black,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final bool isRejectLoading = controller.loadingRejectRequestIds.contains(item["_id"]?.toString());
                      final bool isAcceptLoading = controller.loadingAcceptRequestIds.contains(item["_id"]?.toString());
                      if (isRejectLoading || isAcceptLoading) return;

                      final String? senderId = userDetails?["_id"]?.toString() ?? userDetails?["id"]?.toString();
                      final String? requestId = item["_id"]?.toString();
                      if (senderId != null && requestId != null) {
                        Provider.of<NotificationController>(context, listen: false)
                            .acceptConnection(requestId, senderId);
                      }
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: appColor(context).secondary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: appColor(context).secondary.withValues(
                                  alpha: 0.15,
                                ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: controller.loadingAcceptRequestIds.contains(item["_id"]?.toString())
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: appColor(context).white,
                                ),
                              )
                            : Text(
                                "Accept",
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  appColor(context).white,
                                ),
                              ),
                      ),
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

  Widget _buildSupportFallback(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appColor(context).secondary,
      ),
      child: Center(
        child: Icon(
          Icons.chat_bubble_outline,
          color: appColor(context).white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPersonFallback(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appColor(context).grey100,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: appColor(context).grey400,
          size: 24,
        ),
      ),
    );
  }
}
