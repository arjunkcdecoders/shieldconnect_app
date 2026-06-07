import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/call_list_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class CallListScreen extends StatelessWidget {
  const CallListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final callListController = Provider.of<CallListController>(context);
    final callItems = callListController.callHistory;
    final isLoading = callListController.isLoading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<CallManager>().fetchActiveGroupCalls();
      }
    });

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
                  Consumer<CallListController>(
                    builder: (context, callListController, child) {
                      final profileImageUrl = ApiService.getImageUrl(
                        callListController.profileImage,
                      );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: appColor(context).grey100,
                              image: profileImageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(profileImageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profileImageUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: appColor(context).grey400,
                                    size: 24,
                                  )
                                : null,
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
                      );
                    },
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Page Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Calls",
                    style: fontStyle.clashDisplayBold30.textColor(
                      appColor(context).black,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appColor(context).silver.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.add,
                        color: appColor(context).secondary,
                        size: 22,
                      ),
                    ),
                    color: appColor(context).white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'voice') {
                        _showConnectedMembersBottomSheet(
                          context,
                          isVideo: false,
                          callListController: callListController,
                        );
                      } else if (value == 'video') {
                        _showConnectedMembersBottomSheet(
                          context,
                          isVideo: true,
                          callListController: callListController,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'voice',
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              color: appColor(context).secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Voice Call",
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'video',
                        child: Row(
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              color: appColor(context).secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Video Call",
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                  onChanged: (val) {
                    callListController.searchCalls(val);
                  },
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

              // Active ongoing group call banner(s)
              Consumer<CallManager>(
                builder: (context, callManager, child) {
                  final activeCalls = callManager.activeGroupCalls;
                  if (activeCalls.isEmpty) return const SizedBox.shrink();

                  // Filter out calls that the user is currently actively in
                  final joinableCalls = activeCalls.entries.where((entry) {
                    final call = entry.value;
                    final callId = (call['_id'] ?? call['id'])?.toString();
                    return callManager.state == CallState.idle || callManager.currentCallId != callId;
                  }).toList();

                  if (joinableCalls.isEmpty) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: joinableCalls.map((entry) {
                      final call = entry.value;
                      final groupId = entry.key;
                      final groupName = call['group_name'] ?? call['group_id']?['name'] ?? 'Group Call';
                      final groupImage = call['group_avatar'] ?? call['group_id']?['group_image'] ?? call['group_id']?['avatar'];
                      final isVideo = call['call_type'] == 'video';
                      final roomId = (call['_id'] ?? call['id'] ?? call['roomId'])?.toString() ?? '';
                      final String? callerId = (call['initiator_id'] is Map
                          ? (call['initiator_id']['_id'] ?? call['initiator_id']['id'])?.toString()
                          : call['initiator_id']?.toString()) ?? call['callerId']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), // Premium dark theme
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "$groupName - Live Call",
                                    style: fontStyle.clashDisplaySemiBold14.textColor(Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isVideo ? "Tap Join Now to join the video call" : "Tap Join Now to join the voice call",
                                    style: fontStyle.clashDisplayRegular12.textColor(Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                callManager.joinCall(
                                  roomId,
                                  isVideo,
                                  groupId: groupId,
                                  groupName: groupName,
                                  groupAvatar: groupImage,
                                  callerId: callerId,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 0,
                              ),
                              child: Text(
                                "Join Now",
                                style: fontStyle.clashDisplayBold12.textColor(Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // Calls dynamic list
              Expanded(
                child: isLoading && callItems.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: appColor(context).primary,
                        ),
                      )
                    : callItems.isEmpty
                    ? Center(
                        child: Text(
                          "No call logs found",
                          style: fontStyle.clashDisplayMedium14.textColor(
                            appColor(context).textMediumGrey,
                          ),
                        ),
                      )
                    : ListView.builder(
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
    final String name = item["name"] ?? 'User';
    final String? avatar = item["avatar"];
    final bool isGroup = item["isGroup"] == true;

    final String typeText = isMissed
        ? 'Missed'
        : (isOutgoing ? 'Outgoing' : 'Incoming');
    final Color typeColor = isMissed
        ? appColor(context).red
        : (isOutgoing ? appColor(context).primary : appColor(context).green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar matching chat list sizes
          _buildAvatar(context, isGroup, name, avatar),
          const SizedBox(width: 16),

          // Middle Column Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fontStyle.clashDisplayBold16.textColor(
                    isMissed ? appColor(context).red : appColor(context).black,
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom arrow direction indicator (North-East for Outgoing, South-West for Missed/Incoming)
                        Icon(
                          isOutgoing ? Icons.north_east : Icons.south_west,
                          color: isMissed
                              ? appColor(context).red
                              : appColor(context).green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item["time"] ?? "",
                          style: fontStyle.clashDisplayRegular12.textColor(
                            appColor(context).textMediumGrey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        typeText,
                        style: fontStyle.clashDisplayBold10.textColor(typeColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Side Trigger Button
          GestureDetector(
            onTap: () {
              final callManager = Provider.of<CallManager>(context, listen: false);
              if (isGroup) {
                final String rawName = item['rawGroupName']?.toString() ?? '';
                final String displayName = item['name']?.toString() ?? '';
                final String groupName = (rawName.isEmpty ||
                        rawName == 'Group Call' ||
                        rawName.contains('+') ||
                        displayName.contains('+'))
                    ? 'Group Call'
                    : rawName;

                callManager.startCall(
                  item['groupId'] ?? '',
                  groupName,
                  isVideo: isVideoButton,
                  recipientAvatar: item['avatar'],
                  isGroup: true,
                  groupMemberIds: List<String>.from(item['groupMemberIds'] ?? []),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isVideoButton
                        ? VideoCallingScreen(userName: groupName)
                        : VoiceCallingScreen(
                            userName: groupName,
                            avatarUrl: item['avatar'],
                          ),
                  ),
                );
              } else {
                callManager.startCall(
                  item['recipientId'] ?? '',
                  item['name'] ?? 'User',
                  isVideo: isVideoButton,
                  recipientAvatar: item['avatar'],
                  isGroup: false,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isVideoButton
                        ? VideoCallingScreen(userName: item['name'] ?? 'User')
                        : VoiceCallingScreen(
                            userName: item['name'] ?? 'User',
                            avatarUrl: item['avatar'],
                          ),
                  ),
                );
              }
            },
            child: Icon(
              isVideoButton ? Icons.videocam_outlined : Icons.phone_outlined,
              color: appColor(context).secondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    bool isGroup,
    String name,
    String? avatar,
  ) {
    Widget buildGroupInitialsFallback() {
      final String initials = name.isNotEmpty ? name[0].toUpperCase() : "?";
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: appColor(context).secondary,
        ),
        child: Center(
          child: Text(
            initials,
            style: fontStyle.clashDisplayBold18.textColor(Colors.white),
          ),
        ),
      );
    }

    Widget buildUserFallback() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          ImageAssets.maisieAvatar,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    if (avatar == null || avatar.isEmpty) {
      return isGroup ? buildGroupInitialsFallback() : buildUserFallback();
    }

    final imageUrl = ApiService.getImageUrl(avatar);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: appColor(context).grey100),
        errorWidget: (context, url, error) =>
            isGroup ? buildGroupInitialsFallback() : buildUserFallback(),
      ),
    );
  }

  void _showConnectedMembersBottomSheet(
    BuildContext screenContext, {
    required bool isVideo,
    required CallListController callListController,
  }) {
    callListController.fetchConnectedUsers();

    final List<Map<String, dynamic>> tempSelectedList = [];

    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<CallListController>(
          builder: (consumerContext, controller, child) {
            final isLoading = controller.isLoadingConnected;
            final connected = controller.connectedUsers;

            return StatefulBuilder(
              builder: (modalContext, setModalState) {
                return Container(
                  height: MediaQuery.of(sheetContext).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: appColor(sheetContext).white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Grab handle / Top Bar
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: appColor(sheetContext).grey300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isVideo ? "New Video Call" : "New Voice Call",
                              style: fontStyle.clashDisplaySemiBold18.textColor(
                                appColor(sheetContext).black,
                              ),
                            ),
                            if (tempSelectedList.isNotEmpty)
                              Text(
                                "${tempSelectedList.length} selected",
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  appColor(sheetContext).secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Connection list
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: appColor(sheetContext).secondary,
                                ),
                              )
                            : connected.isEmpty
                                ? Center(
                                    child: Text(
                                      "No connections found",
                                      style: fontStyle.clashDisplayMedium14.textColor(
                                        appColor(sheetContext).grey400,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: connected.length,
                                    itemBuilder: (listContext, index) {
                                      final friend = connected[index];
                                      final String id = friend["id"];
                                      final String name = friend["name"];
                                      final String subtitle = friend["subtitle"];
                                      final String avatar = friend["avatar"];
                                      final bool isSelected = tempSelectedList.any((e) => e["id"] == id);

                                      return ListTile(
                                        onTap: () {
                                          setModalState(() {
                                            if (isSelected) {
                                              tempSelectedList.removeWhere((e) => e["id"] == id);
                                            } else {
                                              tempSelectedList.add(friend);
                                            }
                                          });
                                        },
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: appColor(sheetContext).grey100,
                                          ),
                                          child: avatar.isEmpty
                                              ? Icon(Icons.person, color: appColor(sheetContext).grey400)
                                              : ClipRRect(
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: Image.network(
                                                    ApiService.getImageUrl(avatar),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx, err, stack) =>
                                                        Icon(Icons.person, color: appColor(sheetContext).grey400),
                                                  ),
                                                ),
                                        ),
                                        title: Text(
                                          name,
                                          style: fontStyle.clashDisplaySemiBold14.textColor(
                                            appColor(sheetContext).black,
                                          ),
                                        ),
                                        subtitle: Text(
                                          subtitle,
                                          style: fontStyle.clashDisplayRegular12.textColor(
                                            appColor(sheetContext).grey600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Checkbox(
                                          value: isSelected,
                                          activeColor: appColor(sheetContext).secondary,
                                          onChanged: (val) {
                                            setModalState(() {
                                              if (val == true) {
                                                if (!isSelected) tempSelectedList.add(friend);
                                              } else {
                                                tempSelectedList.removeWhere((e) => e["id"] == id);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),

                      // Action Button
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: GestureDetector(
                          onTap: tempSelectedList.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(sheetContext); // Close bottom sheet
                                  final callManager = Provider.of<CallManager>(screenContext, listen: false);

                                  if (tempSelectedList.length == 1) {
                                    // 1-to-1 Call
                                    final friend = tempSelectedList.first;
                                    callManager.startCall(
                                      friend['id'] ?? '',
                                      friend['name'] ?? 'User',
                                      isVideo: isVideo,
                                      recipientAvatar: friend['avatar'],
                                      isGroup: false,
                                    );

                                    Navigator.push(
                                      screenContext,
                                      MaterialPageRoute(
                                        builder: (ctx) => isVideo
                                            ? VideoCallingScreen(userName: friend['name'] ?? 'User')
                                            : VoiceCallingScreen(
                                                userName: friend['name'] ?? 'User',
                                                avatarUrl: friend['avatar'],
                                              ),
                                      ),
                                    );
                                  } else {
                                    // Group Call
                                    final List<String> memberIds = tempSelectedList.map((f) => f['id'] as String).toList();
                                    final String firstFriendId = tempSelectedList.first['id'] ?? '';
                                    final String firstFriendAvatar = tempSelectedList.first['avatar'];

                                    callManager.startCall(
                                      firstFriendId,
                                      "Group Call",
                                      isVideo: isVideo,
                                      recipientAvatar: firstFriendAvatar,
                                      isGroup: true,
                                      groupMemberIds: memberIds,
                                    );

                                    Navigator.push(
                                      screenContext,
                                      MaterialPageRoute(
                                        builder: (ctx) => isVideo
                                            ? const VideoCallingScreen(userName: "Group Call")
                                            : VoiceCallingScreen(
                                                userName: "Group Call",
                                                avatarUrl: firstFriendAvatar,
                                              ),
                                      ),
                                    );
                                  }
                                },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: tempSelectedList.isEmpty
                                  ? appColor(sheetContext).grey300
                                  : appColor(sheetContext).secondary,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: tempSelectedList.isEmpty
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: appColor(sheetContext).secondary.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                tempSelectedList.isEmpty
                                    ? "Select members"
                                    : (tempSelectedList.length == 1
                                        ? (isVideo ? "Start Video Call" : "Start Voice Call")
                                        : (isVideo ? "Start Group Video Call" : "Start Group Voice Call")),
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  tempSelectedList.isEmpty
                                      ? appColor(sheetContext).grey500
                                      : appColor(sheetContext).white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
