import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/create_group_screen.dart';
import 'package:shieldconnect_app/view/chat_screen.dart';

class AddNewChatScreen extends StatelessWidget {
  const AddNewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> people = [
      {
        "name": "Maisie williams",
        "subtitle": "maisiewilliams@gmail.com",
        "isRequested": false,
      },
      {"name": "Maisie williams", "subtitle": "Requested", "isRequested": true},
      {
        "name": "Maisie williams",
        "subtitle": "maisiewilliams@gmail.com",
        "isRequested": false,
      },
      {
        "name": "Maisie williams",
        "subtitle": "maisiewilliams@gmail.com",
        "isRequested": false,
      },
      {
        "name": "Maisie williams",
        "subtitle": "maisiewilliams@gmail.com",
        "isRequested": false,
      },
      {
        "name": "Maisie williams",
        "subtitle": "maisiewilliams@gmail.com",
        "isRequested": false,
      },
    ];

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
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
                      color: appColor(context).black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  cursorColor: appColor(context).primary,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: fontStyle.clashDisplayRegular12.textColor(
                      appColor(context).grey400,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 10.0),
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
              const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
              const SizedBox(height: 20),

              // "People you may know" text header
              Text(
                "People you may know",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 24),

              // Suggested contacts list
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return _buildContactItem(
                      context,
                      name: person["name"],
                      subtitle: person["subtitle"],
                      isRequested: person["isRequested"],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required String name,
    required String subtitle,
    required bool isRequested,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userName: name,
              isNewChat: true,
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
          CircleAvatar(
            radius: 24,
            backgroundImage: const AssetImage(ImageAssets.maisieAvatar),
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
                  subtitle,
                  style: fontStyle.clashDisplayRegular12
                      .textColor(
                        isRequested
                            ? appColor(context).secondary
                            : appColor(context).grey300,
                      )
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Button (Follow / Cancel)
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 30,
              width: 74,
              decoration: BoxDecoration(
                color: isRequested
                    ? appColor(context).grey200
                    : appColor(context).secondary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isRequested
                    ? [
                        // 3D Solid base for Cancel
                        const BoxShadow(
                          color: Color(0xFFCDCDCD),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                        // Ambient shadow
                        BoxShadow(
                          color: appColor(context).black.withValues(alpha: 0.05),
                          offset: const Offset(0, 6),
                          blurRadius: 8,
                        ),
                      ]
                    : [
                        // 3D Solid base for Follow (Visually matched darker pink)
                        const BoxShadow(
                          color: Color(0xFFB71C44),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                        // Ambient shadow
                        BoxShadow(
                          color: appColor(context).secondary.withValues(alpha: 0.25),
                          offset: const Offset(0, 6),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2), // Accounts visually for 3D extrusion alignment
                  child: Text(
                    isRequested ? "Cancel" : "Follow",
                    style: fontStyle.clashDisplayMedium12
                        .textColor(
                          isRequested ? appColor(context).black : appColor(context).white,
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
}
