import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/help_support_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/view/ticket_details_screen.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Today";
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        return "${parsed.day}/${parsed.month}/${parsed.year}";
      }
    } catch (_) {}
    return "Today";
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HelpSupportController>(context, listen: false)
          .fetchUserTickets();
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Consumer<HelpSupportController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
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
                            "Support Tickets",
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Ticket Overview",
                              style: fontStyle.clashDisplaySemiBold18.textColor(
                                appColor(context).black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showCreateTicketBottomSheet(context),
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
                                    const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Create Ticket",
                                      style: fontStyle.clashDisplaySemiBold12
                                          .textColor(Colors.white),
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
                              child: _buildSummaryCard(
                                context,
                                "All",
                                controller.tickets.length.toString(),
                                Icons.forum_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                "Pending",
                                controller.tickets
                                    .where((t) =>
                                        t.status?.toLowerCase() == 'open' ||
                                        t.status?.toLowerCase() == 'pending')
                                    .length
                                    .toString(),
                                Icons.timer_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                "Closed",
                                controller.tickets
                                    .where((t) =>
                                        t.status?.toLowerCase() == 'closed' ||
                                        t.status?.toLowerCase() == 'resolved')
                                    .length
                                    .toString(),
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
                                  onChanged: (val) {
                                    controller.searchTickets(val);
                                  },
                                  style: fontStyle.clashDisplayMedium12.textColor(
                                    appColor(context).black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Search Subject or ID",
                                    hintStyle: fontStyle.clashDisplayMedium12
                                        .textColor(appColor(context).grey400),
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
                        if (controller.isLoading && controller.tickets.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: appColor(context).secondary,
                              ),
                            ),
                          )
                        else if (controller.tickets.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 48,
                                    color: appColor(context).grey400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No support tickets found",
                                    style: fontStyle.clashDisplayMedium12
                                        .textColor(appColor(context).grey600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 24,
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(
                                appColor(context).grey100,
                              ),
                              headingTextStyle: fontStyle.clashDisplayMedium12
                                  .textColor(appColor(context).grey600),
                              dataTextStyle: fontStyle.clashDisplayMedium12
                                  .textColor(appColor(context).black),
                              columns: const [
                                DataColumn(label: Text("TICKET ID")),
                                DataColumn(label: Text("SUBJECT")),
                                DataColumn(label: Text("CATEGORY")),
                                DataColumn(label: Text("STATUS")),
                                DataColumn(label: Text("LAST UPDATED")),
                              ],
                               rows: controller.tickets.map((ticket) {
                                final String displayId = ticket.ticketId ??
                                    (ticket.id ?? "TCKT-000");
                                final String displaySubject =
                                    ticket.subject ?? "No Subject";
                                final String displayCategory =
                                    ticket.category ?? "General Inquiry";
                                final String displayStatus =
                                    ticket.status ?? "Open";
                                final String displayDate = _formatDate(
                                    ticket.createdAt?.toIso8601String());

                                final bool isOpen =
                                    displayStatus.toLowerCase() == "open" ||
                                        displayStatus.toLowerCase() == "pending";
                                final Color statusBgColor = isOpen
                                    ? const Color(0xFFE3F2FD)
                                    : const Color(0xFFE8F5E9);
                                final Color statusTextColor = isOpen
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFF2E7D32);

                                return DataRow(
                                onSelectChanged: (_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TicketDetailsScreen(ticketId: ticket.id ?? ""),
                                      ),
                                    );
                                  },
                                  cells: [
                                    DataCell(Text(displayId)),
                                    DataCell(Text(displaySubject)),
                                    DataCell(
                                      Text(
                                        displayCategory,
                                        style: TextStyle(
                                          color: appColor(context).secondary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBgColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          displayStatus,
                                          style: TextStyle(
                                            color: statusTextColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(displayDate)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
  ) {
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
              Expanded(
                child: Text(
                  title,
                  style: fontStyle.clashDisplayMedium12.textColor(
                    appColor(context).grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
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

  void _showCreateTicketBottomSheet(BuildContext context) {
    String selectedCategory = "Technical Issue";
    final TextEditingController subjectController = TextEditingController();
    bool isSubmitting = false;
    bool showErrorText = false;
    Timer? errorTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 24,
                  left: 24,
                  right: 24,
                ),
                child: SingleChildScrollView(
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
                            onPressed: () {
                              errorTimer?.cancel();
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.close, color: appColor(context).black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildLabel(context, "Subject"),
                      _buildInput(
                        context,
                        "What's the issue?",
                        controller: subjectController,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(context, "Category"),
                      _buildDropdownPicker(
                        context: context,
                        value: selectedCategory,
                        items: const [
                          "Billing",
                          "Technical Issue",
                          "General Inquiry",
                          "Bug Report",
                        ],
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      errorTimer?.cancel();
                                      Navigator.pop(context);
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                side: BorderSide(
                                    color: appColor(context).grey300),
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
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (subjectController.text.trim().isEmpty) {
                                        setState(() {
                                          showErrorText = true;
                                        });
                                        errorTimer?.cancel();
                                        errorTimer = Timer(
                                            const Duration(seconds: 2), () {
                                          if (context.mounted) {
                                            setState(() {
                                              showErrorText = false;
                                            });
                                          }
                                        });
                                        return;
                                      }

                                      setState(() {
                                        isSubmitting = true;
                                        showErrorText = false;
                                      });

                                      final success =
                                          await Provider.of<HelpSupportController>(
                                                  context,
                                                  listen: false)
                                              .createTicket(
                                        subject: subjectController.text.trim(),
                                        category: selectedCategory,
                                      );

                                      if (success) {
                                        errorTimer?.cancel();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } else {
                                        if (context.mounted) {
                                          setState(() {
                                            isSubmitting = false;
                                            showErrorText = true;
                                          });
                                          errorTimer?.cancel();
                                          errorTimer = Timer(
                                              const Duration(seconds: 2), () {
                                            if (context.mounted) {
                                              setState(() {
                                                showErrorText = false;
                                              });
                                            }
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColor(context).secondary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Create Ticket",
                                      style: fontStyle.clashDisplaySemiBold14
                                          .textColor(Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (showErrorText) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "failed",
                            style: fontStyle.clashDisplaySemiBold12.textColor(
                              const Color(0xFFEF5350), // Premium red accent
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: fontStyle.clashDisplayBold12.textColor(appColor(context).black),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    String hint, {
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appColor(context).grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: fontStyle.clashDisplayMedium12.textColor(
          appColor(context).black,
        ),
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

  Widget _buildDropdownPicker({
    required BuildContext context,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: appColor(context).grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          icon: Icon(Icons.keyboard_arrow_down, color: appColor(context).grey600),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: fontStyle.clashDisplayMedium12.textColor(
            appColor(context).black,
          ),
          dropdownColor: appColor(context).white,
          borderRadius: BorderRadius.circular(12),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).black,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
