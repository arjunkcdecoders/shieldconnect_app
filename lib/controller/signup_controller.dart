import 'package:flutter/material.dart';

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

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

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
      _message = "Password must contain at least one uppercase and one lowercase letter";
      _isSuccess = false;
      notifyListeners();
      return;
    }
    if (!hasNumberAndSpecialChar) {
      _message = "Password must contain at least one number and one special character";
      _isSuccess = false;
      notifyListeners();
      return;
    }

    _message = "";
    _isSuccess = false;
    setLoading(true);

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    setLoading(false);
    _message = "Registration successful!";
    _isSuccess = true;
    notifyListeners();

    // Wait a bit to show the message
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.pop(context);
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
}
