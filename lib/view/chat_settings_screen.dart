import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  // State for toggles
  bool _showProfilePic = true;
  bool _showBio = true;
  bool _showLastSeen = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;
  int _statusPrivacyIndex = 0; // 0 for My connections, 1 for Only share with

  @override
  Widget build(BuildContext context) {
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
                _buildStatusPrivacyCard(),

                // 2. Settings Group
                _buildToggleCard(
                  title: "Show Profile Picture",
                  subtitle: "Allow others to see your profile picture",
                  value: _showProfilePic,
                  onChanged: (val) => setState(() => _showProfilePic = val),
                ),
                _buildToggleCard(
                  title: "Show Bio",
                  subtitle: "Display your 'About' information to contacts",
                  value: _showBio,
                  onChanged: (val) => setState(() => _showBio = val),
                ),
                _buildToggleCard(
                  title: "Last Seen",
                  subtitle: "Show when you were last active",
                  value: _showLastSeen,
                  onChanged: (val) => setState(() => _showLastSeen = val),
                ),
                _buildToggleCard(
                  title: "Read Receipts",
                  subtitle: "Send and receive read confirmation (ticks)",
                  value: _readReceipts,
                  onChanged: (val) => setState(() => _readReceipts = val),
                ),
                _buildToggleCard(
                  title: "Typing Indicators",
                  subtitle: "Show when you are typing a message",
                  value: _typingIndicators,
                  onChanged: (val) => setState(() => _typingIndicators = val),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Custom Expandable Status Privacy Card mimicking the user's uploaded design
  Widget _buildStatusPrivacyCard() {
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
            _statusPrivacyIndex == 0 ? "My connections" : "Only share with...",
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
                    title: "My connections",
                    isSelected: _statusPrivacyIndex == 0,
                    onTap: () => setState(() => _statusPrivacyIndex = 0),
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyOption(
                    title: "Only share with...",
                    isSelected: _statusPrivacyIndex == 1,
                    showEdit: true,
                    onTap: () => setState(() => _statusPrivacyIndex = 1),
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
                          "Status visible to all 2 contacts",
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
  Widget _buildPrivacyOption({
    required String title,
    required bool isSelected,
    bool showEdit = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
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
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: fontStyle.clashDisplayMedium14.textColor(
                appColor(context).black,
              ),
            ),
          ),
          if (showEdit)
            Icon(
              Icons.edit_note_rounded,
              color: appColor(context).secondary,
              size: 24,
            ),
        ],
      ),
    );
  }

  /// Styled card with a toggle switch matching the app's premium aesthetic
  Widget _buildToggleCard({
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
        padding: const EdgeInsets.all(20.0),
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
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: appColor(context).secondary,
              activeTrackColor: appColor(
                context,
              ).secondary.withValues(alpha: 0.2),
              inactiveThumbColor: appColor(context).grey400,
              inactiveTrackColor: appColor(context).grey100,
            ),
          ],
        ),
      ),
    );
  }
}
