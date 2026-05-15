import 'package:flutter/material.dart';

class ProfileController extends ChangeNotifier {
  bool _isLoading = false;
  String _name = "";
  String _imageUrl = "";
  String _bio = "";
  List<Map<String, dynamic>> _archivedChats = [];

  bool get isLoading => _isLoading;
  String get name => _name;
  String get imageUrl => _imageUrl;
  String get bio => _bio;
  List<Map<String, dynamic>> get archivedChats => _archivedChats;

  // Mock function to fetch archived chats
  Future<void> fetchArchivedChats() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _archivedChats = [
      {
        "id": "c1",
        "name": "Design Team",
        "lastMessage": "Let's review the mockups.",
        "time": "Yesterday",
        "image": "https://i.pravatar.cc/150?u=design"
      },
      {
        "id": "c2",
        "name": "John Smith",
        "lastMessage": "See you soon!",
        "time": "2 days ago",
        "image": "https://i.pravatar.cc/150?u=john"
      },
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Initialize data
  Future<void> init() async {
    await fetchUserDetails();
  }

  // Mock function to fetch user details
  Future<void> fetchUserDetails() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock data
    _name = "Arjun Kashyap";
    _imageUrl = "https://i.pravatar.cc/300";
    _bio =
        "Building the future of secure communication. 🚀 | UI/UX Enthusiast | Flutter Developer";

    _isLoading = false;
    notifyListeners();
  }

  // Mock function to pick/update profile image
  Future<void> pickImage() async {
    _isLoading = true;
    notifyListeners();

    // Simulate selection delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock a new image selection
    _imageUrl =
        "https://i.pravatar.cc/300?img=${DateTime.now().millisecond % 70}";

    _isLoading = false;
    notifyListeners();
  }

  // Mock function to update profile details
  Future<void> updateProfile({
    required String name,
    required String bio,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay for update
    await Future.delayed(const Duration(seconds: 2));

    _name = name;
    _bio = bio;
    if (imageUrl != null) {
      _imageUrl = imageUrl;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mock function to logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Simulate session cleanup
    await Future.delayed(const Duration(seconds: 1));

    // Clear local state
    _name = "";
    _imageUrl = "";
    _bio = "";
    _archivedChats = [];

    _isLoading = false;
    notifyListeners();
  }
}
