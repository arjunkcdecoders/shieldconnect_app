import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:shieldconnect_app/model/api_response.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/controller/call_list_controller.dart';
import 'package:shieldconnect_app/view/bottomnav_screen.dart';
import 'package:shieldconnect_app/view/launch_loading_screen.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';
import 'package:shieldconnect_app/services/socket_service.dart';

import 'package:shieldconnect_app/services/call_manager.dart';

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

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();
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

  void resetFields() {
    emailController.clear();
    passwordController.clear();
    emailFocus.unfocus();
    passwordFocus.unfocus();
    _message = "";
    _isSuccess = false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _message = "Please fill the fields";
      _isSuccess = false;
      notifyListeners();
    } else {
      _message = "";
      _isSuccess = false;
      _isLoading = true;
      notifyListeners();

      try {
        final response = await ApiService().post(
          "/auth/login",
          data: {
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
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_session',
            jsonEncode(apiResponse.data?.toJson()),
          );

          // Connect to the socket server using the newly active user session
          final String? userId = apiResponse.data?.id;
          if (userId != null) {
            SocketService().connect(userId);
            CallManager().init(
              userId,
              apiResponse.data?.name ?? 'User',
              myUserAvatar: apiResponse.data?.avatar,
            );
          }

          _message = "Log In Successful!";
          _isSuccess = true;
          notifyListeners();

          // Wait a bit so user can see the success message before navigating
          await Future.delayed(const Duration(seconds: 1));

          if (context.mounted) {
            // Refresh controllers with new session data AFTER the delay, right before navigating,
            // to ensure the loading syncing spinner is active when ChatlistScreen mounts.
            context.read<BottomnavController>().checkStatusFeature();
            context.read<HomeScreenController>().init();
            context.read<ProfileController>().init(context: context);
            context.read<NotificationController>().init();
            context.read<CallListController>().init();
            context.read<StatusController>().init();
            context.read<AddNewChatController>().init();
            context.read<AnnouncementController>().fetchAnnouncements();

            emailController.clear();
            passwordController.clear();
            _message = "";
            _isSuccess = false;
            notifyListeners();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LaunchLoadingScreen()),
            );
          }
        } else {
          _message = apiResponse.message ?? "Invalid Email or Password";
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
