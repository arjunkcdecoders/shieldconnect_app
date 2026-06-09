import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/moderator_users_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ModeratorUsersController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: appColor(context).bgGrey,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _buildSearchBar(context, controller),
              Expanded(
                child: controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : controller.filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              "No users found",
                              style: fontStyle.clashDisplayMedium12
                                  .textColor(appColor(context).silver)
                                  .size(14),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => controller.fetchUsers(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = controller.filteredUsers[index];
                                return _buildUserCard(context, controller, user, index);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appColor(context).white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: appColor(context).transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Image.asset(ImageAssets.appIcon, height: 28, width: 28),
      ),
      leadingWidth: 56,
      title: Text(
        "Users",
        style: fontStyle.clashDisplayBold30
            .textColor(appColor(context).black)
            .size(20),
      ),
      centerTitle: false,
    );
  }

  Widget _buildSearchBar(BuildContext context, ModeratorUsersController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => controller.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: "Search...",
          hintStyle: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).silver)
              .size(12),
          prefixIcon: Icon(
            Icons.search,
            color: appColor(context).primary,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    ModeratorUsersController controller,
    Map<String, dynamic> user,
    int index,
  ) {
    final bool isActive = user['approval_status'] == 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: appColor(context).bgGrey,
                backgroundImage: (user['avatar'] != null && user['avatar'].toString().isNotEmpty)
                    ? NetworkImage(user['avatar'].toString())
                    : null,
                child: (user['avatar'] == null || user['avatar'].toString().isEmpty)
                    ? Icon(
                        Icons.person,
                        color: appColor(context).silver,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown',
                      style: fontStyle.clashDisplayBold30
                          .textColor(appColor(context).black)
                          .size(13),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      user['email'] ?? '',
                      style: fontStyle.clashDisplayRegular12
                          .textColor(appColor(context).silver)
                          .size(10),
                    ),
                    if (user['phone'] != null && user['phone'].toString().isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        user['phone'].toString(),
                        style: fontStyle.clashDisplayRegular12
                            .textColor(appColor(context).textMediumGrey)
                            .size(10),
                      ),
                    ],
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  activeColor: appColor(context).white,
                  activeTrackColor: appColor(context).primary,
                  inactiveThumbColor: appColor(context).white,
                  inactiveTrackColor: appColor(context).bgGrey,
                  trackOutlineColor: WidgetStateProperty.all(
                    appColor(context).transparent,
                  ),
                  onChanged: (value) => controller.toggleUserStatus(index),
                ),
              ),
            ],
          ),
          if (user['region'] != null && user['region'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  user['region'].toString(),
                  style: fontStyle.clashDisplaySemiBold18
                      .textColor(appColor(context).textGrey)
                      .size(9),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
