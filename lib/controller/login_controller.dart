import 'package:flutter/material.dart';

import 'package:shieldconnect_app/view/bottomnav_screen.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  String _message = '';
  String get message => _message;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> init() async {
    setLoading(true);

    await Future.delayed(const Duration(seconds: 2));

    setLoading(false);
  }

  LoginController() {
    // Listen to focus changes to update UI highlighting
    emailFocus.addListener(() {
      notifyListeners();
    });
    passwordFocus.addListener(() {
      notifyListeners();
    });

    emailController.addListener(clearError);
    passwordController.addListener(clearError);
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

  Future<void> login(BuildContext context) async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _message = "Please fill the fields";
      _isSuccess = false;
      notifyListeners();
    } else {
      _message = "";
      _isSuccess = false;
      setLoading(true);
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      setLoading(false);

      // Mocking a successful login for demonstration
      bool success = emailController.text.trim() == "user@example.com" && passwordController.text.trim() == "password123";

      if (success) {
        _message = "Log In Successful!";
        _isSuccess = true;
        notifyListeners();
        
        // Wait a bit so user can see the success message before navigating
        await Future.delayed(const Duration(seconds: 1));
        
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomnavScreen()),
          );
        }
      } else {
        _message = "Invalid Email or Password";
        _isSuccess = false;
        notifyListeners();
      }
    }
  }

  void forgotPassword() {
    // Handle forgot password logic
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }
}
