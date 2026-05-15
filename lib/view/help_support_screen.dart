import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/view/support_tickets_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
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
                    Expanded(
                      child: Text(
                        "Help & Support",
                        style: fontStyle.clashDisplaySemiBold20.textColor(
                          appColor(context).black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. FAQ Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Frequently Asked Questions",
                  style: fontStyle.clashDisplaySemiBold18.textColor(
                    appColor(context).black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildFAQSection(context),

              const SizedBox(height: 32),

              // 3. Support Options Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Still need help?",
                  style: fontStyle.clashDisplaySemiBold18.textColor(
                    appColor(context).black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSupportOption(
                context: context,
                title: "Support Tickets",
                subtitle: "Create and track your support requests",
                icon: Icons.confirmation_number_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportTicketsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        "q": "How to backup my chats?",
        "a":
            "Your chats are automatically backed up to our secure cloud servers every 24 hours.",
      },
      {
        "q": "Can I use Shield Connect on multiple devices?",
        "a":
            "Yes, you can link up to 4 devices to your account simultaneously.",
      },
      {
        "q": "How to delete my account?",
        "a":
            "You can delete your account from the 'Account' settings menu. This action is permanent.",
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: appColor(context).black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              title: Text(
                faqs[index]['q']!,
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  appColor(context).black,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    faqs[index]['a']!,
                    style: fontStyle.clashDisplayMedium12.textColor(
                      appColor(context).grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: appColor(context).black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColor(context).secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: appColor(context).secondary, size: 24),
              ),
              const SizedBox(width: 16),
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
              Icon(
                Icons.chevron_right,
                color: appColor(context).grey400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

