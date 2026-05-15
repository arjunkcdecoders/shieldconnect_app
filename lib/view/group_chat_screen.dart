import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/group_info_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class GroupChatScreen extends StatelessWidget {
  final String groupName;

  const GroupChatScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Aesthetic Group Header
            _buildHeader(context),

            // 2. Dynamic Chat Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Date Header
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Today",
                        style: fontStyle.clashDisplayBold14.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ),
                  ),

                  // Incoming Bubble from a member
                  _buildIncomingText(
                    context,
                    senderName: "Alice Johnson",
                    text: "Hey everyone! Ready for the meeting?",
                    time: "10:00 am",
                    avatar: ImageAssets.obchild1,
                  ),
                  const SizedBox(height: 16),

                  // Outgoing Bubble
                  _buildOutgoingText(context, "Yes, I am ready!", "10:02 am"),
                  const SizedBox(height: 8),

                  // Incoming Bubble from another member
                  _buildIncomingText(
                    context,
                    senderName: "Bob Wilson",
                    text: "I might be 5 mins late.",
                    time: "10:05 am",
                    avatar: ImageAssets.obchild2,
                  ),
                  const SizedBox(height: 24),

                  // System Message / Status Bubble
                  _buildStatusBubble(
                    context,
                    asset: ImageAssets.approved,
                    title: "Group Rules Updated",
                    subtitle: "Please check the new guidelines in group info.",
                    titleColor: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                    time: "10:10 am",
                    isOutgoing:
                        false, // For example, show as incoming from system
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // 3. Footer Toolbar
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  /// Structuring navigation bar with group profile avatar and shortcuts
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: appColor(context).grey100, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back trigger
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: appColor(context).secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Tap target area linking to Group Info
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupInfoScreen(groupName: groupName),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: const NetworkImage(
                      "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: fontStyle.clashDisplaySemiBold16.textColor(
                            appColor(context).black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Alice, Bob, You",
                          style: fontStyle.clashDisplayRegular12.textColor(
                            appColor(context).grey400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Call shortcuts
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoiceCallingScreen(userName: groupName),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Image.asset(
                ImageAssets.phone,
                width: 22,
                height: 22,
                color: appColor(context).secondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallingScreen(userName: groupName),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Image.asset(
                ImageAssets.videoRecorder,
                width: 24,
                height: 24,
                color: appColor(context).secondary,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Three-dot popup menu
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: appColor(context).white,
            icon: Icon(Icons.more_vert, color: appColor(context).secondary),
            onSelected: (value) {
              // Handle actions
            },
            itemBuilder: (BuildContext context) {
              return [
                _buildPopupMenuItem(context, "Archive", ImageAssets.archive),
                _buildPopupMenuItem(context, "Clear", ImageAssets.clearChat),
                _buildPopupMenuItem(context, "Delete", ImageAssets.deleteChat),
                _buildPopupMenuItem(context, "Favorite", ImageAssets.favorite),
              ];
            },
          ),
        ],
      ),
    );
  }

  /// Creates high-stadium, visually unified popup row items driven by specific branding image assets
  PopupMenuItem<String> _buildPopupMenuItem(
    BuildContext context,
    String title,
    String asset,
  ) {
    return PopupMenuItem<String>(
      value: title,
      height: 46,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 20,
            height: 20,
            color: appColor(context).secondary,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: fontStyle.clashDisplaySemiBold14.textColor(
              appColor(context).black,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders Outgoing text widgets
  Widget _buildOutgoingText(BuildContext context, String text, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: appColor(context).secondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  text,
                  style: fontStyle.clashDisplayMedium14.textColor(
                    appColor(context).white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: fontStyle.clashDisplayMedium10.textColor(
                    appColor(context).white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildGreenTick(context),
      ],
    );
  }

  Widget _buildGreenTick(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: appColor(context).green,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.check, color: appColor(context).white, size: 11),
      ),
    );
  }

  /// Incoming message block with Sender Name
  Widget _buildIncomingText(
    BuildContext context, {
    required String senderName,
    required String text,
    required String time,
    required String avatar,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(radius: 14, backgroundImage: AssetImage(avatar)),
        const SizedBox(width: 8),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: appColor(context).grey100,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topLeft: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                senderName,
                style: fontStyle.clashDisplayBold12.textColor(
                  appColor(context).secondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: fontStyle.clashDisplayMedium14.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).grey400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBubble(
    BuildContext context, {
    required String asset,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color bgColor,
    required String time,
    bool isOutgoing = true,
  }) {
    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundImage: const NetworkImage(
              "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isOutgoing ? 40 : 0,
              right: isOutgoing ? 0 : 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: fontStyle.clashDisplaySemiBold12
                            .textColor(titleColor)
                            .copyWith(fontStyle: ui.FontStyle.italic),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).black.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          time,
                          style: fontStyle.clashDisplayMedium10.textColor(
                            appColor(context).grey400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOutgoing) ...[const SizedBox(width: 8), _buildGreenTick(context)],
      ],
    );
  }

  /// Integrated Footer Composer incorporating real interactive TextFields and conditional action bars
  Widget _buildComposer(BuildContext context) {
    bool isAttachmentOpen = false;
    const bool isNewChat = false; // Groups usually start as established

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: appColor(context).white,
            border: Border(
              top: BorderSide(color: appColor(context).grey100, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Input Field + Send trigger
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      cursorColor: appColor(context).primary,
                      style: fontStyle.clashDisplayRegular14.textColor(
                        appColor(context).black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type here...",
                        hintStyle: fontStyle.clashDisplayRegular14.textColor(
                          appColor(context).grey400,
                        ),
                        filled: true,
                        fillColor: appColor(context).grey50,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: appColor(context).grey200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: appColor(context).secondary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Image.asset(
                        ImageAssets.send,
                        width: 22,
                        height: 22,
                        color: appColor(context).secondary,
                      ),
                    ),
                  ),
                ],
              ),

              // Actions matrix
              if (!isNewChat) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Image.asset(
                          ImageAssets.cam,
                          width: 22,
                          height: 22,
                          color: appColor(context).black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showStickersBottomSheet(context),
                        child: Image.asset(
                          ImageAssets.emoji,
                          width: 22,
                          height: 22,
                          color: appColor(context).black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Image.asset(
                          ImageAssets.recorder,
                          width: 22,
                          height: 22,
                          color: appColor(context).black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAttachmentOpen = !isAttachmentOpen;
                          });
                        },
                        child: Image.asset(
                          isAttachmentOpen
                              ? ImageAssets.clipActive
                              : ImageAssets.paperclip,
                          width: 22,
                          height: 22,
                          color: isAttachmentOpen
                              ? null
                              : appColor(context).black87,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isAttachmentOpen) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttachmentOption(
                          context,
                          title: "Gallery",
                          asset: ImageAssets.gallery,
                          color: Colors.purple.shade700,
                        ),
                        _buildAttachmentOption(
                          context,
                          title: "Document",
                          asset: ImageAssets.file,
                          color: Colors.blue.shade700,
                        ),
                        _buildAttachmentOption(
                          context,
                          title: "Location",
                          asset: ImageAssets.map,
                          color: Colors.green.shade800,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required String title,
    required String asset,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: appColor(context).white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: appColor(context).black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(asset, width: 22, height: 22, color: color),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: fontStyle.clashDisplayBold12.textColor(
            appColor(context).black,
          ),
        ),
      ],
    );
  }

  void _showStickersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          height: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Stickers",
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
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: appColor(context).grey50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          [
                            "😊",
                            "🥰",
                            "🚀",
                            "🔥",
                            "🌈",
                            "🎈",
                            "🍕",
                            "🎸",
                            "🐱",
                            "🐶",
                            "🐻",
                            "🐼",
                          ][index % 12],
                          style: const TextStyle(fontSize: 32),
                        ),
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
