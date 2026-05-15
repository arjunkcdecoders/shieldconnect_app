import 'package:flutter/material.dart';

/// Managed state controllers tracking text input parameters, focus shadows, and visibility toggles
class ChangePasswordController extends ChangeNotifier {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode oldPasswordFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  bool obscureOldPassword = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // Validation states
  bool isAtLeast6Chars = false;
  bool hasUpperAndLowerCase = false;
  bool hasNumberAndSpecialChar = false;

  ChangePasswordController() {
    // Capture state to update shadows in real time
    oldPasswordFocusNode.addListener(notifyListeners);
    passwordFocusNode.addListener(notifyListeners);
    confirmPasswordFocusNode.addListener(notifyListeners);

    // Track password changes for dynamic validation
    passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = passwordController.text;

    // 1. At least 6 characters
    isAtLeast6Chars = password.length >= 6;

    // 2. At least one upper case and one lower case
    hasUpperAndLowerCase =
        password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));

    // 3. One number and one special character
    hasNumberAndSpecialChar = password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    notifyListeners();
  }

  /// Flips status boundary logic for old password field
  void toggleObscureOldPassword() {
    obscureOldPassword = !obscureOldPassword;
    notifyListeners();
  }

  /// Flips status boundary logic for primary password field
  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /// Flips status boundary logic for secondary verification field
  void toggleObscureConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }
}
