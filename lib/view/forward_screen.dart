import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/forward_screen_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class ForwardScreen extends StatelessWidget {
  final String messageId;

  const ForwardScreen({
    super.key,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ForwardScreenController>(
      create: (context) => ForwardScreenController()..fetchRecentChats(),
      child: Consumer<ForwardScreenController>(
        builder: (context, controller, child) {
          final isLoading = controller.isLoading;
          final allChats = controller.allChats;
          final filteredChats = controller.filteredChats;
          final selectedUserIds = controller.selectedUserIds;
          final selectedGroupIds = controller.selectedGroupIds;
          final int totalSelected = selectedUserIds.length + selectedGroupIds.length;

          return Scaffold(
            backgroundColor: appColor(context).white,
            appBar: AppBar(
              backgroundColor: appColor(context).white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: appColor(context).black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Forward Message",
                style: fontStyle.clashDisplayBold18.textColor(appColor(context).black),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: appColor(context).grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.filterChats,
                      style: fontStyle.clashDisplayRegular14.textColor(appColor(context).black),
                      decoration: InputDecoration(
                        hintText: "Search chats...",
                        hintStyle: fontStyle.clashDisplayRegular14.textColor(appColor(context).grey400),
                        prefixIcon: Icon(Icons.search, color: appColor(context).grey400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: isLoading && allChats.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(appColor(context).secondary),
                    ),
                  )
                : filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 64, color: appColor(context).grey300),
                            const SizedBox(height: 16),
                            Text(
                              allChats.isEmpty
                                  ? "No active chats found."
                                  : "No chats match your search.",
                              style: fontStyle.clashDisplaySemiBold16.textColor(appColor(context).grey500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: filteredChats.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: appColor(context).grey100),
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          final String id = chat['id'];
                          final bool isGroup = chat['isGroup'] == true;
                          final bool isSelected = isGroup
                              ? selectedGroupIds.contains(id)
                              : selectedUserIds.contains(id);
                          final String avatarUrl = ApiService.getImageUrl(chat['avatar']);
                          final bool hasAvatar = avatarUrl.isNotEmpty;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? appColor(context).secondary.withValues(alpha: 0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? appColor(context).secondary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              onTap: () => controller.toggleSelection(id, isGroup),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: appColor(context).grey100,
                                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                child: hasAvatar
                                    ? null
                                    : Icon(
                                        isGroup ? Icons.group : Icons.person,
                                        color: appColor(context).secondary,
                                        size: 20,
                                      ),
                              ),
                              title: Text(
                                chat['name'],
                                style: fontStyle.clashDisplayBold14.textColor(appColor(context).black),
                              ),
                              subtitle: Text(
                                chat['subtitle'],
                                style: fontStyle.clashDisplayRegular12.textColor(appColor(context).grey500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? appColor(context).secondary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? appColor(context).secondary
                                        : appColor(context).grey400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: appColor(context).white,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
            bottomSheet: totalSelected == 0
                ? null
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appColor(context).white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => controller.forwardMessage(context, messageId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColor(context).secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(appColor(context).white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.scale(
                                    scaleX: -1,
                                    child: Icon(Icons.reply_rounded, color: appColor(context).white, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Forward to $totalSelected chat${totalSelected > 1 ? 's' : ''}",
                                    style: fontStyle.clashDisplayBold14.textColor(appColor(context).white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
