import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/chat_settings_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatSettingsController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return Scaffold(
            backgroundColor: appColor(context).white,
            body: Center(
              child: CircularProgressIndicator(
                color: appColor(context).secondary,
              ),
            ),
          );
        }

        final bool showProfilePic = controller.showProfilePic;
        final bool showBio = controller.showBio;
        final bool showLastSeen = controller.showLastSeen;
        final bool readReceipts = controller.readReceipts;
        final bool typingIndicators = controller.typingIndicators;

        return Scaffold(
          backgroundColor: appColor(context).white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Navigation Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
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
                          "Chat Settings",
                          style: fontStyle.clashDisplaySemiBold20.textColor(
                            appColor(context).black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    _buildStatusPrivacyCard(context, controller),

                    // 2. Settings Group
                    _buildToggleCard(
                      context,
                      title: "Show Profile Picture",
                      subtitle: "Allow others to see your profile picture",
                      value: showProfilePic,
                      onChanged: (val) => controller.updateToggleSetting("show_profile_pic", val),
                    ),
                    _buildToggleCard(
                      context,
                      title: "Show Bio",
                      subtitle: "Display your 'About' information to contacts",
                      value: showBio,
                      onChanged: (val) => controller.updateToggleSetting("show_bio", val),
                    ),
                    _buildToggleCard(
                      context,
                      title: "Last Seen",
                      subtitle: "Show when you were last active",
                      value: showLastSeen,
                      onChanged: (val) => controller.updateToggleSetting("show_last_seen", val),
                    ),
                    _buildToggleCard(
                      context,
                      title: "Read Receipts",
                      subtitle: "Send and receive read confirmation (ticks)",
                      value: readReceipts,
                      onChanged: (val) => controller.updateToggleSetting("show_read_receipts", val),
                    ),
                    _buildToggleCard(
                      context,
                      title: "Typing Indicators",
                      subtitle: "Show when you are typing a message",
                      value: typingIndicators,
                      onChanged: (val) => controller.updateToggleSetting("show_typing_indicator", val),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Custom Expandable Status Privacy Card mimicking the user's uploaded design
  Widget _buildStatusPrivacyCard(BuildContext context, ChatSettingsController controller) {
    final bool isSelective = controller.statusPrivacy == "selective";
    final int visibleCount = isSelective
        ? controller.statusPrivacyList.length
        : controller.connectedUsers.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            "Status Privacy",
            style: fontStyle.clashDisplaySemiBold16.textColor(
              appColor(context).black,
            ),
          ),
          subtitle: Text(
            !isSelective ? "My connections" : "Only share with...",
            style: fontStyle.clashDisplayMedium12.textColor(
              appColor(context).grey600,
            ),
          ),
          iconColor: appColor(context).secondary,
          collapsedIconColor: appColor(context).grey400,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  _buildPrivacyOption(
                    context,
                    title: "My connections",
                    isSelected: !isSelective,
                    isLoading: controller.isUpdatingPrivacy && controller.updatingPrivacyOption == "contacts",
                    onTap: () => controller.updateStatusPrivacy("contacts"),
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyOption(
                    context,
                    title: "Only share with...",
                    isSelected: isSelective,
                    isLoading: controller.isUpdatingPrivacy && controller.updatingPrivacyOption == "selective",
                    showEdit: true,
                    onEditTap: () => _showConnectedUsersSelector(context, controller),
                    onTap: () => controller.updateStatusPrivacy("selective", privacyList: controller.statusPrivacyList),
                  ),
                  const SizedBox(height: 24),

                  // Info Box mimicking Image 3
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0F2FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF0284C7),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Status visible to all $visibleCount contacts",
                          style: fontStyle.clashDisplayMedium12.textColor(
                            const Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for privacy choices with custom checkbox styling
  Widget _buildPrivacyOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    bool isLoading = false,
    bool showEdit = false,
    VoidCallback? onEditTap,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? appColor(context).secondary
                        : appColor(context).grey300,
                    width: 1.5,
                  ),
                  color: isSelected
                      ? appColor(context).secondary
                      : Colors.transparent,
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isSelected ? Colors.white : appColor(context).secondary,
                        ),
                      )
                    : (isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: fontStyle.clashDisplayMedium14.textColor(
                  appColor(context).black,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (showEdit)
          GestureDetector(
            onTap: onEditTap,
            child: Icon(
              Icons.edit_note_rounded,
              color: appColor(context).secondary,
              size: 24,
            ),
          ),
      ],
    );
  }

  /// Styled card with a toggle switch matching the app's premium aesthetic
  Widget _buildToggleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 12.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: fontStyle.clashDisplaySemiBold16.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: fontStyle.clashDisplayMedium12.textColor(
                      appColor(context).grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: appColor(context).secondary,
                activeTrackColor: appColor(
                  context,
                ).secondary.withValues(alpha: 0.2),
                inactiveThumbColor: appColor(context).grey400,
                inactiveTrackColor: appColor(context).grey100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectedUsersSelector(BuildContext context, ChatSettingsController controller) {
    final List<String> tempSelectedList = List<String>.from(controller.statusPrivacyList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: appColor(context).white,
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
                      color: appColor(context).grey300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Connections",
                          style: fontStyle.clashDisplaySemiBold18.textColor(
                            appColor(context).black,
                          ),
                        ),
                        Text(
                          "${tempSelectedList.length} selected",
                          style: fontStyle.clashDisplayMedium12.textColor(
                            appColor(context).secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Connection list
                  Expanded(
                    child: controller.connectedUsers.isEmpty
                        ? Center(
                            child: Text(
                              "No connections found",
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).grey400,
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: controller.connectedUsers.length,
                            itemBuilder: (context, index) {
                              final friend = controller.connectedUsers[index];
                              final String id = friend["id"];
                              final String name = friend["name"];
                              final String subtitle = friend["subtitle"];
                              final String avatar = friend["avatar"];
                              final bool isSelected = tempSelectedList.contains(id);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: appColor(context).grey100,
                                  ),
                                  child: avatar.isEmpty
                                      ? Icon(Icons.person, color: appColor(context).grey400)
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            ApiService.getImageUrl(avatar),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: appColor(context).grey400),
                                          ),
                                        ),
                                ),
                                title: Text(
                                  name,
                                  style: fontStyle.clashDisplaySemiBold14.textColor(
                                    appColor(context).black,
                                  ),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: fontStyle.clashDisplayRegular12.textColor(
                                    appColor(context).grey600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  activeColor: appColor(context).secondary,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        tempSelectedList.add(id);
                                      } else {
                                        tempSelectedList.remove(id);
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
                      onTap: controller.isUpdatingPrivacy
                          ? null
                          : () async {
                              await controller.updateStatusPrivacy("selective", privacyList: tempSelectedList);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: appColor(context).secondary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: appColor(context).secondary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: controller.isUpdatingPrivacy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Apply Settings",
                                  style: fontStyle.clashDisplayMedium14.textColor(
                                    appColor(context).white,
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
  }
}
