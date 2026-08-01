import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/controller/homescreen_controller.dart';
import 'package:shieldconnect_app/model/group_model.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/settings_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:shieldconnect_app/view/group_chat_screen.dart';

class CreateGroupController extends ChangeNotifier {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final FocusNode groupNameFocus = FocusNode();
  final FocusNode groupDescFocus = FocusNode();

  List<Map<String, dynamic>> _connectedUsers = [];
  List<Map<String, dynamic>> get connectedUsers => _connectedUsers;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get hasSelectedUsers =>
      _searchResults.any((p) => p['isSelected'] == true);

  String? _pickedImagePath;
  String? get pickedImagePath => _pickedImagePath;

  CreateGroupController() {
    groupNameFocus.addListener(notifyListeners);
    groupDescFocus.addListener(notifyListeners);
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await fetchConnectedUsers();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchConnectedUsers() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) return;

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? userId = user.id;
      if (userId == null) return;

      final response = await ApiService().get('/connections/friends/$userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _connectedUsers = data.map((item) {
          final Map<String, dynamic> friend = item as Map<String, dynamic>;
          // Skip if the user is blocked
          return {
            "id": friend['user_id']?.toString() ?? "",
            "name": friend['name']?.toString() ?? "Unknown",
            "subtitle":
                friend['email']?.toString() ??
                (friend['bio']?.toString() ?? "Hey there!"),
            "avatar": friend['avatar']?.toString() ?? "",
            "isSelected": false,
          };
        }).toList();

        _searchResults = List.from(_connectedUsers);
      }
    } catch (e) {
      debugPrint("Error fetching connected users in group controller: $e");
    }
    notifyListeners();
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      _searchResults = List.from(_connectedUsers);
    } else {
      _searchResults = _connectedUsers
          .where(
            (user) => user['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  void toggleUserSelection(int index) {
    if (index >= 0 && index < _searchResults.length) {
      _searchResults[index]['isSelected'] =
          !(_searchResults[index]['isSelected'] ?? false);
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _pickedImagePath = image.path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking group image: $e");
    }
  }

  Future<void> createGroup(BuildContext context) async {
    if (groupNameController.text.trim().isEmpty) {
      ToastHelper.showToast(context, "Please enter a group name");
      return;
    }

    final List<String> memberIds = _searchResults
        .where((p) => p['isSelected'] == true)
        .map((p) => p['id'].toString())
        .toList();

    if (memberIds.isEmpty) {
      ToastHelper.showToast(context, "Please select at least one member");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? userId = user.id;
      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Add the creator's ID to the members list if not already present
      if (!memberIds.contains(userId)) {
        memberIds.add(userId);
      }

      final homeScreenController = Provider.of<HomeScreenController>(
        context,
        listen: false,
      );
      final int userGroupCount = homeScreenController.recentChats.where((chat) {
        if (chat is Map) {
          final conversation = chat['conversation'];
          if (conversation is Map) {
            return conversation['type'] == 'group';
          }
        }
        return false;
      }).length;

      final settings = await SettingsModel.loadActiveSettings();
      final maxGroup = settings.maxGroup ?? 50;

      if (userGroupCount >= maxGroup) {
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ToastHelper.showWarningDialog(
            context,
            "Group Limit Reached",
            "You cannot be in or create more than $maxGroup groups. Currently, you are in $userGroupCount groups.",
          );
        }
        return;
      }

      final int maxMembers = settings.maxGroupMembers ?? 256;
      if (memberIds.length > maxMembers) {
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ToastHelper.showWarningDialog(
            context,
            "Group Member Limit Exceeded",
            "This group cannot have more than $maxMembers members (including you). Currently, you have selected ${memberIds.length} members.",
          );
        }
        return;
      }

      // Prepare multi-part request body using Dio's FormData
      final Map<String, dynamic> fields = {
        "name": groupNameController.text.trim(),
        "admin_id": userId,
        "description": groupDescController.text.trim(),
        "members": jsonEncode(memberIds),
      };

      final FormData formData = FormData.fromMap(fields);

      if (_pickedImagePath != null &&
          !_pickedImagePath!.startsWith('assets/')) {
        final String filename = _pickedImagePath!.split('/').last;
        formData.files.add(
          MapEntry(
            "group_image",
            await MultipartFile.fromFile(_pickedImagePath!, filename: filename),
          ),
        );
      }

      final response = await ApiService().post('/groups', data: formData);
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        // Map response using GroupModel
        final GroupModel createdGroup = GroupModel.fromJson(json['data']);

        ToastHelper.showToast(
          context,
          json['message']?.toString() ?? "Group created successfully!",
        );

        // Refresh recent chats so it shows in the chat list screen immediately
        if (context.mounted) {
          Provider.of<HomeScreenController>(
            context,
            listen: false,
          ).fetchRecentChats(updateLoadingState: false);
        }

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupName: createdGroup.name ?? groupNameController.text.trim(),
                groupId: createdGroup.id,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context,
            json['message']?.toString() ?? "Failed to create group",
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating group: $e");
      if (context.mounted) {
        ToastHelper.showToast(
          context,
          "An error occurred while creating group",
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    groupNameController.clear();
    groupDescController.clear();
    searchController.clear();
    _pickedImagePath = null;
    for (var user in _connectedUsers) {
      user['isSelected'] = false;
    }
    _searchResults = List.from(_connectedUsers);
    notifyListeners();
  }

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescController.dispose();
    searchController.dispose();
    groupNameFocus.dispose();
    groupDescFocus.dispose();
    super.dispose();
  }
}
