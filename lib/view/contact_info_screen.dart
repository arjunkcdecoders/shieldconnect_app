import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/personal_chat_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/all_media_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class ContactInfoScreen extends StatelessWidget {
  final String name;
  final String recipientId;
  const ContactInfoScreen({
    super.key,
    required this.name,
    required this.recipientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Consumer<PersonalChatController>(
          builder: (context, controller, child) {
            final details = controller.personalDetails;
            final isLoading = controller.isContactInfoLoading;

            if (isLoading && details == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final String displayName = details?['name'] ?? name;
            final String avatarPath = details?['avatar'] ?? "";
            final String bio = details?['bio'] ?? "Hey there! I am using ShieldConnect.";
            
            final List<dynamic> mediaImages = details?['medias'] ?? [];
            final List<dynamic> groupsInCommon = details?['groupsInCommon'] ?? [];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Custom Header Bar
                  _buildHeader(context),

                  // 2. Big Center Profile block
                  _buildProfileBlock(context, displayName, avatarPath, bio),

                  // 3. Grid/Row of Action Cards
                  _buildActionRow(context, displayName),
                  const SizedBox(height: 32),

                  // 4. Media Gallery Section
                  _buildMediaSection(context, mediaImages),
                  const SizedBox(height: 32),

                  // 5. Groups in Common section
                  _buildGroupsSection(context, groupsInCommon),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
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
  Widget _buildProfileBlock(
    BuildContext context,
    String displayName,
    String avatarPath,
    String bio,
  ) {
    final avatarUrl = ApiService.getImageUrl(avatarPath);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large 108x108 avatar
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appColor(context).grey100, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: appColor(context).grey200,
                          child: Icon(
                            Icons.person,
                            color: appColor(context).secondary,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: appColor(context).grey200,
                      child: Icon(
                        Icons.person,
                        color: appColor(context).secondary,
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Bold Contact Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              style: fontStyle.clashDisplaySemiBold20.textColor(
                appColor(context).black,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status emoji text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: fontStyle.clashDisplayMedium14.textColor(
                appColor(context).black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Action deck holding Message, Audio Call and Video Call stadium-shadow cards
  Widget _buildActionRow(BuildContext context, String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              label: "Message",
              asset: ImageAssets.message,
              onTap: () => Navigator.pop(context), // Pop back to chat
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
                    builder: (context) => VoiceCallingScreen(userName: displayName),
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
                    builder: (context) => VideoCallingScreen(userName: displayName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Helper UI yielding pristine action buttons
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
  Widget _buildMediaSection(BuildContext context, List<dynamic> images) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AllMediaScreen(mediaItems: images)),
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
                      images.length.toString(),
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
          if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "No shared media yet",
                style: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).grey300,
                ),
              ),
            )
          else
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: images.length,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemBuilder: (context, index) {
                  final mediaUrl = ApiService.getImageUrl(images[index].toString());
                  return Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        mediaUrl,
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
    List<dynamic> items,
  ) {
    final int count = items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$count ${count == 1 ? 'Group' : 'Groups'} in Common",
            style: fontStyle.clashDisplayBold16.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 20),

          // Group Items
          if (items.isEmpty)
            Text(
              "No mutual groups",
              style: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).grey300,
              ),
            )
          else
            ...items.map((item) {
              final gName = item["name"]?.toString() ?? "Group";
              final gImage = item["group_image"]?.toString() ?? "";
              final int mCount = item["membersCount"] is int ? item["membersCount"] as int : 0;
              final groupAvatarUrl = ApiService.getImageUrl(gImage, isGroup: true);

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    // Group avatar representing Group chat imagery
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        groupAvatarUrl,
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
                            gName,
                            style: fontStyle.clashDisplayBold16.textColor(
                              appColor(context).black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$mCount ${mCount == 1 ? 'Member' : 'Members'}",
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
