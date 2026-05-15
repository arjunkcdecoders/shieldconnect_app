import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/create_group_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CreateGroupController>(context);

    // Call init if not already loading and data is empty
    if (!controller.isLoading && controller.connectedUsers.isEmpty) {
      Future.microtask(() => controller.init());
    }

    return Scaffold(
      backgroundColor: appColor(context).white,
      // Pink FAB in the bottom-right
      floatingActionButton: GestureDetector(
        onTap: () => controller.createGroup(context),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: appColor(context).secondary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: appColor(context).secondary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: controller.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: appColor(context).white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.arrow_forward, color: appColor(context).white, size: 24),
          ),
        ),
      ),
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
                // Top App Bar Header
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
                      "Create New group",
                      style: fontStyle.clashDisplaySemiBold18.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Group Name Section
                CustomTextField(
                  labelText: "Group Name",
                  hintText: "Family👨‍👩‍👧‍👦",
                  controller: controller.groupNameController,
                  focusNode: controller.groupNameFocus,
                ),
                const SizedBox(height: 24),

                // Choose Group Icon Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: controller.pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          const CircleAvatar(
                            radius: 42,
                            backgroundImage: AssetImage(ImageAssets.maisieAvatar),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: appColor(context).secondary,
                                // shape: BoxShape.circle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: appColor(context).white, width: 1),
                              ),
                              child: Icon(
                                Icons.add,
                                color: appColor(context).white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose Group Icon",
                      style: fontStyle.clashDisplayMedium10.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description Section
                CustomTextField(
                  labelText: "Description",
                  hintText: "Enter Group Description...",
                  maxLines: 3,
                  controller: controller.groupDescController,
                  focusNode: controller.groupDescFocus,
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
                    controller: controller.searchController,
                    onChanged: controller.searchUsers,
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

                // "Select People" Subtitle
                Text(
                  "Select People",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 20),

                // Contact list (Integrated smoothly into SingleChildScrollView)
                controller.isLoading && controller.searchResults.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.searchResults.length,
                        itemBuilder: (context, index) {
                          final person = controller.searchResults[index];
                          return GestureDetector(
                            onTap: () => controller.toggleUserSelection(index),
                            behavior: HitTestBehavior.opaque,
                            child: _buildSelectablePersonItem(
                              context,
                              name: person["name"],
                              subtitle: person["subtitle"],
                              isSelected: person["isSelected"],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectablePersonItem(
    BuildContext context, {
    required String name,
    required String subtitle,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: const AssetImage(ImageAssets.maisieAvatar),
          ),
          const SizedBox(width: 12),

          // Identity Details
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
                      .textColor(appColor(context).grey300)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Selection Indicator Badge
          isSelected
              ? Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: appColor(context).secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.check, color: appColor(context).white, size: 12),
                  ),
                )
              : Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: appColor(context).grey300, width: 1.2),
                  ),
                ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode?.hasFocus ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: fontStyle.clashDisplayRegular12
                .textColor(
                  hasFocus
                      ? appColor(context).primary
                      : appColor(context).darkGrey,
                )
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: appColor(context).primary.withValues(alpha: 0.12),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                    BoxShadow(
                      color: appColor(context).primary.withValues(alpha: 0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            cursorColor: appColor(context).primary,
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: fontStyle.clashDisplayRegular14.textColor(
                appColor(context).textGrey,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: appColor(context).grey.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: appColor(context).primary,
                  width: 1.5,
                ),
              ),
            ),
            style: fontStyle.clashDisplayRegular14
                .textColor(appColor(context).black)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
