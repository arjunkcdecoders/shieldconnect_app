import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/view/ticket_details_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
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
                    Text(
                      "Help & Support",
                      style: fontStyle.clashDisplaySemiBold20.textColor(
                        appColor(context).black,
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
              _buildFAQSection(),

              const SizedBox(height: 32),

              // 3. Support Tickets Section
              _buildSupportTicketsSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
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

  Widget _buildSupportTicketsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Support Tickets",
                style: fontStyle.clashDisplaySemiBold18.textColor(
                  appColor(context).black,
                ),
              ),
              GestureDetector(
                onTap: () => _showCreateTicketBottomSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: appColor(context).secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Create Ticket",
                        style: fontStyle.clashDisplaySemiBold12.textColor(
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ticket Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard("All", "1", Icons.forum_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard("Pending", "1", Icons.timer_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Closed",
                  "0",
                  Icons.event_available_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search & Filter
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: appColor(context).grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search Subject or ID",
                      hintStyle: fontStyle.clashDisplayMedium12.textColor(
                        appColor(context).grey400,
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search,
                        color: appColor(context).grey400,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: appColor(context).grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: appColor(context).secondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            "Latest Support History",
            style: fontStyle.clashDisplaySemiBold16.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 16),

          // Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(
                appColor(context).grey100,
              ),
              headingTextStyle: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).grey600,
              ),
              dataTextStyle: fontStyle.clashDisplayMedium12.textColor(
                appColor(context).black,
              ),
              columns: const [
                DataColumn(label: Text("TICKET ID")),
                DataColumn(label: Text("SUBJECT")),
                DataColumn(label: Text("CATEGORY")),
                DataColumn(label: Text("STATUS")),
                DataColumn(label: Text("LAST UPDATED")),
              ],
              rows: [
                DataRow(
                  onSelectChanged: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TicketDetailsScreen(),
                      ),
                    );
                  },
                  cells: [
                    const DataCell(Text("TCKT-009")),
                    const DataCell(Text("Bug")),
                    DataCell(
                      Text(
                        "Bug Report",
                        style: TextStyle(color: appColor(context).secondary),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Open",
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const DataCell(Text("5/6/2026")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).grey600,
                ),
              ),
              Icon(icon, color: appColor(context).secondary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: fontStyle.clashDisplayBold24.textColor(
              appColor(context).black,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTicketBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Create Support Ticket",
                    style: fontStyle.clashDisplaySemiBold20.textColor(
                      appColor(context).black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: appColor(context).black),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel("Subject"),
              _buildInput("What's the issue?"),
              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildDropdown("General Inquiry"),
              const SizedBox(height: 20),
              _buildLabel("Priority"),
              _buildDropdown("Medium"),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: BorderSide(color: appColor(context).grey300),
                      ),
                      child: Text(
                        "Cancel",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColor(context).secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Create Ticket",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: fontStyle.clashDisplayBold12.textColor(appColor(context).black),
      ),
    );
  }

  Widget _buildInput(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: appColor(context).grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: fontStyle.clashDisplayMedium12.textColor(
            appColor(context).grey400,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appColor(context).grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: fontStyle.clashDisplayMedium12.textColor(
              appColor(context).black,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: appColor(context).grey600),
        ],
      ),
    );
  }
}
