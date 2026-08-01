import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/login_controller.dart';
import 'package:shieldconnect_app/controller/signup_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SignupController>(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: appColor(context).white,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: controller.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      LinearGradient(
                        colors: [
                          appColor(context).primary,
                          appColor(context).secondary,
                        ],
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                  child: Text(
                    "Create Account",
                    style: fontStyle.clashDisplaySemiBold24.textColor(
                      appColor(context).white,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
  
                // Subtitle 1
                Text.rich(
                  TextSpan(
                    text: "Hello Everyone, We are ",
                    style: fontStyle.clashDisplayRegular14.textColor(
                      appColor(context).black,
                    ),
                    children: [
                      TextSpan(
                        text: "ShieldConnect",
                        style: fontStyle.clashDisplayRegular14
                            .textColor(appColor(context).secondary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
  
                // Subtitle 2
                Text(
                  "Welcome to ShieldConnect, please sign up for your account.",
                  style: fontStyle.clashDisplayRegular14.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 30),
  
                // User Name Field
                CustomTextField(
                  labelText: "User Name",
                  hintText: "Enter",
                  controller: controller.userNameController,
                  focusNode: controller.userNameFocus,
                ),
                const SizedBox(height: 20),
  
                // Email Field
                CustomTextField(
                  labelText: "Email",
                  hintText: "Enter",
                  controller: controller.emailController,
                  focusNode: controller.emailFocus,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
  
                // Password Field
                CustomTextField(
                  labelText: "Password",
                  hintText: "Enter",
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
                const SizedBox(height: 20),
  
                // Region Dropdown
                CustomDropdownField(
                  labelText: "Region",
                  hintText: "Select Region",
                  value:
                      (controller.selectedRegionId != null &&
                          controller.regions.any(
                            (e) => e['_id'] == controller.selectedRegionId,
                          ))
                      ? controller.selectedRegionId
                      : null,
                  items: controller.regions.map((e) {
                    return DropdownMenuItem<String>(
                      value: e['_id'] as String?,
                      child: Text(
                        e['name'] as String? ?? '',
                        style: fontStyle.clashDisplayRegular14
                            .textColor(appColor(context).black)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    controller.setSelectedRegionId(val);
                  },
                ),
                const SizedBox(height: 16),
  
                // Dynamic validation conditions
                if (controller.passwordFocus.hasFocus &&
                    controller.passwordController.text.isNotEmpty) ...[
                  _buildConditionItem(
                    context: context,
                    label: 'Between 6 and 8 characters',
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
                ] else ...[
                  const SizedBox(height: 4),
                ],
  
                // T&C disclaimer text
                Text(
                  "By continuing, I accept the T&C and Privacy Policy and child safe parent's app to access my family's personal information",
                  textAlign: TextAlign.start,
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).darkGrey,
                  ),
                ),
                const SizedBox(height: 20),
  
                // Main Continue Button
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
                        : () => controller.signup(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColor(context).transparent,
                      disabledBackgroundColor: appColor(context).transparent,
                      shadowColor: appColor(context).transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: appColor(context).white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Continue",
                            style: fontStyle.clashDisplaySemiBold18
                                .textColor(appColor(context).white)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                if (controller.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      controller.message,
                      style: fontStyle.clashDisplayMedium12.textColor(
                        controller.isSuccess
                            ? Colors.green
                            : appColor(context).red,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
  
                // Bottom footer section links
  
                // "Already have an Account? Sign In"
                Row(
                  children: [
                    Text(
                      "Already have an Account? ",
                      style: fontStyle.clashDisplayMedium12.textColor(
                        appColor(context).black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        controller.clearError();
                        Provider.of<LoginController>(
                          context,
                          listen: false,
                        ).clearError();
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Sign In",
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

class CustomDropdownField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdownField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelText,
          style: fontStyle.clashDisplayRegular12
              .textColor(appColor(context).darkGrey)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          dropdownColor: appColor(context).white,
          initialValue: value,
          items: items,
          onChanged: onChanged,
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
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: appColor(context).primary,
          ),
        ),
      ],
    );
  }
}
