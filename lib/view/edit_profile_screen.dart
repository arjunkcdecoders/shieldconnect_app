import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/edit_profile_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Consumer<EditProfileController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Section: Dismiss trigger and title
                    Row(
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
                          "Edit Profile",
                          style: fontStyle.clashDisplaySemiBold20.textColor(
                            appColor(context).black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 2. Compact Profile Image Uploader Block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                image: const DecorationImage(
                                  image: AssetImage(ImageAssets.userAvatar),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Upload Plus Badge overlay
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: appColor(context).secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: appColor(context).white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: appColor(context).white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Replace your photo",
                          style: fontStyle.clashDisplayMedium10.textColor(
                            appColor(context).black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 3. Local Editable Form Fields Group
                    CustomTextField(
                      labelText: "Name",
                      hintText: "Enter",
                      controller: controller.nameController,
                      focusNode: controller.nameFocusNode,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      labelText: "About",
                      hintText: "Enter",
                      controller: controller.aboutController,
                      focusNode: controller.aboutFocusNode,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      labelText: "Email",
                      hintText: "Enter",
                      controller: controller.emailController,
                      focusNode: controller.emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 40),

                    // 4. Destructive Save action stadium button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: appColor(context).secondary,
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Center(
                          child: Text(
                            "Save",
                            style: fontStyle.clashDisplaySemiBold14.textColor(
                              appColor(context).white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// High-performance Stateless Form input aligned locally to satisfy self-containment constraints
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
    final bool hasFocus = focusNode?.hasFocus ?? false;

    // Dynamic color resolving for top labels
    final Color labelColor =
        hasFocus ? appColor(context).secondary : appColor(context).black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: fontStyle.clashDisplayBold12.textColor(labelColor),
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
                      color: appColor(context).secondary.withValues(alpha: 0.1),
                      offset: const Offset(0, 6),
                      blurRadius: 12,
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
              hintStyle: fontStyle.clashDisplayRegular12.textColor(
                appColor(context).grey300,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical:
                    12, // Slightly reduced vertical padding for compact design
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: appColor(context).grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: appColor(context).secondary,
                  width: 1.2,
                ),
              ),
            ),
            style: fontStyle.clashDisplaySemiBold14.textColor(
              appColor(context).black,
            ),
          ),
        ),
      ],
    );
  }
}
