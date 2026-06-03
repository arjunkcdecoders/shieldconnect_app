import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class AddNewChatController extends ChangeNotifier {
  AddNewChatController() {
    init();
  }

  List<dynamic> _allUsers = [];
  List<dynamic> get allUsers => _allUsers;

  List<dynamic> _searchResults = [];
  String _activeChipTab = "People"; // "People" or "Friends"
  String get activeChipTab => _activeChipTab;

  void setActiveChipTab(String tab) {
    _activeChipTab = tab;
    notifyListeners();
    if (tab == "Friends") {
      fetchAllUsers();
    }
  }

  List<dynamic> get searchResults {
    if (_activeChipTab == "Friends") {
      return _searchResults.where((u) {
        final String? uid = u['_id']?.toString() ?? u['id']?.toString();
        if (uid == null || uid == _userId) return false;

        final relationship = u['relationship'];
        final String relStatus = relationship != null
            ? (relationship['status']?.toString() ?? '')
            : '';
        return relStatus == 'accepted';
      }).toList();
    } else {
      return _searchResults.where((u) {
        final String? uid = u['_id']?.toString() ?? u['id']?.toString();
        if (uid == null || uid == _userId) return false;

        final relationship = u['relationship'];
        final String relStatus = relationship != null
            ? (relationship['status']?.toString() ?? '')
            : '';
        return relStatus != 'accepted';
      }).toList();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? _userId;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  final Set<String> _loadingUserIds = {};
  Set<String> get loadingUserIds => _loadingUserIds;

  Future<void> init() async {
    scrollController.removeListener(_onScroll);
    scrollController.addListener(_onScroll);

    searchController.clear();
    _searchQuery = "";
    _activeChipTab = "People";
    _allUsers = [];
    _searchResults = [];
    _currentPage = 1;
    _totalPages = 1;
    _isLoadingMore = false;
    _loadingUserIds.clear();

    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      _userId = user.id;
    } else {
      _userId = null;
    }

    await fetchAllUsers();

    _isLoading = false;
    notifyListeners();
  }

  String _searchQuery = "";
  Timer? _debounce;

  Future<void> fetchAllUsers({
    bool isLoadMore = false,
    String? searchQuery,
  }) async {
    if (_userId == null) return;

    if (searchQuery != null) {
      _searchQuery = searchQuery;
    }

    if (isLoadMore) {
      if (_currentPage >= _totalPages) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _currentPage = 1;
      _isLoading = true;
      if (!isLoadMore) {
        _allUsers = []; // Clear for new search
      }
    }
    notifyListeners();

    try {
      if (_activeChipTab == "Friends" && !isLoadMore) {
        int page = 1;
        int totalPages = 1;
        List<dynamic> allFetched = [];
        do {
          String url = '/users?currentUserId=$_userId&page=$page';
          if (_searchQuery.isNotEmpty) {
            url += '&name=$_searchQuery';
          }
          final response = await ApiService().get(url);
          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json['success'] == true) {
            final List<dynamic> fetchedUsers = json['data'] ?? [];
            final filteredUsers = fetchedUsers.where((u) {
              final String? uid = u['_id']?.toString() ?? u['id']?.toString();
              return uid != null && uid != _userId;
            }).toList();

            allFetched.addAll(filteredUsers);

            if (json['pagination'] != null) {
              totalPages = json['pagination']['total_pages'] ?? 1;
            } else {
              break;
            }
          } else {
            break;
          }
          page++;
        } while (page <= totalPages);

        _allUsers = allFetched;
        _currentPage = totalPages;
        _totalPages = totalPages;
        _searchResults = List.from(_allUsers);
      } else {
        String url = '/users?currentUserId=$_userId&page=$_currentPage';
        if (_searchQuery.isNotEmpty) {
          url += '&name=$_searchQuery';
        }

        final response = await ApiService().get(url);
        final dynamic responseData = response.data;
        final Map<String, dynamic> json = responseData is String
            ? jsonDecode(responseData)
            : responseData as Map<String, dynamic>;

        if (json['success'] == true) {
          final List<dynamic> fetchedUsers = json['data'] ?? [];
          final filteredUsers = fetchedUsers.where((u) {
            final String? uid = u['_id']?.toString() ?? u['id']?.toString();
            return uid != null && uid != _userId;
          }).toList();

          if (isLoadMore) {
            _allUsers.addAll(filteredUsers);
          } else {
            _allUsers = filteredUsers;
          }

          if (json['pagination'] != null) {
            _totalPages = json['pagination']['total_pages'] ?? 1;
          }

          _searchResults = List.from(_allUsers);
        }
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreUsers() async {
    await fetchAllUsers(isLoadMore: true);
  }

  void searchUsers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchAllUsers(searchQuery: query);
    });
  }

  Future<void> connectUser(String recipientId) async {
    if (_userId == null) return;
    _loadingUserIds.add(recipientId);
    notifyListeners();
    try {
      final response = await ApiService().post(
        '/connections/connect',
        data: {"senderId": _userId, "recipientId": recipientId},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final index = _allUsers.indexWhere((u) => u['_id'] == recipientId);
        if (index != -1) {
          _allUsers[index] = Map<String, dynamic>.from(_allUsers[index]);
          _allUsers[index]['relationship'] = {
            'status': 'pending',
            'requested_by': _userId,
          };
          _searchResults = List.from(_allUsers);
        }
      }
    } catch (e) {
      debugPrint("Error connecting user: $e");
    } finally {
      _loadingUserIds.remove(recipientId);
      notifyListeners();
    }
  }

  Future<void> cancelConnection(String recipientId) async {
    if (_userId == null) return;
    _loadingUserIds.add(recipientId);
    notifyListeners();
    try {
      final response = await ApiService().delete(
        '/connections/cancel',
        data: {"senderId": _userId, "recipientId": recipientId},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final index = _allUsers.indexWhere((u) => u['_id'] == recipientId);
        if (index != -1) {
          _allUsers[index] = Map<String, dynamic>.from(_allUsers[index]);
          _allUsers[index]['relationship'] = null;
          _searchResults = List.from(_allUsers);
        }
      }
    } catch (e) {
      debugPrint("Error cancelling connection: $e");
    } finally {
      _loadingUserIds.remove(recipientId);
      notifyListeners();
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_isLoading && _currentPage < _totalPages) {
        loadMoreUsers();
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}
