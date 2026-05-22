import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/create_group_screen.dart';
import 'package:shieldconnect_app/view/chat_screen.dart';

class AddNewChatScreen extends StatelessWidget {
  const AddNewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Consumer<AddNewChatController>(
            builder: (context, controller, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom App Bar / Header
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
                        "Add New Chat",
                        style: fontStyle.clashDisplaySemiBold18.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: appColor(context).white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: appColor(
                            context,
                          ).black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.searchUsers,
                      cursorColor: appColor(context).primary,
                      decoration: InputDecoration(
                        hintText: "Search...",
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

                  // Create New Group
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateGroupScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appColor(context).grey100,
                          ),
                          child: Center(
                            child: Image.asset(
                              ImageAssets.newGroup,
                              width: 18,
                              height: 18,
                              color: appColor(context).secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Create New Group",
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider line
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF5F5F5),
                  ),
                  const SizedBox(height: 20),

                  // "People you may know" text header
                  Text(
                    "People you may know",
                    style: fontStyle.clashDisplaySemiBold14.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: "People",
                        isActive: controller.activeChipTab == "People",
                        onTap: () => controller.setActiveChipTab("People"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: "Friends",
                        isActive: controller.activeChipTab == "Friends",
                        onTap: () => controller.setActiveChipTab("Friends"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Suggested contacts list
                  Expanded(
                    child: controller.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: appColor(context).secondary,
                            ),
                          )
                        : controller.searchResults.isEmpty
                        ? Center(
                            child: Text(
                              "No users found",
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).grey400,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: controller.scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount:
                                controller.searchResults.length +
                                (controller.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == controller.searchResults.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: CircularProgressIndicator(
                                      color: appColor(context).secondary,
                                    ),
                                  ),
                                );
                              }
                              final user = controller.searchResults[index];
                              final relationship = user['relationship'];
                              final bool isRequested =
                                  relationship != null &&
                                  relationship['status'] == 'pending' &&
                                  relationship['requested_by'] != user['_id'];
                              final bool isBlockedByReceiver =
                                  relationship != null &&
                                  relationship['status'] == 'blocked' &&
                                  relationship['requested_by'] != user['_id'];
                              final bool isLoadingButton =
                                  controller.loadingUserIds.contains(user['_id']);

                              return _buildContactItem(
                                context,
                                userId: user['_id'] ?? "",
                                name: user['name'] ?? "Unknown",
                                subtitle: user['email'] ?? "",
                                avatar: user['avatar'],
                                isRequested: isRequested,
                                isBlockedByReceiver: isBlockedByReceiver,
                                status: relationship?['status'],
                                isLoadingButton: isLoadingButton,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required String userId,
    required String name,
    required String subtitle,
    required bool isRequested,
    required bool isBlockedByReceiver,
    required bool isLoadingButton,
    String? avatar,
    String? status,
  }) {
    String buttonText = "Connect";
    if (status == 'accepted') {
      buttonText = "Connected";
    } else if (isRequested) {
      buttonText = "Cancel";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userName: name,
              isNewChat: true,
              recipientId: userId,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          children: [
            // Circular Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColor(context).grey100,
                image: (avatar != null && avatar.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(ApiService.getImageUrl(avatar)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (avatar == null || avatar.isEmpty)
                  ? Icon(Icons.person, color: appColor(context).grey400)
                  : null,
            ),
            const SizedBox(width: 12),

            // Info Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: fontStyle.clashDisplaySemiBold14.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status == 'accepted' 
                        ? "Connected" 
                        : (isBlockedByReceiver
                            ? "Blocked"
                            : (isRequested ? "Requested" : subtitle)),
                    style: fontStyle.clashDisplayRegular12
                        .textColor(
                          isBlockedByReceiver
                              ? const Color(0xFFB71C1C)
                              : ((isRequested || status == 'accepted')
                                  ? appColor(context).secondary
                                  : appColor(context).grey300),
                        )
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action Button
            if (!isBlockedByReceiver)
              GestureDetector(
              onTap: () {
                if (status == 'accepted' || isLoadingButton) return;
                if (isRequested) {
                  context.read<AddNewChatController>().cancelConnection(userId);
                } else {
                  context.read<AddNewChatController>().connectUser(userId);
                }
              },
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                constraints: const BoxConstraints(minWidth: 74),
                decoration: BoxDecoration(
                  color: (isRequested || status == 'accepted')
                      ? appColor(context).grey200
                      : appColor(context).secondary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: (isRequested || status == 'accepted')
                      ? [
                          const BoxShadow(
                            color: Color(0xFFCDCDCD),
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
                        ]
                      : [
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: isLoadingButton
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: (isRequested || status == 'accepted')
                                  ? appColor(context).black
                                  : appColor(context).white,
                            ),
                          )
                        : Text(
                            buttonText,
                            style: fontStyle.clashDisplayMedium12
                                .textColor(
                                  (isRequested || status == 'accepted')
                                      ? appColor(context).black
                                      : appColor(context).white,
                                )
                                .copyWith(fontSize: 11),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? appColor(context).secondary : appColor(context).grey100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: appColor(context).secondary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: fontStyle.clashDisplaySemiBold12.textColor(
            isActive ? appColor(context).white : appColor(context).grey600,
          ),
        ),
      ),
    );
  }
}
