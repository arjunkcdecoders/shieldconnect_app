import 'package:flutter/material.dart';

class AddNewChatController extends ChangeNotifier {
  List<dynamic> _allUsers = [];
  List<dynamic> get allUsers => _allUsers;

  List<dynamic> _searchResults = [];
  List<dynamic> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController searchController = TextEditingController();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await fetchAllUsers();
    await fetchConnectionStatuses();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllUsers() async {
    // Mock fetching all users
    await Future.delayed(const Duration(milliseconds: 500));
    _allUsers = [
      {'id': '1', 'name': 'Alice Johnson', 'avatar': null, 'status': 'Available'},
      {'id': '2', 'name': 'Bob Wilson', 'avatar': null, 'status': 'Busy'},
      {'id': '3', 'name': 'Charlie Davis', 'avatar': null, 'status': 'Available'},
    ];
    _searchResults = List.from(_allUsers);
    notifyListeners();
  }

  Future<void> fetchConnectionStatuses() async {
    // Mock fetching connection statuses for the user list
    await Future.delayed(const Duration(milliseconds: 300));
    for (var user in _allUsers) {
      user['connection_status'] = 'none'; // none, pending, connected, blocked
    }
    notifyListeners();
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      _searchResults = List.from(_allUsers);
    } else {
      _searchResults = _allUsers
          .where((user) =>
              user['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
