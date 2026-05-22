import 'package:flutter/material.dart';
import 'package:shieldconnect_app/model/api_response.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class SignupController extends ChangeNotifier {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode userNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  String _message = '';
  String get message => _message;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  SignupController() {
    userNameFocus.addListener(notifyListeners);
    emailFocus.addListener(notifyListeners);
    passwordFocus.addListener(notifyListeners);

    userNameController.addListener(clearError);
    emailController.addListener(clearError);
    passwordController.addListener(clearError);
    passwordController.addListener(notifyListeners);
  }

  void clearError() {
    if (_message.isNotEmpty) {
      _message = '';
      _isSuccess = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Dynamic conditions for password validation
  bool get isAtLeast6Chars {
    final pass = passwordController.text;
    return pass.length >= 6 && pass.length <= 8;
  }

  bool get hasUpperAndLowerCase {
    final pass = passwordController.text;
    return RegExp(r'[a-z]').hasMatch(pass) && RegExp(r'[A-Z]').hasMatch(pass);
  }

  bool get hasNumberAndSpecialChar {
    final pass = passwordController.text;
    return RegExp(r'\d').hasMatch(pass) &&
        RegExp(r'[^a-zA-Z0-9\s]').hasMatch(pass);
  }

  Future<void> signup(BuildContext context) async {
    if (userNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _message = "Please fill the fields";
      _isSuccess = false;
      notifyListeners();
      return;
    }

    if (!isAtLeast6Chars) {
      _message = "Password length must be between 6 and 8 characters";
      _isSuccess = false;
      notifyListeners();
      return;
    }
    if (!hasUpperAndLowerCase) {
      _message =
          "Password must contain at least one uppercase and one lowercase letter";
      _isSuccess = false;
      notifyListeners();
      return;
    }
    if (!hasNumberAndSpecialChar) {
      _message =
          "Password must contain at least one number and one special character";
      _isSuccess = false;
      notifyListeners();
      return;
    }

    _message = "";
    _isSuccess = false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().post(
        "/auth/register",
        data: {
          "name": userNameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      final apiResponse = ApiResponse<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      _isLoading = false;
      notifyListeners();

      if (apiResponse.success) {
        _message = "Registration successful!";
        _isSuccess = true;
        notifyListeners();

        // Wait a bit to show the message
        await Future.delayed(const Duration(seconds: 1));

        if (context.mounted) {
          _message = "";
          _isSuccess = false;
          notifyListeners();

          _showAccountPendingDialog(context);
        }
      } else {
        _message = "Registration failed";
        _isSuccess = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _message = "Oops! We hit a small problem. Please try again.";
      _isSuccess = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    userNameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void _showAccountPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: appColor(context).white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(ImageAssets.appIcon, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(
                    "ShieldConnect",
                    style: fontStyle.clashDisplayBold16.textColor(
                      appColor(context).black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appColor(context).secondary,
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: appColor(context).secondary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Account Pending",
                style: fontStyle.clashDisplayBold18.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Your account is currently pending admin approval. You will be able to log in once an administrator has reviewed and approved your request.",
                textAlign: TextAlign.center,
                style: fontStyle.clashDisplayRegular14.textColor(
                  appColor(context).grey500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    userNameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to login screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor(context).secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Back to Login",
                    style: fontStyle.clashDisplaySemiBold16.textColor(
                      appColor(context).white,
                    ),
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
