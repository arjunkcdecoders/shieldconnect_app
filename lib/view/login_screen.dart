import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/login_controller.dart';
import 'package:shieldconnect_app/controller/signup_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/view/forgot_password_screen.dart';
import 'package:shieldconnect_app/view/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LoginController>(context);

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  "Log In",
                  style: fontStyle.clashDisplaySemiBold24.textColor(
                    appColor(context).white,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              // Subtitle
              Text(
                "Let's start again to chat with friends",
                style: fontStyle.clashDisplayRegular14.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 30),

              // Email Field
              CustomTextField(
                labelText: "Email",
                hintText: "Enter Email",
                controller: controller.emailController,
                focusNode: controller.emailFocus,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Password Field
              CustomTextField(
                labelText: "Password",
                hintText: "Enter Password",
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
              const SizedBox(height: 16),

              // Forgot Password link
              GestureDetector(
                onTap: () {
                  controller.resetFields();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  "FORGOT PASSWORD?",
                  style: fontStyle.clashDisplaySemiBold12.textColor(
                    appColor(context).cyan,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // T&C disclaimer text
              Text(
                "By continuing, I accept the T&C and Privacy Policy and child safe parent's app to access my family's personal information",
                textAlign: TextAlign.start,
                style: fontStyle.clashDisplayRegular12.textColor(
                  appColor(context).darkGrey,
                ),
              ),
              const SizedBox(height: 13),

              // Main Login Button
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
                  onPressed: controller.isLoading ? null : () => controller.login(context),
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
                          "Log In",
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

              // "Don't Have an Account Yet? Create Account"
              Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t Have an Account Yet? ",
                    style: fontStyle.clashDisplayMedium12.textColor(
                      appColor(context).black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      controller.resetFields();
                      Provider.of<SignupController>(context, listen: false)
                          .resetFields();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Create Account",
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
