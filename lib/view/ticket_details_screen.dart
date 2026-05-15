import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      "text": "Hi, I'm having trouble with my recent message sync.",
      "isMe": true,
      "time": "09:04 PM",
    },
    {
      "text":
          "Hello! I'm sorry to hear that. Could you please provide more details?",
      "isMe": false,
      "time": "09:05 PM",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
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
                      color: appColor(context).black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TCKT-009",
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
                        Text(
                          "Bug",
                          style: fontStyle.clashDisplaySemiBold12.textColor(
                            appColor(context).black,
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
                        _buildInfoItem("Status", "OPEN"),
                        _buildInfoItem("Category", "Bug Report"),
                        _buildInfoItem("Priority", "MEDIUM"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem("Created Date", "May 6, 2026"),
                        _buildInfoItem("Raised By", "Swiss"),
                        _buildInfoItem("Assigned Agent", "Unassigned"),
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
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appColor(context).grey100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildChatMessage(
                            msg['text'],
                            msg['isMe'],
                            msg['time'],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMessageInput(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
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

  Widget _buildChatMessage(String text, bool isMe, String time) {
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
              "${isMe ? 'YOU' : 'SUPPORT'} $time",
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
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            child: Text(
              text,
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

  Widget _buildMessageInput() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appColor(context).white,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add, color: appColor(context).grey400, size: 20),
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
              decoration: InputDecoration(
                hintText: "Type your message...",
                hintStyle: fontStyle.clashDisplayMedium12.textColor(
                  appColor(context).grey400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appColor(context).secondary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.send, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}
