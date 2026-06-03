import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';

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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _feedbackMessage = '';
  String get feedbackMessage => _feedbackMessage;

  bool _isError = false;
  bool get isError => _isError;

  bool _ignoreTextChanges = false;

  ChangePasswordController() {
    // Capture state to update shadows in real time
    oldPasswordFocusNode.addListener(notifyListeners);
    passwordFocusNode.addListener(notifyListeners);
    confirmPasswordFocusNode.addListener(notifyListeners);

    // Track password changes for dynamic validation
    passwordController.addListener(_validatePassword);

    // Clear feedback messages when fields change
    oldPasswordController.addListener(_onTextChanged);
    passwordController.addListener(_onTextChanged);
    confirmPasswordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_ignoreTextChanges) return;
    if (_feedbackMessage.isNotEmpty) {
      _feedbackMessage = '';
      notifyListeners();
    }
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

  void clearAll() {
    _ignoreTextChanges = true;
    oldPasswordController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _feedbackMessage = '';
    _isError = false;
    _ignoreTextChanges = false;
    notifyListeners();
  }

  void _clearFeedbackAfterDelay(String msg) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_feedbackMessage == msg) {
        _feedbackMessage = '';
        notifyListeners();
      }
    });
  }

  Future<void> changePassword(BuildContext context) async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _feedbackMessage = 'Please fill all fields';
      _isError = true;
      notifyListeners();
      _clearFeedbackAfterDelay('Please fill all fields');
      return;
    }

    if (newPassword.length < 6 || newPassword.length > 8) {
      _feedbackMessage = 'Password length must be between 6 and 8 characters';
      _isError = true;
      notifyListeners();
      _clearFeedbackAfterDelay(
        'Password length must be between 6 and 8 characters',
      );
      return;
    }

    if (!hasUpperAndLowerCase) {
      _feedbackMessage =
          'Password must contain at least one uppercase and one lowercase letter';
      _isError = true;
      notifyListeners();
      _clearFeedbackAfterDelay(
        'Password must contain at least one uppercase and one lowercase letter',
      );
      return;
    }

    if (!hasNumberAndSpecialChar) {
      _feedbackMessage =
          'Password must contain at least one number and one special character';
      _isError = true;
      notifyListeners();
      _clearFeedbackAfterDelay(
        'Password must contain at least one number and one special character',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _feedbackMessage = 'Passwords do not match';
      _isError = true;
      notifyListeners();
      _clearFeedbackAfterDelay('Passwords do not match');
      return;
    }

    if (oldPassword == newPassword) {
      _feedbackMessage =
          'Try picking a new password that you haven’t used before';
      _isError = true;
      notifyListeners();
      _clearFeedbackAfterDelay(
        'Try picking a new password that you haven’t used before',
      );
      return;
    }

    _feedbackMessage = '';
    _isError = false;
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        _feedbackMessage = 'User session not found';
        _isError = true;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String userId = user.id ?? "";
      if (userId.isEmpty) {
        _feedbackMessage = 'User session is invalid';
        _isError = true;
        notifyListeners();
        return;
      }

      final response = await ApiService().put(
        '/users/change-password/$userId',
        data: {
          "currentPassword": oldPassword,
          "newPassword": newPassword,
        },
      );

      final responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201 || (json['success'] == true)) {
        debugPrint("API_FLOW: Password changed successfully");
        if (context.mounted) {
          _feedbackMessage = 'Password changed successfully.';
          _isError = false;

          _ignoreTextChanges = true;
          oldPasswordController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
          _ignoreTextChanges = false;

          oldPasswordFocusNode.unfocus();
          passwordFocusNode.unfocus();
          confirmPasswordFocusNode.unfocus();

          notifyListeners();
          await Future.delayed(const Duration(seconds: 2));

          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        final errorMsg = json['message'] ?? 'Failed to change password';
        debugPrint(
          "API_FLOW: Password change failed with status: ${response.statusCode}",
        );
        if (context.mounted) {
          _feedbackMessage = errorMsg;
          _isError = true;
          notifyListeners();
          _clearFeedbackAfterDelay(errorMsg);
        }
      }
    } catch (e) {
      debugPrint("API_FLOW: Error changing password: $e");
      if (context.mounted) {
        _feedbackMessage = 'An error occurred';
        _isError = true;
        notifyListeners();
        _clearFeedbackAfterDelay('An error occurred');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

