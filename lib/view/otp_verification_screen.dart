import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:shieldconnect_app/view/reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _nextField(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo and App Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    ImageAssets.appIcon,
                    height: 40,
                    width: 40,
                  ),
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

              // Verify OTP Header
              Text(
                "Verify OTP",
                style: fontStyle.clashDisplaySemiBold24.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 30),

              // Enter 6-Digit OTP Label
              Text(
                "Enter 6-Digit OTP *",
                style: fontStyle.clashDisplayMedium14.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 20),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofocus: index == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _nextField(value, index),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
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
                      style: fontStyle.clashDisplayBold18.textColor(
                        appColor(context).black,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Verify OTP Button
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
                    ToastHelper.showToast(context, "OTP Verified Successfully!");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResetPasswordScreen(),
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
                    "Verify OTP",
                    style: fontStyle.clashDisplaySemiBold18
                        .textColor(appColor(context).white)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Back to Email Link
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  "Back to Email",
                  style: fontStyle.clashDisplayMedium14.textColor(
                    appColor(context).secondary,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // OTP Sent Status
              Text(
                "OTP sent to your email!",
                style: fontStyle.clashDisplayMedium14.textColor(
                  appColor(context).green,
                ),
              ),
              const SizedBox(height: 40),

              // Footer: Remember your password? Login
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
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
    );
  }
}
