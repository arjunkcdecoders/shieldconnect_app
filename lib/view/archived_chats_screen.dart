import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/chat_screen.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> archivedChats = [
      {
        "name": "Maisie williams",
        "message": "Hii..Are You There?",
        "time": "Yesterday",
        "status": "read_filled",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": false,
      },
      {
        "name": "Family",
        "message": "Hello everyone!",
        "time": "May 10",
        "status": "read_empty",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": false,
        "isGroup": true,
      },
      {
        "name": "Bruce Wayne",
        "message": "Hey! 😊",
        "time": "May 8",
        "status": "none",
        "unread": 0,
        "hasRing": false,
        "hasStatusDot": false,
      },
    ];

    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: appColor(context).white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: appColor(context).black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Archived Chats",
          style: fontStyle.clashDisplaySemiBold18.textColor(appColor(context).black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: archivedChats.length,
                  itemBuilder: (context, index) {
                    return _buildChatItem(context, archivedChats[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    final bool hasRing = chat["hasRing"] ?? false;
    final bool hasStatusDot = chat["hasStatusDot"] ?? false;
    final String status = chat["status"] ?? "none";
    final int unread = chat["unread"] ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userName: chat["name"],
              isGroup: chat["isGroup"] ?? false,
              isRequest: chat["isRequest"] ?? false,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22.0),
        child: Row(
          children: [
            // Avatar
            SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: hasRing
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appColor(context).secondary,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: (chat["isGroup"] ?? false)
                              ? const NetworkImage(
                                  "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                                ) as ImageProvider
                              : const AssetImage(ImageAssets.maisieAvatar),
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: (chat["isGroup"] ?? false)
                                ? const NetworkImage(
                                    "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
                                  ) as ImageProvider
                                : const AssetImage(ImageAssets.maisieAvatar),
                          ),
                          if (hasStatusDot)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: appColor(context).secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: appColor(context).white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Mid Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chat["name"],
                    style: fontStyle.clashDisplaySemiBold16.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (status == "read_empty") ...[
                        Icon(
                          Icons.check_circle_outline,
                          color: appColor(context).green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ] else if (status == "read_filled") ...[
                        Icon(
                          Icons.check_circle,
                          color: appColor(context).green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          chat["message"],
                          style: fontStyle.clashDisplayRegular12.textColor(
                            appColor(context).grey400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right side (time)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat["time"],
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).grey300,
                  ),
                ),
                const SizedBox(height: 6),
                unread > 0
                    ? Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: appColor(context).secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread.toString(),
                            style: fontStyle.clashDisplaySemiBold12
                                .textColor(appColor(context).white)
                                .copyWith(fontSize: 10),
                          ),
                        ),
                      )
                    : const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
