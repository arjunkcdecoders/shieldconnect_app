import 'package:flutter/material.dart';
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
    // Mock fetching connected users
    await Future.delayed(const Duration(milliseconds: 500));
    _connectedUsers = [
      {"id": "1", "name": "Maisie williams", "subtitle": "maisiewilliams@gmail.com", "isSelected": false},
      {"id": "2", "name": "John Doe", "subtitle": "johndoe@gmail.com", "isSelected": false},
      {"id": "3", "name": "Jane Smith", "subtitle": "janesmith@gmail.com", "isSelected": false},
      {"id": "4", "name": "Alex Wilson", "subtitle": "alex@gmail.com", "isSelected": false},
    ];
    _searchResults = List.from(_connectedUsers);
    notifyListeners();
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      _searchResults = List.from(_connectedUsers);
    } else {
      _searchResults = _connectedUsers
          .where((user) =>
              user['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void toggleUserSelection(int index) {
    if (index >= 0 && index < _searchResults.length) {
      _searchResults[index]['isSelected'] = !(_searchResults[index]['isSelected'] ?? false);
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    // Mock picking an image
    await Future.delayed(const Duration(milliseconds: 300));
    _pickedImagePath = 'assets/images/mock_group_image.png';
    notifyListeners();
  }

  Future<void> createGroup(BuildContext context) async {
    if (groupNameController.text.trim().isEmpty) {
      ToastHelper.showToast(context, "Please enter a group name");
      return;
    }

    if (_pickedImagePath == null) {
      ToastHelper.showToast(context, "Please select a group image");
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Mock group creation delay
    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();

    if (context.mounted) {
      ToastHelper.showToast(context, "Group created successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(
            groupName: groupNameController.text.trim(),
          ),
        ),
      );
    }
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
