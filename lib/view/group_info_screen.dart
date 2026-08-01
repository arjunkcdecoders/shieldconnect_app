import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/group_chat_controller.dart';
import 'package:shieldconnect_app/controller/add_members_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/all_media_screen.dart';
import 'package:shieldconnect_app/view/voice_calling_screen.dart';
import 'package:shieldconnect_app/view/video_calling_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupName;
  final String groupId;
  const GroupInfoScreen({
    super.key,
    required this.groupName,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<GroupChatController>(
        context,
        listen: false,
      );
      if (controller.groupDetails == null ||
          (controller.groupDetails!['_id']?.toString() != groupId &&
              controller.groupDetails!['id']?.toString() != groupId)) {
        controller.fetchGroupDetails(groupId);
      }
    });
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Consumer<GroupChatController>(
          builder: (context, controller, child) {
            final details = controller.groupDetails;
            final isLoading = controller.isLoading;

            if (isLoading && details == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final String groupName =
                details?['name']?.toString() ?? this.groupName;
            final String? groupImage =
                details?['group_image']?.toString() ??
                details?['avatar']?.toString();
            final String description =
                details?['description']?.toString() ??
                "No description available";

            final List<Map<String, dynamic>> rawMembers = [];
            if (details?['members'] is List) {
              for (var item in details!['members']) {
                if (item is Map<String, dynamic>) {
                  rawMembers.add(item);
                } else if (item is Map) {
                  rawMembers.add(Map<String, dynamic>.from(item));
                }
              }
            }

            final int memberCount = rawMembers.length;

            final dynamic recentMedia =
                details?['recent_media'] ?? details?['medias'] ?? [];
            final List<String> mediaImages = [];
            if (recentMedia is List) {
              for (var m in recentMedia) {
                if (m is String) {
                  mediaImages.add(m);
                } else if (m is Map) {
                  final url = m['file_url'] ?? m['url'] ?? m['file'];
                  if (url != null) {
                    mediaImages.add(url.toString());
                  }
                }
              }
            }

            final dynamic adminVal = details != null
                ? details['admin_id']
                : null;
            final adminId = adminVal is Map ? adminVal['_id'] : adminVal;
            final String? adminIdStr = adminId?.toString();
            final bool showAdd =
                controller.userId != null && controller.userId == adminIdStr;

            bool isUserAdmin = false;
            final String? currentUserId = controller.userId;
            if (currentUserId != null) {
              if (currentUserId == adminIdStr) {
                isUserAdmin = true;
              } else {
                for (var member in rawMembers) {
                  final userMap = member['user_id'] is Map
                      ? member['user_id'] as Map
                      : null;
                  final String mId =
                      userMap?['_id']?.toString() ??
                      userMap?['id']?.toString() ??
                      (member['user_id'] is String
                          ? member['user_id']?.toString()
                          : null) ??
                      member['id']?.toString() ??
                      "";
                  if (mId == currentUserId) {
                    final String role =
                        member['role']?.toString().toLowerCase() ?? "member";
                    if (role == 'admin' || role == 'creator') {
                      isUserAdmin = true;
                    }
                    break;
                  }
                }
              }
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Custom Header Bar
                  _buildHeader(
                    context,
                    isUserAdmin,
                    groupName,
                    description,
                    groupImage,
                  ),

                  // 2. Center Group Profile Stack
                  _buildProfileBlock(
                    context,
                    groupName,
                    groupImage,
                    memberCount,
                  ),

                  // 3. Action Deck (Audio, Video, Add)
                  _buildActionRow(context, groupName, groupImage, isUserAdmin),
                  const SizedBox(height: 24),

                  // 4. Metadata Segment (Status, Creator info)
                  _buildMetadataSegment(context, description, details),
                  const SizedBox(height: 32),

                  // 5. Media Gallery Row
                  _buildMediaSection(
                    context,
                    mediaImages,
                    recentMedia is List ? recentMedia : [],
                  ),
                  const SizedBox(height: 32),

                  // 6. Members Listing Deck
                  _buildMembersSection(
                    context,
                    rawMembers,
                    controller,
                    isMainCreator: showAdd,
                    canAddMembers: isUserAdmin,
                  ),
                  const SizedBox(height: 24),

                  // 7. Leave Group Button
                  _buildLeaveGroupOption(
                    context,
                    controller,
                    rawMembers,
                    isUserAdmin,
                    memberCount,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Top header aligned beautifully with a circular back shortcut
  Widget _buildHeader(
    BuildContext context,
    bool canEdit,
    String groupName,
    String description,
    String? groupImage,
  ) {
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
                "Group Info",
                style: fontStyle.clashDisplaySemiBold18.textColor(
                  appColor(context).black,
                ),
              ),
            ],
          ),
          if (canEdit)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: appColor(context).black,
                size: 24,
              ),
              color: appColor(context).white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                final controller = Provider.of<GroupChatController>(
                  context,
                  listen: false,
                );
                if (value == 'edit') {
                  _showEditGroupDialog(
                    context,
                    groupName,
                    description,
                    groupImage,
                  );
                } else if (value == 'delete') {
                  _showDeleteGroupDialog(
                    context,
                    controller,
                    groupId,
                    groupName,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: appColor(context).black,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Edit Group",
                        style: fontStyle.clashDisplayMedium14.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Delete Group",
                        style: fontStyle.clashDisplayMedium14.textColor(
                          Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          // else
          //   Icon(Icons.more_vert, color: appColor(context).grey300, size: 24),
        ],
      ),
    );
  }

  void _showEditGroupDialog(
    BuildContext context,
    String currentName,
    String currentDesc,
    String? currentImage,
  ) {
    final controller = Provider.of<GroupChatController>(context, listen: false);
    final nameController = TextEditingController(text: currentName);
    final descController = TextEditingController(text: currentDesc);
    String? pickedImagePath;
    bool isSaving = false;
    bool showFailureText = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: appColor(context).white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Group Details",
                    style: fontStyle.clashDisplayBold18.textColor(
                      appColor(context).black,
                    ),
                  ),
                  if (!isSaving)
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Image Editor
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: appColor(context).grey100,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: pickedImagePath != null
                                ? Image.file(
                                    File(pickedImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    ApiService.getImageUrl(
                                      currentImage,
                                      isGroup: true,
                                    ),
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
                        GestureDetector(
                          onTap: isSaving
                              ? null
                              : () async {
                                  try {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 512,
                                      maxHeight: 512,
                                      imageQuality: 70,
                                    );
                                    if (image != null) {
                                      setDialogState(() {
                                        pickedImagePath = image.path;
                                      });
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      "Error picking image in edit dialog: $e",
                                    );
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: appColor(context).secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: appColor(context).white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: appColor(context).white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Group Name Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Group Name",
                          style: fontStyle.clashDisplayBold12.textColor(
                            appColor(context).black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: appColor(context).grey100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: nameController,
                            enabled: !isSaving,
                            style: fontStyle.clashDisplayMedium14.textColor(
                              appColor(context).black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter group name",
                              hintStyle: fontStyle.clashDisplayMedium14
                                  .textColor(appColor(context).grey400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: fontStyle.clashDisplayBold12.textColor(
                            appColor(context).black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: appColor(context).grey100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: descController,
                            enabled: !isSaving,
                            maxLines: 3,
                            style: fontStyle.clashDisplayMedium14.textColor(
                              appColor(context).black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter group description...",
                              hintStyle: fontStyle.clashDisplayMedium14
                                  .textColor(appColor(context).grey400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: Text(
                            "Cancel",
                            style: fontStyle.clashDisplayMedium14.textColor(
                              appColor(context).grey400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final String newName = nameController.text
                                      .trim();
                                  final String newDesc = descController.text
                                      .trim();

                                  if (newName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Group name cannot be empty.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isSaving = true;
                                  });

                                  final success = await controller.editGroup(
                                    name: newName,
                                    description: newDesc,
                                    imagePath: pickedImagePath,
                                  );

                                  if (success) {
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  } else {
                                    setDialogState(() {
                                      isSaving = false;
                                      showFailureText = true;
                                    });
                                    Future.delayed(
                                      const Duration(seconds: 3),
                                      () {
                                        if (dialogContext.mounted) {
                                          setDialogState(() {
                                            showFailureText = false;
                                          });
                                        }
                                      },
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColor(context).secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Save Changes",
                                  style: fontStyle.clashDisplayBold14.textColor(
                                    appColor(context).white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (showFailureText) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            "Failed to update",
                            style: fontStyle.clashDisplayMedium12.textColor(
                              Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteGroupDialog(
    BuildContext context,
    GroupChatController controller,
    String groupId,
    String groupName,
  ) {
    bool isDeleting = false;
    bool deleteFailed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: appColor(context).white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Delete Group",
                style: fontStyle.clashDisplayBold18.textColor(
                  appColor(context).black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Are you sure you want to delete '$groupName'? This action cannot be undone.",
                    style: fontStyle.clashDisplayRegular14.textColor(
                      appColor(context).grey400,
                    ),
                  ),
                  if (deleteFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 14.0),
                      child: Text(
                        "Unable to delete the group. Please try again.",
                        style: fontStyle.clashDisplayMedium12.textColor(
                          Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: fontStyle.clashDisplayMedium14.textColor(
                      appColor(context).grey300,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() {
                            isDeleting = true;
                            deleteFailed = false;
                          });
                          final success = await controller.deleteGroup(groupId);
                          if (success) {
                            if (context.mounted) {
                              try {
                                Provider.of<HomeScreenController>(
                                  context,
                                  listen: false,
                                ).fetchRecentChats();
                              } catch (_) {}
                              Navigator.pop(dialogContext);
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                            }
                          } else {
                            setState(() {
                              isDeleting = false;
                              deleteFailed = true;
                            });
                            Future.delayed(const Duration(seconds: 3), () {
                              if (dialogContext.mounted) {
                                setState(() {
                                  deleteFailed = false;
                                });
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isDeleting ? "Deleting..." : "Delete",
                    style: fontStyle.clashDisplayBold14.textColor(
                      appColor(context).white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Renders central circular avatar representing group chat imagery
  Widget _buildProfileBlock(
    BuildContext context,
    String name,
    String? imageUrl,
    int memberCount,
  ) {
    final groupImgUrl = ApiService.getImageUrl(imageUrl, isGroup: true);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appColor(context).grey100, width: 3),
            ),
            child: ClipOval(
              child: Image.network(
                groupImgUrl,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: fontStyle.clashDisplaySemiBold20.textColor(
                appColor(context).black,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Total member counts tag
          Text(
            "$memberCount ${memberCount == 1 ? 'Member' : 'Members'}",
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders Audio Call, Video Call, and user Add action matrix cards
  Widget _buildActionRow(
    BuildContext context,
    String groupName,
    String? groupImage,
    bool canAddMembers,
  ) {
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
                final controller = context.read<GroupChatController>();
                final List<String> memberIds = [];
                final gDetails = controller.groupDetails;
                final List<String> previousMemberIds = [];
                if (gDetails != null && gDetails['previous_members'] != null) {
                  final prevList = gDetails['previous_members'];
                  if (prevList is List) {
                    for (var pm in prevList) {
                      if (pm is Map) {
                        final userIdData = pm['user_id'];
                        String? pmId;
                        if (userIdData is Map) {
                          pmId = (userIdData['_id'] ?? userIdData['id'])?.toString();
                        } else if (userIdData != null) {
                          pmId = userIdData.toString();
                        } else {
                          pmId = (pm['_id'] ?? pm['id'])?.toString();
                        }
                        if (pmId != null && pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      } else if (pm != null) {
                        final pmId = pm.toString();
                        if (pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      }
                    }
                  }
                }

                if (gDetails != null && gDetails['members'] != null) {
                  final membersList = gDetails['members'];
                  if (membersList is List) {
                    final myId = context.read<CallManager>().myUserId;
                    for (var m in membersList) {
                      if (m is Map) {
                        final userIdData = m['user_id'];
                        String? mId;
                        if (userIdData is Map) {
                          mId = (userIdData['_id'] ?? userIdData['id'])?.toString();
                        } else if (userIdData != null) {
                          mId = userIdData.toString();
                        } else {
                          mId = (m['_id'] ?? m['id'])?.toString();
                        }
                        if (mId != null &&
                            mId.isNotEmpty &&
                            mId != myId &&
                            !previousMemberIds.contains(mId)) {
                          memberIds.add(mId);
                        }
                      }
                    }
                  }
                }
                context.read<CallManager>().startCall(
                  groupId,
                  groupName,
                  isVideo: false,
                  recipientAvatar: groupImage,
                  isGroup: true,
                  groupMemberIds: memberIds,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoiceCallingScreen(
                      userName: groupName,
                      avatarUrl: groupImage,
                    ),
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
                final controller = context.read<GroupChatController>();
                final List<String> memberIds = [];
                final gDetails = controller.groupDetails;
                final List<String> previousMemberIds = [];
                if (gDetails != null && gDetails['previous_members'] != null) {
                  final prevList = gDetails['previous_members'];
                  if (prevList is List) {
                    for (var pm in prevList) {
                      if (pm is Map) {
                        final userIdData = pm['user_id'];
                        String? pmId;
                        if (userIdData is Map) {
                          pmId = (userIdData['_id'] ?? userIdData['id'])?.toString();
                        } else if (userIdData != null) {
                          pmId = userIdData.toString();
                        } else {
                          pmId = (pm['_id'] ?? pm['id'])?.toString();
                        }
                        if (pmId != null && pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      } else if (pm != null) {
                        final pmId = pm.toString();
                        if (pmId.isNotEmpty) {
                          previousMemberIds.add(pmId);
                        }
                      }
                    }
                  }
                }

                if (gDetails != null && gDetails['members'] != null) {
                  final membersList = gDetails['members'];
                  if (membersList is List) {
                    final myId = context.read<CallManager>().myUserId;
                    for (var m in membersList) {
                      if (m is Map) {
                        final userIdData = m['user_id'];
                        String? mId;
                        if (userIdData is Map) {
                          mId = (userIdData['_id'] ?? userIdData['id'])?.toString();
                        } else if (userIdData != null) {
                          mId = userIdData.toString();
                        } else {
                          mId = (m['_id'] ?? m['id'])?.toString();
                        }
                        if (mId != null &&
                            mId.isNotEmpty &&
                            mId != myId &&
                            !previousMemberIds.contains(mId)) {
                          memberIds.add(mId);
                        }
                      }
                    }
                  }
                }
                context.read<CallManager>().startCall(
                  groupId,
                  groupName,
                  isVideo: true,
                  recipientAvatar: groupImage,
                  isGroup: true,
                  groupMemberIds: memberIds,
                );
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
          if (canAddMembers) ...[
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
        ],
      ),
    );
  }

  /// Unified helper building floating action cards
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

  /// Renders Group Info Metadata such as Description
  Widget _buildMetadataSegment(
    BuildContext context,
    String description,
    Map<String, dynamic>? details,
  ) {
    String createdByInfo = "Created recently";
    final dynamic detailsCreatedAt = details?['created_at'] ?? details?['createdAt'];
    if (detailsCreatedAt != null) {
      try {
        final parsedDate = DateTime.parse(detailsCreatedAt.toString());
        createdByInfo =
            "Created on ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: fontStyle.clashDisplayBold14.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            createdByInfo,
            style: fontStyle.clashDisplayMedium12.textColor(
              appColor(context).grey400,
            ),
          ),
        ],
      ),
    );
  }

  /// Structured Media Horizontal Carousel for quick browsing of shared files
  Widget _buildMediaSection(
    BuildContext context,
    List<String> images,
    List<dynamic> rawMediaItems,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllMediaScreen(mediaItems: rawMediaItems),
          ),
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
                  final mediaUrl = ApiService.getImageUrl(images[index]);
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

  /// Integrated listing housing member entries backed by dynamic role badge assignments
  Widget _buildMembersSection(
    BuildContext context,
    List<Map<String, dynamic>> rawMembers,
    GroupChatController controller, {
    required bool isMainCreator,
    required bool canAddMembers,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canAddMembers) ...[
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
          ],

          // Loop of physical group participants
          ...rawMembers.map((member) {
            final userMap = member['user_id'] is Map
                ? member['user_id'] as Map
                : null;
            final String mName =
                userMap?['name']?.toString() ??
                member['name']?.toString() ??
                "Member";
            final String? mAvatar =
                userMap?['avatar']?.toString() ?? member['avatar']?.toString();
            final String mEmail =
                userMap?['email']?.toString() ??
                member['email']?.toString() ??
                "${mName.replaceAll(' ', '').toLowerCase()}@gmail.com";

            final String mId =
                userMap?['_id']?.toString() ??
                userMap?['id']?.toString() ??
                (member['user_id'] is String
                    ? member['user_id']?.toString()
                    : null) ??
                member['id']?.toString() ??
                "";

            final String role =
                member['role']?.toString().toLowerCase() ?? "member";
            final bool isAdmin = role == 'admin' || role == 'creator';

            final dynamic adminVal = controller.groupDetails != null
                ? controller.groupDetails!['admin_id']
                : null;
            final adminId = adminVal is Map ? adminVal['_id'] : adminVal;
            final String? adminIdStr = adminId?.toString();
            final bool isMainAdmin = mId == adminIdStr;

            final memberAvatarUrl = ApiService.getImageUrl(mAvatar);

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                children: [
                  // Member circular thumbnail
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: appColor(context).grey100,
                    backgroundImage: memberAvatarUrl.isNotEmpty
                        ? NetworkImage(memberAvatarUrl)
                        : null,
                    child: memberAvatarUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            color: appColor(context).secondary,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Text details block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mName,
                          style: fontStyle.clashDisplayBold14.textColor(
                            appColor(context).black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mEmail,
                          style: fontStyle.clashDisplayMedium12.textColor(
                            appColor(context).grey300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin tag or Actions
                  if (isAdmin && controller.successAdminMemberId != mId)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
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
                        ),
                        if (isMainCreator && !isMainAdmin)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: GestureDetector(
                              onTap: () async {
                                if (mId.isNotEmpty) {
                                  await controller.demoteAdminToMember(mId);
                                }
                              },
                              child: controller.demotingAdminMemberId == mId
                                  ? Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: appColor(context).white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        height: 10,
                                        width: 10,
                                        child: CircularProgressIndicator(
                                          color: appColor(context).secondary,
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                    )
                                  : controller.failedDemoteMemberId == mId
                                  ? Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: appColor(context).white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red.shade700,
                                        size: 12,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: appColor(context).white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red.shade400,
                                        size: 10,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    )
                  else if ((canAddMembers && mId != controller.userId) ||
                      (isAdmin &&
                          controller.successAdminMemberId ==
                              mId)) // Hides icons for other members in group (only admin can remove/manage)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (mId.isNotEmpty) {
                              await controller.makeMemberAdmin(mId);
                            }
                          },
                          child: controller.makingAdminMemberId == mId
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: appColor(context).secondary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : controller.successAdminMemberId == mId
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.person_add_alt,
                                      color: appColor(context).secondary,
                                      size: 20,
                                    ),
                                    Positioned(
                                      right: -4,
                                      bottom: -4,
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.green.shade600,
                                        size: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : controller.failedAdminMemberId == mId
                              ? Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red.shade700,
                                  size: 20,
                                )
                              : Icon(
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
                                "Are you sure you want to remove $mName from the group?",
                            onConfirm: () async {
                              if (mId.isNotEmpty) {
                                await controller.removeMember(mId);
                              }
                            },
                          ),
                          child: controller.removingMemberId == mId
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 2,
                                  ),
                                )
                              : controller.failedMemberId == mId
                              ? Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red.shade700,
                                  size: 20,
                                )
                              : Icon(
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
              backgroundColor:
                  (title.contains("Remove") || title.contains("Leave"))
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
    final chatController = Provider.of<GroupChatController>(
      context,
      listen: false,
    );
    final String currentUserId = chatController.userId ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ChangeNotifierProvider<AddMembersController>(
          create: (context) =>
              AddMembersController()..init(currentUserId, groupId),
          child: Consumer<AddMembersController>(
            builder: (context, addController, child) {
              final friends = addController.friends;
              final selectedCount = friends
                  .where((f) => f['isSelected'] == true)
                  .length;

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
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
                        const SizedBox(height: 16),

                        // Search bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: appColor(context).grey100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: addController.searchController,
                            style: fontStyle.clashDisplayMedium14.textColor(
                              appColor(context).black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search connected users...",
                              hintStyle: fontStyle.clashDisplayMedium14
                                  .textColor(appColor(context).grey400),
                              icon: Icon(
                                Icons.search,
                                color: appColor(context).grey400,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // List / Loader
                        Expanded(
                          child: addController.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : friends.isEmpty
                              ? Center(
                                  child: Text(
                                    addController.searchController.text.isEmpty
                                        ? "No new connected users to add"
                                        : "No users matching '${addController.searchController.text}'",
                                    style: fontStyle.clashDisplayMedium14
                                        .textColor(appColor(context).grey300),
                                  ),
                                )
                              : ListView.builder(
                                  controller: addController.scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount:
                                      friends.length +
                                      (addController.hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == friends.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final user = friends[index];
                                    final bool isSelected =
                                        user["isSelected"] == true;
                                    final String avatarUrl =
                                        ApiService.getImageUrl(user["avatar"]);

                                    return InkWell(
                                      onTap: () {
                                        addController.toggleUserSelection(
                                          index,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                          horizontal: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: appColor(
                                                context,
                                              ).grey100,
                                              backgroundImage:
                                                  avatarUrl.isNotEmpty
                                                  ? NetworkImage(avatarUrl)
                                                  : null,
                                              child: avatarUrl.isEmpty
                                                  ? Icon(
                                                      Icons.person,
                                                      color: appColor(
                                                        context,
                                                      ).secondary,
                                                      size: 20,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user["name"]!,
                                                    style: fontStyle
                                                        .clashDisplaySemiBold14
                                                        .textColor(
                                                          appColor(
                                                            context,
                                                          ).black,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    user["subtitle"]!,
                                                    style: fontStyle
                                                        .clashDisplayMedium12
                                                        .textColor(
                                                          appColor(
                                                            context,
                                                          ).grey400,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Checkbox(
                                              value: isSelected,
                                              activeColor: appColor(
                                                context,
                                              ).secondary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              onChanged: (bool? checked) {
                                                addController
                                                    .toggleUserSelection(index);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Add Selected Button
                        if (selectedCount > 0) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: addController.isSaving
                                  ? null
                                  : () async {
                                      final success = await addController
                                          .addMembers(context: context);
                                      if (success && context.mounted) {
                                        // Refresh the group chat details using parent controller
                                        chatController.fetchGroupDetails(
                                          groupId,
                                        );
                                        chatController.fetchChatHistory(
                                          groupId,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColor(context).secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                              ),
                              child: addController.isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Add Selected ($selectedCount)",
                                      style: fontStyle.clashDisplayBold16
                                          .textColor(appColor(context).white),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLeaveGroupOption(
    BuildContext context,
    GroupChatController controller,
    List<Map<String, dynamic>> rawMembers,
    bool isUserAdmin,
    int memberCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: InkWell(
        onTap: () => _handleLeaveGroup(
          context,
          controller,
          rawMembers,
          isUserAdmin,
          memberCount,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 12),
              Text(
                "Leave Group",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLeaveGroup(
    BuildContext context,
    GroupChatController controller,
    List<Map<String, dynamic>> rawMembers,
    bool isUserAdmin,
    int memberCount,
  ) {
    if (isUserAdmin) {
      int adminCount = 0;
      for (var member in rawMembers) {
        final String role =
            member['role']?.toString().toLowerCase() ?? "member";
        if (role == 'admin' || role == 'creator') {
          adminCount++;
        }
      }

      if (adminCount <= 1 && memberCount > 1) {
        _showInfoAlert(
          context,
          title: "Action Blocked",
          content:
              "You are the only admin. Please promote another member to admin before leaving.",
        );
        return;
      }
    }

    _showConfirmationDialog(
      context,
      title: "Leave Group?",
      content:
          "Are you sure you want to leave this group? You will no longer receive any messages from this conversation.",
      onConfirm: () async {
        final success = await controller.leaveGroup(groupId);
        if (success) {
          if (context.mounted) {
            try {
              Provider.of<HomeScreenController>(
                context,
                listen: false,
              ).fetchRecentChats();
            } catch (e) {
              debugPrint("Error refreshing home chats: $e");
            }
            Navigator.of(context).pop(); // Return to GroupChatScreen
          }
        }
      },
    );
  }

  void _showInfoAlert(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appColor(context).white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade700,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: fontStyle.clashDisplayBold18.textColor(
                appColor(context).black,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: fontStyle.clashDisplayRegular14.textColor(
            appColor(context).grey400,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: appColor(context).secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Okay",
              style: fontStyle.clashDisplayBold14.textColor(
                appColor(context).white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
