import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/all_media_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class ContactInfoScreen extends StatelessWidget {
  final String name;
  const ContactInfoScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    // Fetching consistent network placeholders matching user mockups
    final List<String> mediaImages = [
      "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400", // jungle
      "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=400", // nature hills
      "https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?w=400", // poppy field
      "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400", // forest landscape
    ];

    final List<Map<String, String>> groupItems = [
      {"title": "Family", "members": "15 Members"},
      {"title": "Friends", "members": "15 Members"},
      {"title": "Relatives", "members": "15 Members"},
      {"title": "College", "members": "15 Members"},
    ];

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Custom Header Bar
              _buildHeader(context),

              // 2. Big Center Profile block
              _buildProfileBlock(context),

              // 3. Grid/Row of Action Cards
              _buildActionRow(context),
              const SizedBox(height: 32),

              // 4. Media Gallery Section
              _buildMediaSection(context, mediaImages),
              const SizedBox(height: 32),

              // 5. Groups in Common section
              _buildGroupsSection(context, groupItems),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Elegant top action bar with custom rounded pink back arrow
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Custom styled light-pink circular back container
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: appColor(context).secondary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: appColor(context).secondary,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                "Contact Info",
                style: fontStyle.clashDisplaySemiBold18.textColor(
                  appColor(context).black,
                ),
              ),
            ],
          ),
          Icon(Icons.more_vert, color: appColor(context).black, size: 24),
        ],
      ),
    );
  }

  /// Elevated Profile Stack housing the Big CircleAvatar and user info tags
  Widget _buildProfileBlock(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large 108x108 avatar matching mockups
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appColor(context).grey100, width: 3),
              image: const DecorationImage(
                image: AssetImage(ImageAssets.maisieAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bold Contact Name
          Text(
            name,
            style: fontStyle.clashDisplaySemiBold20.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 4),

          // Phone tag
          Text(
            "9898989898",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
          const SizedBox(height: 12),

          // Status emoji text
          Text(
            "Happy Life 🥰",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).black,
            ),
          ),
        ],
      ),
    );
  }

  /// Action deck holding Message, Audio Call and Video Call stadium-shadow cards
  Widget _buildActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              label: "Message",
              asset: ImageAssets.message,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildActionCard(
              context,
              label: "Audio Call",
              asset: ImageAssets.phone,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoiceCallingScreen(userName: name),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildActionCard(
              context,
              label: "Video Call",
              asset: ImageAssets.videoRecorder,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallingScreen(userName: name),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Helper UI yielding pristine glass-elevated action buttons
  Widget _buildActionCard(
    BuildContext context, {
    required String label,
    required String asset,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: appColor(context).white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: appColor(context).black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: 22,
              height: 22,
              color: appColor(context).secondary,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic Media Gallery builder displaying horizontal grid of recent documents
  Widget _buildMediaSection(BuildContext context, List<String> images) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllMediaScreen()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with total count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Media, Links and Docs",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).grey500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "14",
                      style: fontStyle.clashDisplayBold14.textColor(
                        appColor(context).black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: appColor(context).black,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal list of media thumbnails
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemBuilder: (context, index) {
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: appColor(context).grey200,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: appColor(context).grey400,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Vertical checklist structuring mutual connections and linked Groups
  Widget _buildGroupsSection(
    BuildContext context,
    List<Map<String, String>> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "4 Groups in Common",
            style: fontStyle.clashDisplayBold16.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 20),

          // Group Items
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                children: [
                  // Group Foliage Circular avatar representing Group chat imagery
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          color: appColor(context).grey200,
                          child: Icon(
                            Icons.group,
                            color: appColor(context).grey400,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Columns
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"]!,
                          style: fontStyle.clashDisplayBold16.textColor(
                            appColor(context).black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item["members"]!,
                          style: fontStyle.clashDisplayMedium12.textColor(
                            appColor(context).grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
