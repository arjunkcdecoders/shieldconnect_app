import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/help_support_controller.dart';
import 'package:shieldconnect_app/model/ticket_chat_model.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/linkified_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class TicketDetailsScreen extends StatelessWidget {
  final String ticketId;
  const TicketDetailsScreen({super.key, required this.ticketId});

  String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    try {
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (_) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<HelpSupportController>(
        context,
        listen: false,
      );
      final ticket = controller.selectedTicket;
      final isDifferentTicket =
          ticket == null ||
          (ticket.id != ticketId && ticket.ticketId != ticketId);

      if (isDifferentTicket && !controller.isLoading) {
        controller.fetchTicketDetails(ticketId);
        controller.fetchTicketChats(ticketId);
      }
    });

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Consumer<HelpSupportController>(
          builder: (context, controller, child) {
            final ticket = controller.selectedTicket;

            if (controller.isLoading && ticket == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: appColor(context).secondary,
                ),
              );
            } else if (ticket == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: appColor(context).grey400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Failed to load ticket details",
                      style: fontStyle.clashDisplayMedium14.textColor(
                        appColor(context).grey600,
                      ),
                    ),
                  ],
                ),
              );
            }

            double chatHeight = MediaQuery.of(context).size.height * 0.45;
            if (chatHeight < 320) chatHeight = 320;

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
                        Text(
                          "Ticket Details",
                          style: fontStyle.clashDisplaySemiBold20.textColor(
                            appColor(context).black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Ticket Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: appColor(context).white,
                        borderRadius: BorderRadius.circular(24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.ticketId ?? (ticket.id ?? "TCKT-000"),
                            style: fontStyle.clashDisplayBold24.textColor(
                              appColor(context).black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Subject: ",
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  appColor(context).grey400,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  ticket.subject ?? "No Subject",
                                  style: fontStyle.clashDisplaySemiBold12
                                      .textColor(appColor(context).black),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(
                                context,
                                "Status",
                                (ticket.status ?? "Open").toUpperCase(),
                              ),
                              _buildInfoItem(
                                context,
                                "Category",
                                ticket.category ?? "General Inquiry",
                              ),
                              _buildInfoItem(
                                context,
                                "Priority",
                                (ticket.priority ?? "").toUpperCase(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(
                                context,
                                "Created Date",
                                _formatDate(ticket.createdAt),
                              ),
                              _buildInfoItem(
                                context,
                                "Raised By",
                                ticket.user?.name ?? "User",
                              ),
                              _buildInfoItem(
                                context,
                                "Assigned Agent",
                                ticket.assignedAdmin is Map
                                    ? (ticket.assignedAdmin['name']
                                              ?.toString() ??
                                          "Unassigned")
                                    : (ticket.assignedTo ?? "Unassigned"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. Conversation Thread
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Conversation Thread",
                      style: fontStyle.clashDisplaySemiBold16.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: chatHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appColor(context).grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: GestureDetector(
                      onTap: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        children: [
                          Expanded(
                            child: controller.ticketChats.isEmpty
                                ? Center(
                                    child: Text(
                                      "No messages yet. Send a message to start.",
                                      style: fontStyle.clashDisplayMedium12
                                          .textColor(appColor(context).grey600),
                                    ),
                                  )
                                : ListView.builder(
                                    reverse: true,
                                    itemCount: controller.ticketChats.length,
                                    itemBuilder: (context, index) {
                                      // Since list is reversed, index 0 is the newest message
                                      final chat =
                                          controller.ticketChats[controller
                                                  .ticketChats
                                                  .length -
                                              1 -
                                              index];
                                      final isMe = chat.adminUserId == null;
                                      return _buildChatMessage(
                                        context,
                                        chat,
                                        isMe,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _ChatInputWidget(
                            ticketId: ticketId,
                            controller: controller,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: fontStyle.clashDisplayMedium10.textColor(
            appColor(context).grey400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: fontStyle.clashDisplaySemiBold12.textColor(
            appColor(context).black,
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(
    BuildContext context,
    TicketChatModel chat,
    bool isMe,
  ) {
    final timeStr = chat.createdAt != null
        ? DateFormat('hh:mm a').format(chat.createdAt!.toLocal())
        : '';
    final hasAttachment = chat.fileUrl != null && chat.fileUrl!.isNotEmpty;
    final isImg = hasAttachment && _isImage(chat.fileUrl, chat.fileName);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
            child: Text(
              "${isMe ? 'YOU' : 'SUPPORT'} $timeStr",
              style: fontStyle.clashDisplayMedium10.textColor(
                appColor(context).grey600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? appColor(context).secondary
                  : appColor(context).white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: hasAttachment
                  ? 180.0 // Smaller media bubbles constraints
                  : MediaQuery.of(context).size.width * 0.6,
            ),
            child: hasAttachment
                ? (isImg
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: chat.fileUrl!,
                                width: 150,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 150,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 150,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            if (chat.message != null &&
                                chat.message!.isNotEmpty &&
                                !chat.message!.startsWith('Attachment:')) ...[
                              const SizedBox(height: 6),
                              LinkifiedText(
                                text: chat.message!,
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  isMe ? Colors.white : appColor(context).black,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              color: isMe
                                  ? Colors.white
                                  : appColor(context).secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.fileName ?? "File Attachment",
                                    style: fontStyle.clashDisplaySemiBold12
                                        .textColor(
                                          isMe
                                              ? Colors.white
                                              : appColor(context).black,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (chat.fileSize != null)
                                    Text(
                                      "${(chat.fileSize! / 1024).toStringAsFixed(1)} KB",
                                      style: fontStyle.clashDisplayMedium10
                                          .textColor(
                                            isMe
                                                ? Colors.white70
                                                : appColor(context).grey400,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ))
                : LinkifiedText(
                    text: chat.message ?? "",
                    style: fontStyle.clashDisplayMedium12.textColor(
                      isMe ? Colors.white : appColor(context).black,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  bool _isImage(String? url, String? name) {
    final path = (url ?? name ?? '').toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.contains('attachment-');
  }
}

class _ChatInputWidget extends StatefulWidget {
  final String ticketId;
  final HelpSupportController controller;

  const _ChatInputWidget({required this.ticketId, required this.controller});

  @override
  State<_ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<_ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    await widget.controller.sendTicketMessage(
      ticketId: widget.ticketId,
      message: text,
    );
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        final text = _textController.text.trim();
        final messageText = text.isNotEmpty ? text : "Attachment: $fileName";

        _textController.clear();
        FocusScope.of(context).unfocus();

        await widget.controller.sendTicketMessage(
          ticketId: widget.ticketId,
          message: messageText,
          filePath: filePath,
        );
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSending = widget.controller.isSendingMessage;

    return Row(
      children: [
        GestureDetector(
          onTap: isSending ? null : _pickAndSendFile,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appColor(context).white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: appColor(context).grey400, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: appColor(context).white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _textController,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: isSending ? "Sending..." : "Type your message...",
                hintStyle: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).grey400,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: isSending ? null : _sendMessage,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appColor(context).secondary,
              shape: BoxShape.circle,
            ),
            child: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
