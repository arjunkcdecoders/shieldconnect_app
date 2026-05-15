import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/add_new_chat_screen.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';

class CallListScreen extends StatelessWidget {
  const CallListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> callItems = [
      {
        "name": "Maisie williams",
        "time": "14 April, 5:14 PM",
        "isMissed": false,
        "isOutgoing": true,
        "isVideoButton": false,
      },
      {
        "name": "Maisie williams",
        "time": "14 April, 5:14 PM",
        "isMissed": true,
        "isOutgoing": false,
        "isVideoButton": true,
      },
      {
        "name": "Maisie williams",
        "time": "14 April, 5:14 PM",
        "isMissed": false,
        "isOutgoing": true,
        "isVideoButton": false,
      },
      {
        "name": "Maisie williams",
        "time": "14 April, 5:14 PM",
        "isMissed": false,
        "isOutgoing": true,
        "isVideoButton": false,
      },
      {
        "name": "Maisie williams",
        "time": "14 April, 5:14 PM",
        "isMissed": true,
        "isOutgoing": false,
        "isVideoButton": true,
      },
      {
        "name": "Maisie williams",
        "time": "14 April, 5:14 PM",
        "isMissed": false,
        "isOutgoing": true,
        "isVideoButton": false,
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
              // Top Header row (matches chat list design)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile avatar stack
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage(ImageAssets.userAvatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: -4,
                        child: Image.asset(
                          ImageAssets.tick,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ],
                  ),
                  // Actions (Notification bell, Plus)
                  Row(
                    children: [
                      _buildHeaderAction(
                        context,
                        assetPath: ImageAssets.notification,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderAction(
                        context,
                        assetPath: ImageAssets.plus,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNewChatScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Page Title
              Text(
                "Calls",
                style: fontStyle.clashDisplayBold30.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar (matches chat list design dimensions)
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

              // Subheading "Recent"
              Text(
                "Recent",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 20),

              // Calls dynamic list
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: callItems.length,
                  itemBuilder: (context, index) {
                    return _buildCallItem(context, callItems[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    required String assetPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: appColor(context).silver.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 22,
            height: 22,
            color: appColor(context).secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCallItem(BuildContext context, Map<String, dynamic> item) {
    final bool isMissed = item["isMissed"] ?? false;
    final bool isOutgoing = item["isOutgoing"] ?? false;
    final bool isVideoButton = item["isVideoButton"] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        children: [
          // Avatar matching chat list sizes
          CircleAvatar(
            radius: 28,
            backgroundImage: const AssetImage(ImageAssets.maisieAvatar),
          ),
          const SizedBox(width: 16),

          // Middle Column Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item["name"],
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    isMissed ? appColor(context).red : appColor(context).black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Custom arrow direction indicator (North-East for Successful Outgoing/Incoming, South-West for Missed)
                    Icon(
                      isOutgoing ? Icons.north_east : Icons.south_west,
                      color: isMissed
                          ? appColor(context).red
                          : appColor(context).green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item["time"],
                      style: fontStyle.clashDisplayRegular12.textColor(
                        appColor(context).textMediumGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Side Trigger Button
          Icon(
            isVideoButton ? Icons.videocam_outlined : Icons.phone_outlined,
            color: appColor(context).secondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}
