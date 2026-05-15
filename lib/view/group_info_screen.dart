import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/all_media_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupName;
  const GroupInfoScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    // Gorgeous scenery placeholders matching mockups
    final List<String> mediaImages = [
      "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400", // jungle
      "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=400", // nature hills
      "https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?w=400", // poppy field
      "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400", // forest landscape
    ];

    final List<Map<String, dynamic>> members = [
      {"name": "Maisie williams", "isAdmin": true},
      {"name": "Maisie williams", "isAdmin": true},
      {"name": "Maisie williams", "isAdmin": false},
      {"name": "Maisie williams", "isAdmin": false},
      {"name": "Maisie williams", "isAdmin": false},
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

              // 2. Center Group Profile Stack
              _buildProfileBlock(context),

              // 3. Action Deck (Audio, Video, Add)
              _buildActionRow(context),
              const SizedBox(height: 24),

              // 4. Metadata Segment (Status, Creator info)
              _buildMetadataSegment(context),
              const SizedBox(height: 32),

              // 5. Media Gallery Row
              _buildMediaSection(context, mediaImages),
              const SizedBox(height: 32),

              // 6. Members Listing Deck
              _buildMembersSection(context, members),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Top header aligned beautifully with a circular back shortcut
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
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

  /// Renders central circular Foliage avatar matching group visual styles
  Widget _buildProfileBlock(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Monstera greenery asset for the Family group icon
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appColor(context).grey100, width: 3),
            ),
            child: ClipOval(
              child: Image.network(
                "https://images.unsplash.com/photo-1545241047-6083a3684587?w=400",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: appColor(context).grey200,
                    child: Icon(
                      Icons.group,
                      color: appColor(context).grey400,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Group Title
          Text(
            groupName,
            style: fontStyle.clashDisplaySemiBold20.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 4),

          // Total member counts tag
          Text(
            "14 Members",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders Audio Call, Video Call, and user Add action matrix cards
  Widget _buildActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              label: "Audio Call",
              asset: ImageAssets.phone,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VoiceCallingScreen(userName: groupName),
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
                    builder: (context) =>
                        VideoCallingScreen(userName: groupName),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildActionCard(
              context,
              label: "Add",
              asset: ImageAssets.addPerson,
              onTap: () => _showAddMembersBottomSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Unified helper building floating Glassmorphism actions
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

  /// Renders Group Info Metadata such as Description Status and Creation timestamps
  Widget _buildMetadataSegment(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Happy Life 🥰",
            style: fontStyle.clashDisplayBold14.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Created by You on 12/12/2026",
            style: fontStyle.clashDisplayMedium12.textColor(
              appColor(context).grey400,
            ),
          ),
        ],
      ),
    );
  }

  /// Structured Media Horizontal Carousel for quick browsing of shared files
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

  /// Integrated listing housing member entries backed by dynamic role badge assignments
  Widget _buildMembersSection(
    BuildContext context,
    List<Map<String, dynamic>> memberData,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Add Members" trigger card row
          GestureDetector(
            onTap: () => _showAddMembersBottomSheet(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: appColor(
                        context,
                      ).secondary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        ImageAssets.userAdd,
                        width: 18,
                        height: 18,
                        color: appColor(context).secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Add Members",
                    style: fontStyle.clashDisplayBold14.textColor(
                      appColor(context).black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subtle partition divider
          Divider(color: appColor(context).grey100, height: 1),
          const SizedBox(height: 20),

          // Loop of physical group participants
          ...memberData.map((member) {
            final bool isAdmin = member["isAdmin"] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                children: [
                  // Member circular thumbnail
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage(ImageAssets.maisieAvatar),
                  ),
                  const SizedBox(width: 14),

                  // Text details block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member["name"]!,
                          style: fontStyle.clashDisplayBold14.textColor(
                            appColor(context).black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${(member["name"] as String).replaceAll(' ', '').toLowerCase()}@gmail.com",
                          style: fontStyle.clashDisplayMedium12.textColor(
                            appColor(context).grey300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin tag or Actions
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appColor(context).secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Group Admin",
                        style: fontStyle.clashDisplayMedium10.textColor(
                          appColor(context).white,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showConfirmationDialog(
                            context,
                            title: "Make Admin?",
                            content:
                                "Are you sure you want to make ${member["name"]} a group admin?",
                            onConfirm: () {
                              // Mock make admin action
                            },
                          ),
                          child: Icon(
                            Icons.person_add_alt,
                            color: appColor(context).secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showConfirmationDialog(
                            context,
                            title: "Remove Member?",
                            content:
                                "Are you sure you want to remove ${member["name"]} from the group?",
                            onConfirm: () {
                              // Mock remove action
                            },
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appColor(context).white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: fontStyle.clashDisplayBold18.textColor(
            appColor(context).black,
          ),
        ),
        content: Text(
          content,
          style: fontStyle.clashDisplayRegular14.textColor(
            appColor(context).grey400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: fontStyle.clashDisplayMedium14.textColor(
                appColor(context).grey300,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains("Remove")
                  ? Colors.red.shade400
                  : appColor(context).secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Confirm",
              style: fontStyle.clashDisplayBold14.textColor(
                appColor(context).white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMembersBottomSheet(BuildContext context) {
    final List<Map<String, String>> connectedUsers = [
      {"name": "Alice Johnson", "avatar": ImageAssets.obchild1},
      {"name": "Bob Wilson", "avatar": ImageAssets.obchild2},
      {"name": "Charlie Day", "avatar": ImageAssets.maisieAvatar},
      {"name": "Dave Smith", "avatar": ImageAssets.obchild1},
      {"name": "Eve Adams", "avatar": ImageAssets.obchild2},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Members",
                    style: fontStyle.clashDisplayBold18.textColor(
                      appColor(context).black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appColor(context).grey100,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: appColor(context).grey500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: connectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = connectedUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(user["avatar"]!),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              user["name"]!,
                              style: fontStyle.clashDisplaySemiBold14.textColor(
                                appColor(context).black,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Mock add action
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: appColor(context).secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Add",
                                style: fontStyle.clashDisplayBold12.textColor(
                                  appColor(context).white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
