import 'package:flutter/material.dart';
import 'package:shieldconnect_app/model/api_response.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/view/otp_verification_screen.dart';
import 'package:shieldconnect_app/view/reset_password_screen.dart';

class ForgotPasswordController extends ChangeNotifier {
  // 1. Forgot Password Screen State
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocus = FocusNode();

  // 2. OTP Verification Screen State
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  // 3. Reset Password Screen State
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _message = "";
  bool _isError = false;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isLoading => _isLoading;
  String get message => _message;
  bool get isError => _isError;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setMessage(String msg, {bool isError = false}) {
    _message = msg;
    _isError = isError;
    notifyListeners();
  }

  void clearMessage() {
    _message = "";
    _isError = false;
    notifyListeners();
  }

  // --- API Functions ---

  /// Sends OTP to the provided email via API
  Future<void> sendOtp(BuildContext context) async {
    clearMessage();
    if (emailController.text.trim().isEmpty) {
      setMessage("Please enter your email", isError: true);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().post(
        "/auth/forgot-password",
        data: {"email": emailController.text.trim()},
      );

      final apiResponse = ApiResponse.fromJson(response.data, (json) => json);

      _isLoading = false;
      notifyListeners();

      if (apiResponse.success) {
        setMessage(apiResponse.message ?? "OTP sent successfully!");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OtpVerificationScreen(),
          ),
        );
      } else {
        setMessage(apiResponse.message ?? "Failed to send OTP", isError: true);
      }
    } catch (e) {
      _isLoading = false;
      setMessage("Connection error. Please try again.", isError: true);
      notifyListeners();
    }
  }

  /// Verifies the 6-digit OTP via API
  Future<void> verifyOtp(BuildContext context) async {
    clearMessage();
    String otp = otpControllers.map((e) => e.text).join();

    if (otp.length < 6) {
      setMessage("Please enter complete 6-digit OTP", isError: true);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().post(
        "/auth/verify-otp",
        data: {"email": emailController.text.trim(), "otp": otp},
      );

      final apiResponse = ApiResponse.fromJson(response.data, (json) => json);

      _isLoading = false;
      notifyListeners();

      if (apiResponse.success) {
        setMessage(apiResponse.message ?? "OTP Verified Successfully!");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      } else {
        setMessage(apiResponse.message ?? "Invalid OTP", isError: true);
      }
    } catch (e) {
      _isLoading = false;
      setMessage(
        "Oops! We hit a small problem. Please try again.",
        isError: true,
      );
      notifyListeners();
    }
  }

  /// Resets the password via API
  Future<void> resetPassword(BuildContext context) async {
    clearMessage();
    if (passwordController.text.isEmpty) {
      setMessage("Please enter new password", isError: true);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setMessage("Passwords do not match", isError: true);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      String otp = otpControllers.map((e) => e.text).join();
      final response = await ApiService().post(
        "/auth/reset-password",
        data: {
          "email": emailController.text.trim(),
          "otp": otp,
          "password": passwordController.text.trim(),
          "confirmPassword": confirmPasswordController.text.trim(),
        },
      );

      final apiResponse = ApiResponse.fromJson(response.data, (json) => json);

      _isLoading = false;
      notifyListeners();

      if (apiResponse.success) {
        setMessage(apiResponse.message ?? "Password Reset Successfully!");

        // Clear all fields and navigate back to login after a delay
        Future.delayed(const Duration(seconds: 1), () {
          emailController.clear();
          for (var c in otpControllers) {
            c.clear();
          }
          passwordController.clear();
          confirmPasswordController.clear();
          clearMessage();
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      } else {
        setMessage(
          apiResponse.message ?? "Failed to reset password",
          isError: true,
        );
      }
    } catch (e) {
      _isLoading = false;
      setMessage(
        "Oops! We hit a small problem. Please try again.",
        isError: true,
      );
      notifyListeners();
    }
  }

  void nextField(String value, int index) {
    if (value.length == 1 && index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocus.dispose();
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in otpFocusNodes) {
      f.dispose();
    }
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }
}
