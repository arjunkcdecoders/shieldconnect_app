import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/contact_info_screen.dart';
import 'package:shieldconnect_app/view/group_info_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class ChatScreen extends StatelessWidget {
  final String userName;
  final bool isNewChat; // Enables conditionality for blank/new chat structures
  final bool isGroup;

  final bool isRequest;

  const ChatScreen({
    super.key,
    required this.userName,
    this.isNewChat = false,
    this.isGroup = false,
    this.isRequest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Aesthetic Chat Header
            _buildHeader(context),

            // 2. Dynamic Chat Body
            Expanded(
              child: isRequest
                  ? _buildRequestChatView(context)
                  : (isNewChat
                        ? _buildNewChatWelcome(context)
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Date Header
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    "Today",
                                    style: fontStyle.clashDisplayBold14
                                        .textColor(appColor(context).black),
                                  ),
                                ),
                              ),

                              // Outgoing Bubble 1
                              _buildOutgoingText(
                                context,
                                "Aww, thank you!",
                                "10:00 am",
                              ),
                              const SizedBox(height: 8),

                              // Outgoing Bubble 2
                              _buildOutgoingText(
                                context,
                                "🥰 It's been good so far how about yours?",
                                "10:00 am",
                              ),
                              const SizedBox(height: 8),

                              // Outgoing Voice Call Action card
                              _buildOutgoingVoiceCall(
                                context,
                                "3 Minutes",
                                "10:00 am",
                              ),
                              const SizedBox(height: 24),

                              // Incoming Voice Message Audio Player
                              _buildIncomingVoicePlayer(
                                context,
                                "00:09",
                                "10:00 am",
                              ),
                              const SizedBox(height: 16),

                              // Incoming standard Text Bubble
                              _buildIncomingText(
                                context,
                                "Hey! 😊",
                                "10:00 am",
                              ),
                              const SizedBox(height: 24),

                              // 3D Animal Status Indicator Bubbles added as per visual specs
                              _buildStatusBubble(
                                context,
                                asset: ImageAssets.blocked,
                                title: "Your message is blocked",
                                subtitle:
                                    "This message may contain inappropriate content that could make others uncomfortable.",
                                titleColor: const Color(0xFFB71C1C),
                                bgColor: const Color(0xFFFFEBEE)
                                  ..withValues(alpha: 0.5),
                                time: "10:00 am",
                                isOutgoing: true,
                              ),
                              const SizedBox(height: 16),

                              _buildStatusBubble(
                                context,
                                asset: ImageAssets.review,
                                title: "Your message is under review",
                                subtitle:
                                    "We're reviewing your message to keep everyone safe and respectful.",
                                titleColor: const Color(0xFF9C27B0),
                                bgColor: const Color(0xFFF3E5F5)
                                  ..withValues(alpha: 0.4),
                                time: "10:00 am",
                                isOutgoing: true,
                              ),
                              const SizedBox(height: 16),

                              _buildStatusBubble(
                                context,
                                asset: ImageAssets.approved,
                                title: "Your message is now approved!",
                                subtitle:
                                    "Great news! Your message follows follows our community guidelines and is ready to be sent.",
                                titleColor: const Color(0xFF2E7D32),
                                bgColor: const Color(
                                  0xFFE8F5E9,
                                ).withValues(alpha: 0.5),
                                time: "10:00 am",
                                isOutgoing: true,
                              ),
                              const SizedBox(height: 24),
                            ],
                          )),
            ),

            // 3. Footer Toolbar / Consent Drawer
            isRequest
                ? _buildRequestConsentPanel(context)
                : _buildComposer(context),
          ],
        ),
      ),
    );
  }

  /// Displays large Welcome card for brand-new chat streams initiated from suggestions list
  Widget _buildNewChatWelcome(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          // Large circular branding avatar seen centered on mockup
          Container(
            width: 108,
            height: 108,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(ImageAssets.maisieAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary header name
          Text(
            userName,
            style: fontStyle.clashDisplaySemiBold20.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 4),

          // Normalized descriptive email tagline
          Text(
            "${userName.replaceAll(' ', '').toLowerCase()}@gmail.com",
            style: fontStyle.clashDisplayRegular14.textColor(
              appColor(context).grey600,
            ),
          ),
          const SizedBox(height: 24),

          // Reactive Follow Button Component
          const _FollowButton(),
        ],
      ),
    );
  }

  /// Structuring navigation bar with profile avatars and conditional call routes
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

          // Tap target area enclosing Avatar and Name linking to Contact / Group Info screens
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isGroup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupInfoScreen(groupName: userName),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContactInfoScreen(name: userName),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  // Circular mini avatar representing connection
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: isGroup
                        ? const NetworkImage(
                                "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                              )
                              as ImageProvider
                        : const AssetImage(ImageAssets.maisieAvatar),
                  ),
                  const SizedBox(width: 12),

                  // Contact Name Title
                  Expanded(
                    child: Text(
                      userName,
                      style: fontStyle.clashDisplaySemiBold16.textColor(
                        appColor(context).black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Conditional shortcuts - Omit action bars for blank new chats
          if (!isNewChat && !isRequest) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VoiceCallingScreen(userName: userName),
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
                    builder: (context) =>
                        VideoCallingScreen(userName: userName),
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
            Theme(
              data: Theme.of(context).copyWith(
                splashColor: appColor(context).transparent,
                highlightColor: appColor(context).transparent,
              ),
              child: PopupMenuButton<String>(
                icon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.more_vert,
                    color: appColor(context).secondary,
                    size: 22,
                  ),
                ),
                padding: EdgeInsets.zero,
                color: appColor(context).white,
                surfaceTintColor: appColor(context).white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                offset: const Offset(
                  0,
                  46,
                ), // Places the card elegantly floating below the icon anchor
                onSelected: (value) {},
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem(context, "Archive", ImageAssets.archive),
                  _buildPopupMenuItem(
                    context,
                    "Clear Chat",
                    ImageAssets.clearChat,
                  ),
                  _buildPopupMenuItem(
                    context,
                    "Delete Chat",
                    ImageAssets.deleteChat,
                  ),
                  _buildPopupMenuItem(
                    context,
                    "Favorite",
                    ImageAssets.favorite,
                  ),
                  _buildPopupMenuItem(context, "Block", ImageAssets.block),
                  _buildPopupMenuItem(context, "Report", ImageAssets.report),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Renders Outgoing text widgets matching custom corner curves + status badge overlays
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

  /// Renders high-fidelity vibrant green delivery tick mirroring zoom reference
  Widget _buildGreenTick(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: appColor(
          context,
        ).green, // Exact vibrant green seen in zoom mockup
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.check, color: appColor(context).white, size: 11),
      ),
    );
  }

  /// Custom Voice Call Outgoing Bubble block
  Widget _buildOutgoingVoiceCall(
    BuildContext context,
    String duration,
    String time,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 170,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appColor(context).secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appColor(context).white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      ImageAssets.outgoingCall,
                      width: 18,
                      height: 18,
                      color: appColor(context).secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Voice Call",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).white,
                        ),
                      ),
                      Text(
                        duration,
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: fontStyle.clashDisplayMedium10.textColor(
                  appColor(context).white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Adding alignment spacing for the right badge stack column alignment
        const SizedBox(width: 24),
      ],
    );
  }

  /// Unified status bubble constructor delivering dynamic 3D animal status overlays
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
      mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOutgoing) ...[
          CircleAvatar(
            radius: 14,
            backgroundImage: const AssetImage(ImageAssets.maisieAvatar),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isOutgoing ? 40 : 0,
              right: isOutgoing ? 0 : 40,
            ), // Limits width keeping bubble small
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom 3D status animal asset
                Image.asset(asset, width: 48, height: 48, fit: BoxFit.contain),
                const SizedBox(width: 10),

                // Informative status headers and messages
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: fontStyle.clashDisplaySemiBold14
                            .textColor(titleColor)
                            .copyWith(fontStyle: ui.FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).black.withValues(alpha: 0.9),
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
        if (isOutgoing) ...[
          const SizedBox(width: 8),
          _buildGreenTick(context),
        ],
      ],
    );
  }

  /// Handcrafting complex Waveform Audio Players inside incoming message streams
  Widget _buildIncomingVoicePlayer(
    BuildContext context,
    String duration,
    String time,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: const AssetImage(ImageAssets.maisieAvatar),
        ),
        const SizedBox(width: 8),
        Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appColor(context).secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: appColor(context).white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reactive layout simulating high-fidelity Audio Frequency waveforms
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(13, (index) {
                        final double height = [
                          6.0,
                          12.0,
                          18.0,
                          10.0,
                          6.0,
                          16.0,
                          22.0,
                          18.0,
                          10.0,
                          14.0,
                          10.0,
                          6.0,
                          12.0,
                        ][index];
                        final bool isActive =
                            index < 5; // Simulated playback bounds
                        return Container(
                          width: 2,
                          height: height,
                          decoration: BoxDecoration(
                            color: isActive
                                ? appColor(context).black87
                                : appColor(context).grey300,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$duration •",
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).black54,
                    ),
                  ),
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

  /// Core textual incoming message block
  Widget _buildIncomingText(BuildContext context, String text, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: const AssetImage(ImageAssets.maisieAvatar),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
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
          child: Row(
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
        ),
      ],
    );
  }

  /// Integrated Footer Composer incorporating real interactive TextFields and conditional action bars
  Widget _buildComposer(BuildContext context) {
    bool isAttachmentOpen = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ), // Compressing padding for tighter, sleek profile
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
                  // Angled Send Plane Glyph
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

              // Actions matrix - ONLY visible on established chats
              if (!isNewChat) ...[
                const SizedBox(
                  height: 10,
                ), // Reduced spacing divider for compactness
                // Dynamic Action Matrix with image-based Assets
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
                          // Tint paperclip to black when inactive, let clipActive render its native branding colors!
                          color: isAttachmentOpen
                              ? null
                              : appColor(context).black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggled Attachment Drawer Area mimicking mockups
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

  /// Helper UI building the Stadium Circle options in the expanded attachment drawer
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

  /// Render SPECIAL Message Request Intro containing Centered Large Avatar Stack and one text bubble
  Widget _buildRequestChatView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 24),
        // Large central user branding avatar seen centered on mockup
        Center(
          child: Container(
            width: 108,
            height: 108,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(ImageAssets.maisieAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Bold Large contact name
        Center(
          child: Text(
            userName,
            style: fontStyle.clashDisplaySemiBold20.textColor(
              appColor(context).black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Normalized contact email subtitle
        Center(
          child: Text(
            "${userName.replaceAll(' ', '').toLowerCase()}@gmail.com",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Centered Today timeline label
        Center(
          child: Text(
            "Today",
            style: fontStyle.clashDisplayBold14.textColor(
              appColor(context).black,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Replicating Mockup single initial incoming text bubble
        _buildIncomingText(context, "Hey! 😊", "10:00 am"),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Anchored Bottom Message Request acceptance / block drawer replacing standard composer input block
  Widget _buildRequestConsentPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: BoxDecoration(color: appColor(context).white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The bold pink main query
          Text(
            "Accept message request from\n$userName?",
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayBold16.textColor(
              appColor(context).secondary,
            ),
          ),
          const SizedBox(height: 16),

          // Consent conditions tag
          Text(
            "If you accept, they will also be able to call you and see info such as your activity status and when you've read messages.",
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayRegular12.textColor(
              appColor(context).black.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 32),

          // 3 Dynamic Actions Stadium Cards: Block, Reject, Accept
          Row(
            children: [
              Expanded(
                child: _buildRequestActionCard(
                  context,
                  label: "Block",
                  textColor: appColor(context).black,
                  bgColor: appColor(context).grey200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRequestActionCard(
                  context,
                  label: "Reject",
                  textColor: const Color(
                    0xFFB71C44,
                  ), // Mockup custom deeper pink-red reject indicator
                  bgColor: appColor(context).grey200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRequestActionCard(
                  context,
                  label: "Accept",
                  textColor: appColor(context).white,
                  bgColor: appColor(context).secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generates stadium rounded cards mirroring custom action buttons
  /// Generates stadium rounded cards mirroring custom tactile 3D action buttons
  Widget _buildRequestActionCard(
    BuildContext context, {
    required String label,
    required Color textColor,
    required Color bgColor,
  }) {
    final bool isPink = bgColor == appColor(context).secondary;

    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          // Base sharp 3D tactile offset base
          BoxShadow(
            color: isPink ? const Color(0xFFB71C44) : const Color(0xFFCDCDCD),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
          // Soft blur drop shade below
          BoxShadow(
            color: isPink
                ? appColor(context).secondary.withValues(alpha: 0.2)
                : appColor(context).black.withValues(alpha: 0.05),
            offset: const Offset(0, 6),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          label,
          style: fontStyle.clashDisplaySemiBold14.textColor(textColor),
        ),
      ),
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

/// Dedicated internal Stateful component delivering dual-state toggle configuration for follow triggers
class _FollowButton extends StatefulWidget {
  const _FollowButton();

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowed = false; // Tracks whether request is active

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: !_isFollowed
          ? GestureDetector(
              key: const ValueKey("follow_action"),
              onTap: () {
                setState(() {
                  _isFollowed = true;
                });
              },
              child: Container(
                height: 36,
                width: 110,
                decoration: BoxDecoration(
                  color: appColor(context).secondary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFB71C44), // Solid 3D pink base
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: appColor(context).secondary.withValues(alpha: 0.2),
                      offset: const Offset(0, 6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "Follow",
                      style: fontStyle.clashDisplaySemiBold14.textColor(
                        appColor(context).white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Row(
              key: const ValueKey("requested_state"),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Outlined "Requested" container with dynamic checkmark
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: appColor(context).white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: appColor(context).secondary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        color: appColor(context).black,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Requested",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Solid 3D Grey "Cancel" button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFollowed = false;
                    });
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: appColor(context).grey200,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFFCDCDCD), // Solid 3D grey base
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: appColor(
                            context,
                          ).black.withValues(alpha: 0.05),
                          offset: const Offset(0, 6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          "Cancel",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
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
