import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:shieldconnect_app/view/reset_password_screen.dart';

import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/forgot_password_controller.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ForgotPasswordController>(context);

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
                      controller: controller.otpControllers[index],
                      focusNode: controller.otpFocusNodes[index],
                      autofocus: index == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => controller.nextField(value, index),
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
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.verifyOtp(context),
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
                          "Verify OTP",
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
              const SizedBox(height: 25),

              // Back to Email Link
              GestureDetector(
                onTap: () {
                  controller.clearMessage();
                  Navigator.pop(context);
                },
                child: Text(
                  "Back to Email",
                  style: fontStyle.clashDisplayMedium14.textColor(
                    appColor(context).secondary,
                  ),
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
