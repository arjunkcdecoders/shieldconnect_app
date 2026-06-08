import 'dart:ui';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/controller/call_controller.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class AddCallMembersScreen extends StatelessWidget {
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final ValueNotifier<Set<String>> _selectedUserIds =
      ValueNotifier<Set<String>>({});
  final ValueNotifier<bool> _isAdding = ValueNotifier<bool>(false);
  final TextEditingController _searchController = TextEditingController();

  AddCallMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final callManager = Provider.of<CallManager>(context, listen: false);
    final String myId = callManager.myUserId ?? '';
    final String otherId = (callManager.myUserId == callManager.callerId)
        ? (callManager.receiverId ?? '')
        : (callManager.callerId ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CallController>(context, listen: false).fetchFriends(myId);
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
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
        ),
        title: Text(
          "Add Members",
          style: fontStyle.clashDisplaySemiBold18.textColor(
            appColor(context).black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Search Bar matching AddNewChatScreen style
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
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, query, child) {
                    return TextField(
                      controller: _searchController,
                      onChanged: (val) => _searchQuery.value = val,
                      cursorColor: appColor(context).primary,
                      style: fontStyle.clashDisplayMedium14.textColor(
                        appColor(context).black,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search friends...",
                        hintStyle: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).grey400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 10.0,
                          ),
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
                        suffixIcon: query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _searchQuery.value = '';
                                },
                                child: Icon(
                                  Icons.close,
                                  color: appColor(context).primary,
                                  size: 20,
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Friends List Section
              Expanded(
                child: Consumer<CallController>(
                  builder: (context, controller, child) {
                    if (controller.isLoadingFriends) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: appColor(context).secondary,
                        ),
                      );
                    }

                    if (controller.friendsErrorMessage != null) {
                      return Center(
                        child: Text(
                          controller.friendsErrorMessage!,
                          style: fontStyle.clashDisplayMedium14.textColor(
                            appColor(context).black,
                          ),
                        ),
                      );
                    }

                    final Set<String> existingUserIds = {myId, otherId};
                    for (final p in controller.participants) {
                      final pId = p['user_id'] ?? p['id'] ?? p['_id'];
                      if (pId != null) {
                        existingUserIds.add(pId.toString());
                      }
                    }

                    return ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, query, child) {
                        final lowercaseQuery = query.toLowerCase();

                        // Filter by query and exclude users already in call
                        final filteredFriends = controller.friends.where((
                          friend,
                        ) {
                          final friendId =
                              friend['user_id'] ??
                              friend['id'] ??
                              friend['_id'];
                          if (friendId == null ||
                              existingUserIds.contains(friendId.toString())) {
                            return false;
                          }
                          final String name = (friend['name'] ?? 'User')
                              .toString()
                              .toLowerCase();
                          return name.contains(lowercaseQuery);
                        }).toList();

                        if (filteredFriends.isEmpty) {
                          return Center(
                            child: Text(
                              controller.friends.isEmpty
                                  ? "No connected friends found."
                                  : "No friends are available right now",
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).grey500,
                              ),
                            ),
                          );
                        }

                        return ValueListenableBuilder<Set<String>>(
                          valueListenable: _selectedUserIds,
                          builder: (context, selectedIds, child) {
                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredFriends.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFF5F5F5),
                                  ),
                              itemBuilder: (context, index) {
                                final friend = filteredFriends[index];
                                final String friendName =
                                    friend['name'] ?? 'User';
                                final String? friendAvatar = friend['avatar'];
                                final String friendId =
                                    (friend['user_id'] ??
                                            friend['id'] ??
                                            friend['_id'])
                                        .toString();
                                final bool isSelected = selectedIds.contains(
                                  friendId,
                                );
                                final bool isOnline =
                                    friend['is_online'] == true;

                                return GestureDetector(
                                  onTap: () {
                                    final newSelected = Set<String>.from(
                                      selectedIds,
                                    );
                                    if (isSelected) {
                                      newSelected.remove(friendId);
                                    } else {
                                      newSelected.add(friendId);
                                    }
                                    _selectedUserIds.value = newSelected;
                                  },
                                  child: Container(
                                    color: Colors
                                        .transparent, // Ensure full row is tappable
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar with online/offline indicator dot
                                        Stack(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: appColor(
                                                    context,
                                                  ).grey200,
                                                  width: 1.5,
                                                ),
                                                color: appColor(
                                                  context,
                                                ).grey100,
                                              ),
                                              child:
                                                  (friendAvatar != null &&
                                                      friendAvatar.isNotEmpty)
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            ApiService.getImageUrl(
                                                              friendAvatar,
                                                            ),
                                                        fit: BoxFit.cover,
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => Icon(
                                                              Icons.person,
                                                              color: appColor(
                                                                context,
                                                              ).grey400,
                                                              size: 22,
                                                            ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      color: appColor(
                                                        context,
                                                      ).grey400,
                                                      size: 22,
                                                    ),
                                            ),
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: isOnline
                                                      ? const Color(0xFF1A9E16)
                                                      : appColor(
                                                          context,
                                                        ).grey400,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: appColor(
                                                      context,
                                                    ).white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 14),
                                        // Name and status details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                friendName,
                                                style: fontStyle
                                                    .clashDisplaySemiBold14
                                                    .textColor(
                                                      appColor(context).black,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isOnline ? "Online" : "Offline",
                                                style: fontStyle
                                                    .clashDisplayMedium10
                                                    .textColor(
                                                      isOnline
                                                          ? const Color(
                                                              0xFF1A9E16,
                                                            )
                                                          : appColor(
                                                              context,
                                                            ).grey400,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Custom Radio Selection Indicator
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? appColor(context).secondary
                                                  : appColor(context).grey300,
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? appColor(context).secondary
                                                      .withValues(alpha: 0.2)
                                                : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? Center(
                                                  child: Icon(
                                                    Icons.check,
                                                    color: appColor(
                                                      context,
                                                    ).secondary,
                                                    size: 14,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              // Bottom Action Button bar
              ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedUserIds,
                builder: (context, selectedIds, child) {
                  if (selectedIds.isEmpty) return const SizedBox.shrink();

                  return ValueListenableBuilder<bool>(
                    valueListenable: _isAdding,
                    builder: (context, adding, child) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        child: GestureDetector(
                          onTap: adding
                              ? null
                              : () async {
                                  _isAdding.value = true;
                                  try {
                                    final callId = callManager.currentCallId;
                                    if (callId != null) {
                                      final controller =
                                          Provider.of<CallController>(
                                            context,
                                            listen: false,
                                          );

                                      // Gather baseline lists for Me/existing members
                                      final List<String> pIds = [];
                                      final List<String> pNames = [];

                                      String? myName = callManager.myUserName;
                                      if (myName == null ||
                                          myName.isEmpty ||
                                          myName == 'User') {
                                        try {
                                          final profileController =
                                              Provider.of<ProfileController>(
                                                context,
                                                listen: false,
                                              );
                                          if (profileController
                                              .name
                                              .isNotEmpty) {
                                            myName = profileController.name;
                                          }
                                        } catch (_) {}
                                      }

                                      String? myAvatar =
                                          callManager.myUserAvatar;
                                      if (myAvatar == null ||
                                          myAvatar.isEmpty) {
                                        try {
                                          final profileController =
                                              Provider.of<ProfileController>(
                                                context,
                                                listen: false,
                                              );
                                          if (profileController
                                              .imageUrl
                                              .isNotEmpty) {
                                            myAvatar =
                                                profileController.imageUrl;
                                          }
                                        } catch (_) {}
                                      }

                                      if (callManager.myUserId != null) {
                                        pIds.add(callManager.myUserId!);
                                        pNames.add(myName ?? 'User');
                                      }

                                      for (final p in controller.participants) {
                                        final pId =
                                            (p['user_id'] ??
                                                    p['id'] ??
                                                    p['_id'])
                                                ?.toString();
                                        final pName =
                                            (p['name'] ??
                                                    p['username'] ??
                                                    'User')
                                                .toString();
                                        if (pId != null &&
                                            pId.isNotEmpty &&
                                            !pIds.contains(pId)) {
                                          pIds.add(pId);
                                          pNames.add(pName);
                                        }
                                      }

                                      // Loop and add all selected participants
                                      for (final id in selectedIds) {
                                        final success = await controller
                                            .addParticipant(callId, id);
                                        if (success) {
                                          final friend = controller.friends
                                              .firstWhere(
                                                (f) =>
                                                    (f['user_id'] ??
                                                            f['id'] ??
                                                            f['_id'])
                                                        ?.toString() ==
                                                    id,
                                                orElse: () =>
                                                    <String, dynamic>{},
                                              );
                                          final String friendName =
                                              friend['name'] ?? 'User';

                                          if (!pIds.contains(id)) {
                                            pIds.add(id);
                                            pNames.add(friendName);
                                          }

                                          final Map<String, dynamic>
                                          socketData = {
                                            'callId': callId,
                                            'roomId': callManager.currentRoomId,
                                            'callerId': callManager.myUserId,
                                            'callerName': myName,
                                            'callerAvatar': myAvatar,
                                            'receiverId': id,
                                            'receiverIds': [id],
                                            'isVideo': callManager.isVideo,
                                            'isGroup': true,
                                            'groupName': callManager.isGroup
                                                ? (callManager.receiverName ??
                                                      "Group Call")
                                                : (myName ?? "Group Call"),
                                            'group_name': callManager.isGroup
                                                ? (callManager.receiverName ??
                                                      "Group Call")
                                                : (myName ?? "Group Call"),
                                            'groupAvatar': callManager.isGroup
                                                ? (callManager.receiverAvatar ??
                                                      "")
                                                : (myAvatar ?? ""),
                                            'group_avatar': callManager.isGroup
                                                ? (callManager.receiverAvatar ??
                                                      "")
                                                : (myAvatar ?? ""),
                                            'participantIds': pIds,
                                            'participantNames': pNames,
                                            'participantsCount': pIds.length,
                                          };
                                          SocketService().emit(
                                            'call_user',
                                            socketData,
                                          );
                                        }
                                      }
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  } catch (e) {
                                    dev.log(
                                      "🚨 CallManager: Error adding call participants: $e",
                                    );
                                  } finally {
                                    _isAdding.value = false;
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: appColor(context).secondary,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                const BoxShadow(
                                  color: Color(0xFFB71C44),
                                  offset: Offset(0, 3),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: appColor(
                                    context,
                                  ).secondary.withValues(alpha: 0.25),
                                  offset: const Offset(0, 6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: adding
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: appColor(context).white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Add Selected Members (${selectedIds.length})",
                                      style: fontStyle.clashDisplayBold14
                                          .textColor(Colors.white),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
