import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        "type": "support_update",
        "title": "Support Update",
        "time": "5/14/2026, 11:12:33 AM",
        "subtitle": "Agent replied to ticket TCKT-039: hi",
      },
      {
        "type": "request_received",
        "title": "New Friend Request",
        "time": "10:25 AM",
        "subtitle": "Bruce Wayne sent you a friend request",
      },
      {
        "type": "request_sent",
        "title": "You Sent a Friend Request",
        "time": "10:25 AM",
        "subtitle": "You sent a follow request to bruce wayne",
      },
      {
        "type": "info",
        "title": "New Friend Request",
        "time": "10:25 AM",
        "subtitle": "Bruce Wayne accept your friend request",
      },
      {
        "type": "request_received",
        "title": "New Friend Request",
        "time": "10:25 AM",
        "subtitle": "Bruce Wayne sent you a friend request",
      },
      {
        "type": "request_sent",
        "title": "You Sent a Friend Request",
        "time": "10:25 AM",
        "subtitle": "You sent a follow request to bruce wayne",
      },
    ];

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
                ],
              ),
              const SizedBox(height: 24),

              // Compact Search Bar
              Container(
                decoration: BoxDecoration(
                  color: appColor(context).white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: appColor(context).black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  cursorColor: appColor(context).primary,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: fontStyle.clashDisplayRegular12.textColor(
                      appColor(context).grey400,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 10.0),
                      child: Image.asset(
                        ImageAssets.searchIcon,
                        width: 18,
                        height: 18,
                        color: appColor(context).secondary,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Today Sub-header
              Text(
                "Today",
                style: fontStyle.clashDisplayRegular12.textColor(
                  appColor(context).grey500,
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic compact notifications list
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(
                      context,
                      notifications[index],
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
  ) {
    final String type = item["type"] ?? "info";
    final String title = item["title"] ?? "";
    final String time = item["time"] ?? "";
    final String subtitle = item["subtitle"] ?? "";

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
              type == "support_update"
                  ? Container(
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
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          const AssetImage(ImageAssets.maisieAvatar),
                    ),
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
              if (type == "support_update")
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
          if (type != "info" && type != "support_update")
            const SizedBox(height: 12),

          // Action buttons (Compact Stadium styling)
          if (type == "request_received")
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: appColor(context).grey100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
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
                    onTap: () {},
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
                        child: Text(
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
            )
          else if (type == "request_sent")
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 36,
                  width: MediaQuery.of(context).size.width * 0.38,
                  decoration: BoxDecoration(
                    color: appColor(context).grey100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: fontStyle.clashDisplayMedium12.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
