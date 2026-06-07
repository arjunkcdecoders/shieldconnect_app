import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: Consumer<ProfileController>(
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => controller.toggleImageOptions(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: appColor(context).grey100,
                                          borderRadius: BorderRadius.circular(24),
                                          image: controller.pickedImage != null
                                              ? DecorationImage(
                                                  image: FileImage(
                                                    controller.pickedImage!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : ApiService.getImageUrl(
                                                        controller.imageUrl,
                                                      ).isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        ApiService.getImageUrl(
                                                          controller.imageUrl,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                        ),
                                        child: controller.pickedImage == null &&
                                                ApiService.getImageUrl(
                                                  controller.imageUrl,
                                                ).isEmpty
                                            ? Icon(
                                                Icons.person,
                                                color: appColor(context).grey400,
                                                size: 40,
                                              )
                                            : null,
                                      ),
                                      // Upload Edit Badge overlay
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: appColor(context).secondary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: appColor(context).white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            color: appColor(context).white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    (controller.pickedImage != null ||
                                            ApiService.getImageUrl(controller.imageUrl).isNotEmpty)
                                        ? "Edit photo"
                                        : "Upload photo",
                                    style: fontStyle.clashDisplayMedium10.textColor(
                                      appColor(context).black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (controller.showImageOptions) ...[
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildOptionButton(
                                      context,
                                      icon: Icons.photo_library_outlined,
                                      label: "Upload photo",
                                      onTap: () {
                                        controller.pickImage(source: ImageSource.gallery);
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _buildOptionButton(
                                      context,
                                      icon: Icons.camera_alt_outlined,
                                      label: "Take photo",
                                      onTap: () {
                                        controller.pickImage(source: ImageSource.camera);
                                      },
                                    ),
                                    if (controller.pickedImage != null ||
                                        ApiService.getImageUrl(controller.imageUrl).isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildOptionButton(
                                        context,
                                        icon: Icons.delete_outline,
                                        label: "Remove photo",
                                        isDestructive: true,
                                        onTap: () {
                                          controller.removeImage();
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                      controller: controller.bioController,
                      focusNode: controller.bioFocusNode,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      labelText: "Email",
                      hintText: "Enter",
                      controller: controller.emailController,
                      focusNode: controller.emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true, // Fixed email
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      labelText: "Region",
                      hintText: "Enter",
                      controller: controller.regionController,
                      focusNode: controller.regionFocusNode,
                      readOnly: true, // Fixed region
                    ),
                    const SizedBox(height: 40),

                    // 4. Destructive Save action stadium button
                    GestureDetector(
                      onTap: controller.isLoading
                          ? null
                          : () => controller.updateProfile(context),
                      child: Container(
                        height: 46,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: appColor(context).secondary,
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Center(
                          child: controller.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Save",
                                  style: fontStyle.clashDisplaySemiBold14
                                      .textColor(appColor(context).white),
                                ),
                        ),
                      ),
                    ),
                    if (controller.message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          controller.message,
                          style: fontStyle.clashDisplayMedium12.textColor(
                            controller.isError ? Colors.red : Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color textColor = isDestructive ? Colors.red.shade600 : appColor(context).black;
    final Color iconColor = isDestructive ? Colors.red.shade600 : appColor(context).secondary;
    final Color bgColor = isDestructive 
        ? Colors.red.shade50.withValues(alpha: 0.5) 
        : appColor(context).grey100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive ? Colors.red.shade100 : appColor(context).grey200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: fontStyle.clashDisplayMedium12.textColor(textColor),
            ),
          ],
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
  final bool readOnly;

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
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFocus = focusNode?.hasFocus ?? false;

    // Dynamic color resolving for top labels
    final Color labelColor = hasFocus
        ? appColor(context).secondary
        : appColor(context).black;

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
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: fontStyle.clashDisplayRegular12.textColor(
                appColor(context).grey300,
              ),
              filled: true,
              fillColor: readOnly
                  ? appColor(context).grey100
                  : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
              readOnly ? appColor(context).grey400 : appColor(context).black,
            ),
          ),
        ),
      ],
    );
  }
}
