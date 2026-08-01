import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';

import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/forgot_password_controller.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ForgotPasswordController>(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: appColor(context).white,
        appBar: AppBar(
          backgroundColor: appColor(context).white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: appColor(context).black),
            onPressed: () {
              controller.clearMessage();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo and App Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(ImageAssets.appIcon, height: 40, width: 40),
                    const SizedBox(width: 10),
                    Text(
                      "ShieldConnect",
                      style: fontStyle.clashDisplayBold24.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Header
                Text(
                  "Set new password",
                  style: fontStyle.clashDisplaySemiBold24.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 40),

                // New Password Field
                CustomTextField(
                  labelText: "New Password *",
                  hintText: "Enter new password",
                  controller: controller.passwordController,
                  focusNode: controller.passwordFocus,
                  obscureText: !controller.isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off_outlined,
                      color: controller.passwordFocus.hasFocus
                          ? appColor(context).primary
                          : appColor(context).grey,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
                const SizedBox(height: 25),

                // Confirm Password Field
                CustomTextField(
                  labelText: "Confirm New Password *",
                  hintText: "Confirm new password",
                  controller: controller.confirmPasswordController,
                  focusNode: controller.confirmPasswordFocus,
                  obscureText: !controller.isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off_outlined,
                      color: controller.confirmPasswordFocus.hasFocus
                          ? appColor(context).primary
                          : appColor(context).grey,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                ),
                const SizedBox(height: 40),

                // Reset Password Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appColor(context).primary,
                        appColor(context).secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.resetPassword(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColor(context).transparent,
                      shadowColor: appColor(context).transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Reset Password",
                            style: fontStyle.clashDisplaySemiBold18
                                .textColor(appColor(context).white)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                if (controller.message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      controller.message,
                      textAlign: TextAlign.center,
                      style: fontStyle.clashDisplayMedium14.textColor(
                        controller.isError
                            ? appColor(context).red
                            : appColor(context).green,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Remember your password? ",
                      style: fontStyle.clashDisplayMedium14.textColor(
                        appColor(context).textMediumGrey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        "Login",
                        style: fontStyle.clashDisplayBold14.textColor(
                          appColor(context).secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
