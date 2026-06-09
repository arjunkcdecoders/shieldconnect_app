import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/controller/bottomnav_controller.dart';
import 'package:shieldconnect_app/model/api_response.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/view/login_screen.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/controller/call_list_controller.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/controller/add_new_chat_controller.dart';

import 'package:dio/dio.dart' as dio_lib;

class ProfileController extends ChangeNotifier {
  ProfileController() {
    init();
    // Attach reactive update listeners for focus nodes
    nameFocusNode.addListener(notifyListeners);
    bioFocusNode.addListener(notifyListeners);
    emailFocusNode.addListener(notifyListeners);
    regionFocusNode.addListener(notifyListeners);
  }

  bool _isLoading = false;
  String _userId = "";
  String _name = "";
  String _email = "";
  String _imageUrl = "";
  String _bio = "";
  File? _pickedImage;
  bool _shouldRemoveAvatar = false;
  bool _showImageOptions = false;
  List<dynamic> _archivedChats = [];
  bool _isModerator = false;
  String _region = "";
  String _appMode = "user";

  // Controllers for editing
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  // Delete Account Flow States
  bool _isPasswordVerifying = false;
  bool _isPasswordVerified = false;
  bool _isAccountDeleting = false;
  bool _showDeleteFailedText = false;
  final TextEditingController deletePasswordController =
      TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode bioFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode regionFocusNode = FocusNode();

  bool get isLoading => _isLoading;
  String get userId => _userId;
  String get name => _name;
  String get email => _email;
  String get imageUrl => _imageUrl;
  String get bio => _bio;
  File? get pickedImage => _pickedImage;
  bool get shouldRemoveAvatar => _shouldRemoveAvatar;
  bool get showImageOptions => _showImageOptions;
  List<dynamic> get archivedChats => _archivedChats;

  bool get isPasswordVerifying => _isPasswordVerifying;
  bool get isPasswordVerified => _isPasswordVerified;
  bool get isAccountDeleting => _isAccountDeleting;
  bool get showDeleteFailedText => _showDeleteFailedText;
  bool get isModerator => _isModerator;
  String get region => _region;
  String get appMode => _appMode;

  // Initialize data
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _appMode = prefs.getString('app_mode') ?? 'user';
    await fetchUserDetails();
    await fetchArchivedChats();
  }

  Future<void> setAppMode(String mode) async {
    _appMode = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode);
    notifyListeners();
  }

  // Fetch user details from session
  Future<void> fetchUserDetails() async {
    try {
      _shouldRemoveAvatar = false;
      _showImageOptions = false;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _appMode = prefs.getString('app_mode') ?? 'user';
      final String? sessionStr = prefs.getString('user_session');
      debugPrint("ProfileController: sessionStr: $sessionStr");

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id ?? "";
        _isModerator = user.isModerator ?? false;
        _region = user.region ?? "";
        regionController.text = _region;
        debugPrint(
          "ProfileController: userId: $_userId, isModerator: $_isModerator, region: $_region",
        );

        if (_userId.isNotEmpty) {
          final response = await ApiService().get(
            '/users/$_userId?currentUserId=$_userId',
          );
          debugPrint("ProfileController: API Response: ${response.data}");

          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json.containsKey('success') && json['success'] == true) {
            final data = json['data'];
            if (data != null) {
              _name = data['name'] ?? "";
              _email = data['email'] ?? "";
              _imageUrl = data['avatar'] ?? "";
              _bio = data['bio'] ?? "";
              _isModerator =
                  data['is_moderator'] as bool? ??
                  data['isModerator'] as bool? ??
                  false;

              // Safe region parsing
              final dynamic rawRegion = data['region'];
              if (rawRegion is Map) {
                _region = rawRegion['name'] as String? ?? "";
              } else if (rawRegion is String) {
                if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(rawRegion)) {
                  _region = await _fetchRegionNameById(rawRegion);
                } else {
                  _region = rawRegion;
                }
              } else {
                _region = "";
              }

              // Populate controllers for EditProfileScreen
              nameController.text = _name;
              bioController.text = _bio;
              emailController.text = _email;
              regionController.text = _region;

              // Save the fetched user to SharedPreferences to keep session updated with settings
              final UserModel fetchedUser = UserModel.fromJson(data);
              await prefs.setString(
                'user_session',
                jsonEncode(fetchedUser.toJson()),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user details from API: $e");
    }

    notifyListeners();
  }

  Future<String> _fetchRegionNameById(String regionId) async {
    try {
      final response = await ApiService().get('/admin/regions');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> regionsList = json['data'] ?? [];
        for (var r in regionsList) {
          if (r['_id'] == regionId) {
            return r['name'] as String? ?? "";
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching region name by ID: $e");
    }
    return regionId;
  }

  final Set<String> _failedUnarchiveChatIds = {};
  Set<String> get failedUnarchiveChatIds => _failedUnarchiveChatIds;

  // Fetch archived chats from API
  Future<void> fetchArchivedChats() async {
    if (_userId.isEmpty) {
      await fetchUserDetails();
    }
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().get('/chat/archived/$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _archivedChats = json['data'] ?? [];
        _failedUnarchiveChatIds.clear();
      } else {
        _archivedChats = [];
      }
    } catch (e) {
      debugPrint("Error fetching archived chats: $e");
      _archivedChats = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Unarchive chat via API
  Future<bool> unarchiveChat(String chatId) async {
    if (_userId.isEmpty) return false;
    try {
      final response = await ApiService().put(
        '/chat/unarchive',
        data: {"userId": _userId, "chatId": chatId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchArchivedChats();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error unarchiving chat: $e");
      return false;
    }
  }

  // Handle unarchive chat flow (error tracking, home screen updates)
  Future<bool> handleUnarchiveChat(BuildContext context, String chatId) async {
    final success = await unarchiveChat(chatId);
    if (success) {
      if (context.mounted) {
        context.read<HomeScreenController>().fetchRecentChats(
          updateLoadingState: false,
        );
      }
      return true;
    } else {
      _failedUnarchiveChatIds.add(chatId);
      notifyListeners();

      Future.delayed(const Duration(seconds: 4), () {
        _failedUnarchiveChatIds.remove(chatId);
        notifyListeners();
      });
      return false;
    }
  }

  // Pick profile image from device
  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        _pickedImage = File(image.path);
        _shouldRemoveAvatar = false;
        _showImageOptions = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Remove profile image
  void removeImage() {
    _pickedImage = null;
    _imageUrl = "";
    _shouldRemoveAvatar = true;
    _showImageOptions = false;
    notifyListeners();
  }

  // Toggle/Set showing photo edit options on the right side of image
  void toggleImageOptions() {
    _showImageOptions = !_showImageOptions;
    notifyListeners();
  }

  void setImageOptions(bool show) {
    _showImageOptions = show;
    notifyListeners();
  }

  String _message = "";
  bool _isError = false;

  String get message => _message;
  bool get isError => _isError;

  void clearMessage() {
    _message = "";
    _isError = false;
    notifyListeners();
  }

  void setMessage(String msg, {bool isError = false}) {
    _message = msg;
    _isError = isError;
    notifyListeners();
  }

  // Update profile details via API
  Future<void> updateProfile(BuildContext context) async {
    if (_userId.isEmpty) {
      setMessage("User ID not found. Please log in again.", isError: true);
      return;
    }

    clearMessage();
    _isLoading = true;
    notifyListeners();

    try {
      // Prepare multipart form data
      Map<String, dynamic> data = {
        "name": nameController.text.trim(),
        "bio": bioController.text.trim(),
      };

      if (_pickedImage != null) {
        data["avatar"] = await dio_lib.MultipartFile.fromFile(
          _pickedImage!.path,
          filename: _pickedImage!.path.split('/').last,
        );
      } else if (_shouldRemoveAvatar) {
        data["avatar"] = "";
        data["removeAvatar"] = "true";
      }

      final formData = dio_lib.FormData.fromMap(data);

      final response = await ApiService().put(
        "/users/profile/$_userId",
        data: formData,
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      final apiResponse = ApiResponse<UserModel>.fromJson(
        json,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        // Update local session with new user data
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_session',
          jsonEncode(apiResponse.data!.toJson()),
        );

        // Notify HomeScreenController to refresh the profile image
        if (context.mounted) {
          context.read<HomeScreenController>().fetchProfileImage();
          context.read<CallListController>().fetchProfileImage();
        }

        // Update local state variables
        _name = apiResponse.data!.name ?? _name;
        _imageUrl = apiResponse.data!.avatar ?? _imageUrl;
        _bio = apiResponse.data!.bio ?? _bio;
        _pickedImage = null; // Clear picked image after success
        _shouldRemoveAvatar = false;

        setMessage(apiResponse.message ?? "Profile updated!");

        // Return to profile screen after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            clearMessage();
            Navigator.pop(context);
          }
        });
      } else {
        setMessage(apiResponse.message ?? "Update failed", isError: true);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      setMessage("Connection error. Try again.", isError: true);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Reset delete account states
  void resetDeleteAccountState() {
    deletePasswordController.clear();
    _isPasswordVerifying = false;
    _isPasswordVerified = false;
    _isAccountDeleting = false;
    _showDeleteFailedText = false;
    notifyListeners();
  }

  // Verify password via API
  Future<bool> verifyPassword(String password) async {
    if (_userId.isEmpty) return false;
    _isPasswordVerifying = true;
    _showDeleteFailedText = false;
    notifyListeners();
    try {
      final response = await ApiService().post(
        '/users/verify-password/$_userId',
        data: {'password': password},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      final success = json['success'] == true;
      if (success) {
        _isPasswordVerified = true;
      } else {
        _showDeleteFailedText = true;
        Future.delayed(const Duration(seconds: 3), () {
          _showDeleteFailedText = false;
          notifyListeners();
        });
      }
      _isPasswordVerifying = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error verifying password: $e");
      _showDeleteFailedText = true;
      Future.delayed(const Duration(seconds: 3), () {
        _showDeleteFailedText = false;
        notifyListeners();
      });
      _isPasswordVerifying = false;
      notifyListeners();
      return false;
    }
  }

  // Delete account via API, clear session, and navigate to Login
  Future<bool> deleteAccount(BuildContext context) async {
    if (_userId.isEmpty) return false;
    _isAccountDeleting = true;
    notifyListeners();
    try {
      final response = await ApiService().delete('/admin/users/$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        // Clear session from SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_session');

        // Disconnect and clean up the active socket connection
        SocketService().disconnect();

        // Clear local state variables
        _name = "";
        _email = "";
        _imageUrl = "";
        _bio = "";
        _archivedChats = [];
        _failedUnarchiveChatIds.clear();
        _pickedImage = null;
        _isModerator = false;
        _region = "";
        regionController.clear();

        // Reset delete states
        deletePasswordController.clear();
        _isPasswordVerifying = false;
        _isPasswordVerified = false;
        _isAccountDeleting = false;
        _showDeleteFailedText = false;

        _isLoading = false;
        notifyListeners();

        if (context.mounted) {
          context.read<StatusController>().init();
          context.read<AddNewChatController>().init();
          // Reset bottom navigation index and check status feature
          context.read<BottomnavController>().reset();
          context.read<BottomnavController>().checkStatusFeature();
          // Navigate to LoginScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
    }
    _isAccountDeleting = false;
    notifyListeners();
    return false;
  }

  // function to logout
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Clear session from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');

    // Disconnect and clean up the active socket connection
    SocketService().disconnect();

    // Simulate session cleanup
    await Future.delayed(const Duration(seconds: 1));

    // Clear local state
    _name = "";
    _email = "";
    _imageUrl = "";
    _bio = "";
    _archivedChats = [];
    _failedUnarchiveChatIds.clear();
    _pickedImage = null;
    _isModerator = false;
    _region = "";
    regionController.clear();

    _isLoading = false;
    notifyListeners();

    if (context.mounted) {
      context.read<StatusController>().init();
      context.read<AddNewChatController>().init();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
    // Reset bottom navigation index and check status feature
    if (context.mounted) {
      context.read<BottomnavController>().reset();
      context.read<BottomnavController>().checkStatusFeature();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    emailController.dispose();
    regionController.dispose();
    deletePasswordController.dispose();
    nameFocusNode.dispose();
    bioFocusNode.dispose();
    emailFocusNode.dispose();
    regionFocusNode.dispose();
    super.dispose();
  }
}
