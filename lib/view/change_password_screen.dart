import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/change_password_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: appColor(context).white,
        body: SafeArea(
          child: Consumer<ChangePasswordController>(
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
                      // 1. Back Button Header
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
                            "Change Password",
                            style: fontStyle.clashDisplaySemiBold20.textColor(
                              appColor(context).black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 2. Input Data Fields Group
                      CustomTextField(
                        labelText: "Old Password",
                        hintText: "Enter Old Password",
                        controller: controller.oldPasswordController,
                        focusNode: controller.oldPasswordFocusNode,
                        obscureText: controller.obscureOldPassword,
                        suffixIcon: IconButton(
                          onPressed: controller.toggleObscureOldPassword,
                          icon: Icon(
                            controller.obscureOldPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: appColor(context).grey400,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        labelText: "New Password",
                        hintText: "Enter New Password",
                        controller: controller.passwordController,
                        focusNode: controller.passwordFocusNode,
                        obscureText: controller.obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: controller.toggleObscurePassword,
                          icon: Icon(
                            controller.obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: appColor(context).grey400,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dynamic conditions
                      _buildConditionItem(
                        context: context,
                        label: 'Atleast 6 characters',
                        isMet: controller.isAtLeast6Chars,
                      ),
                      _buildConditionItem(
                        context: context,
                        label: 'Atleast one upper case and one lower case',
                        isMet: controller.hasUpperAndLowerCase,
                      ),
                      _buildConditionItem(
                        context: context,
                        label: 'One number ,one special character',
                        isMet: controller.hasNumberAndSpecialChar,
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        labelText: "Confirm Password",
                        hintText: "Re-enter New Password",
                        controller: controller.confirmPasswordController,
                        focusNode: controller.confirmPasswordFocusNode,
                        obscureText: controller.obscureConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: controller.toggleObscureConfirmPassword,
                          icon: Icon(
                            controller.obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: appColor(context).grey400,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),

                      // 3. Bottom Update action button
                      GestureDetector(
                        onTap: controller.isLoading
                            ? null
                            : () => controller.changePassword(context),
                        child: Container(
                          height: 46,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: controller.isLoading
                                ? appColor(
                                    context,
                                  ).secondary.withValues(alpha: 0.6)
                                : appColor(context).secondary,
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
                                    "Update Password",
                                    style: fontStyle.clashDisplaySemiBold14
                                        .textColor(appColor(context).white),
                                  ),
                          ),
                        ),
                      ),
                      if (controller.feedbackMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            controller.feedbackMessage,
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
      ),
    );
  }

  Widget _buildConditionItem({
    required BuildContext context,
    required String label,
    required bool isMet,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? Colors.green : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: clashDisplay(
                fontsize: 12,
                fontWeight: regular,
              ).textColor(isMet ? Colors.green : Colors.grey[600]!),
            ),
          ),
        ],
      ),
    );
  }
}

/// Local re-usable high-performance Stateless Input Field configuration
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

    // Resolved dynamics for label formatting
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
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: fontStyle.clashDisplayRegular12.textColor(
                appColor(context).grey500,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
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
              appColor(context).black,
            ),
          ),
        ),
      ],
    );
  }
}
