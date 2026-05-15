import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/view/otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: appColor(context).white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: appColor(context).black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    appColor(context).primary,
                    appColor(context).secondary,
                  ],
                ).createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Text(
                  "Forgot Password",
                  style: fontStyle.clashDisplaySemiBold24.textColor(
                    appColor(context).white,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              // Subtitle
              Text(
                "Enter your email address to receive a verification code.",
                style: fontStyle.clashDisplayRegular14.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 30),

              // Email Field
              CustomTextField(
                labelText: "Email",
                hintText: "Enter your email",
                controller: emailController,
                focusNode: emailFocus,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),

              // Send OTP Button
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OtpVerificationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor(context).transparent,
                    shadowColor: appColor(context).transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Send OTP",
                    style: fontStyle.clashDisplaySemiBold18
                        .textColor(appColor(context).white)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
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
