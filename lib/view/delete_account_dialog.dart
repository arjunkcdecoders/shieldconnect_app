import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appColor(context).white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<ProfileController>(
            builder: (context, profileController, child) {
              final bool isVerifying = profileController.isPasswordVerifying;
              final bool isVerified = profileController.isPasswordVerified;
              final bool isDeleting = profileController.isAccountDeleting;
              final bool showFailedText = profileController.showDeleteFailedText;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Header Trash Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF0F2), // Pale pink/red background
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.delete_rounded,
                        color: Color(0xFFD64D65), // Destructive pink/red icon color
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    "Delete Account?",
                    style: fontStyle.clashDisplayBold18.textColor(
                      appColor(context).darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    "This action is permanent and cannot be undone. Please enter your password to confirm deletion.",
                    style: fontStyle.clashDisplayMedium12.textColor(
                      appColor(context).grey600,
                    ).copyWith(height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Password input container
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: appColor(context).white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appColor(context).grey200,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListenableBuilder(
                            listenable: profileController.deletePasswordController,
                            builder: (context, child) {
                              return TextField(
                                controller: profileController.deletePasswordController,
                                enabled: !isVerified && !isVerifying,
                                style: fontStyle.clashDisplayRegular14.textColor(
                                  appColor(context).black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter your password",
                                  hintStyle: fontStyle.clashDisplayRegular14.textColor(
                                    appColor(context).grey400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Verify / Verified Button
                        ListenableBuilder(
                          listenable: profileController.deletePasswordController,
                          builder: (context, child) {
                            final bool isEmpty = profileController.deletePasswordController.text.trim().isEmpty;
                            final bool isButtonDisabled = isVerified || isVerifying || isEmpty;

                            return GestureDetector(
                              onTap: isButtonDisabled
                                  ? null
                                  : () {
                                      profileController.verifyPassword(
                                        profileController.deletePasswordController.text.trim(),
                                      );
                                    },
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? const Color(0xFFD64D65).withValues(alpha: 0.1)
                                      : (isEmpty
                                          ? const Color(0xFFD64D65).withValues(alpha: 0.5)
                                          : const Color(0xFFD64D65)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: isVerifying
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              appColor(context).white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          isVerified ? "Verified" : "Verify",
                                          style: fontStyle.clashDisplaySemiBold12.textColor(
                                            isVerified
                                                ? const Color(0xFFD64D65)
                                                : appColor(context).white,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Failed text below the button
                  if (showFailedText) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "failed",
                          style: fontStyle.clashDisplayMedium12.textColor(
                            const Color(0xFFD64D65),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Bottom Cancel and Delete Forever Actions
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: GestureDetector(
                          onTap: isDeleting ? null : () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: appColor(context).white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: appColor(context).grey200,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Cancel",
                                style: fontStyle.clashDisplaySemiBold14.textColor(
                                  appColor(context).darkText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Delete Forever Button
                      Expanded(
                        child: GestureDetector(
                          onTap: (!isVerified || isDeleting) ? null : () => profileController.deleteAccount(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? const Color(0xFFFCD0D8) // Soft pink background as in mockup
                                  : const Color(0xFFFCD0D8).withValues(alpha: 0.5), // Semi-transparent when disabled
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isDeleting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          const Color(0xFFD64D65),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Delete Forever",
                                      style: fontStyle.clashDisplaySemiBold14.textColor(
                                        isVerified
                                            ? const Color(0xFFD64D65) // Dark pink text
                                            : const Color(0xFFD64D65).withValues(alpha: 0.5),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
