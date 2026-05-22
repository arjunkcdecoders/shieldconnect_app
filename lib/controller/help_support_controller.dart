import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/faq_model.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/ticket_model.dart';
import 'package:shieldconnect_app/model/ticket_chat_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:dio/dio.dart' as dio;

class HelpSupportController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // FAQs
  List<FaqModel> _faqs = [];
  List<FaqModel> get faqs => _faqs;

  // Tickets
  List<TicketModel> _tickets = [];
  List<TicketModel> get tickets => _tickets;

  TicketModel? _selectedTicket;
  TicketModel? get selectedTicket => _selectedTicket;

  // Admin Chats
  List<Map<String, dynamic>> _adminMessages = [];
  List<Map<String, dynamic>> get adminMessages => _adminMessages;

  // Fetch FAQs from API
  Future<void> fetchFAQs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().get('/admin/faqs?status=Active');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        _faqs = data
            .map((item) => FaqModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching FAQs: $e");
      // Fallback to empty list on error
      _faqs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _hasFetchedTickets = false;
  bool get hasFetchedTickets => _hasFetchedTickets;

  void resetHasFetchedTickets() {
    _hasFetchedTickets = false;
    notifyListeners();
  }

  // Fetch All User Tickets
  Future<void> fetchUserTickets({bool force = false}) async {
    if (!force && _hasFetchedTickets) return;
    _isLoading = true;
    _hasFetchedTickets = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        _tickets = [];
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? userId = user.id;
      if (userId == null) {
        _tickets = [];
        return;
      }

      final response = await ApiService().get('/tickets?requesterId=$userId&requesterRole=user');
      final dynamic responseData = response.data;

      List<dynamic> listData = [];
      if (responseData is List) {
        listData = responseData;
      } else if (responseData is Map<String, dynamic>) {
        listData = responseData['data'] is List ? responseData['data'] : [];
      } else if (responseData is String) {
        final decoded = jsonDecode(responseData);
        if (decoded is List) {
          listData = decoded;
        } else if (decoded is Map<String, dynamic>) {
          listData = decoded['data'] is List ? decoded['data'] : [];
        }
      }

      _tickets = listData
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error fetching user tickets: $e");
      _tickets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Ticket
  Future<bool> createTicket({
    required String subject,
    required String category,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? userId = user.id;
      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Instantiate a TicketModel to construct the payload using .toJson()
      final TicketModel ticket = TicketModel(
        userId: userId,
        subject: subject,
        category: category,
      );

      final Map<String, dynamic> payload = ticket.toJson()..removeWhere((key, value) => value == null);

      final response = await ApiService().post('/tickets', data: payload);
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true || response.statusCode == 200 || response.statusCode == 201) {
        await fetchUserTickets(force: true);
        return true;
      } else {
        debugPrint("Failed to create ticket: ${response.data}");
        return false;
      }
    } catch (e) {
      debugPrint("Error creating ticket: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search / Filter Tickets
  void searchTickets(String query) {
    if (query.isEmpty) {
      fetchUserTickets();
      return;
    }

    _tickets = _tickets.where((ticket) {
      final subject = ticket.subject?.toLowerCase() ?? "";
      final ticketId = ticket.ticketId?.toLowerCase() ?? "";
      final id = ticket.id?.toLowerCase() ?? "";
      final q = query.toLowerCase();
      return subject.contains(q) || ticketId.contains(q) || id.contains(q);
    }).toList();

    notifyListeners();
  }

  // Fetch Ticket Details
  Future<void> fetchTicketDetails(String ticketId) async {
    _isLoading = true;
    _selectedTicket = null;
    notifyListeners();

    try {
      final response = await ApiService().get('/tickets/$ticketId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        final Map<String, dynamic> data = json['data'] as Map<String, dynamic>;
        _selectedTicket = TicketModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error fetching ticket details: $e");
      _selectedTicket = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch All Chats between Support/Admin and User
  Future<void> fetchTicketMessages(String ticketId) async {
    // Simulated chat thread involving both user and support
    _adminMessages = [
      {
        "text": "Hi, I'm having trouble with my recent message sync.",
        "isMe": true, // User message
        "time": "09:04 PM",
      },
      {
        "text":
            "Hello! I'm sorry to hear that. Could you please provide more details?",
        "isMe": false, // Support/Admin message
        "time": "09:05 PM",
      },
      {
        "text":
            "It seems like messages from the last hour aren't appearing on my desktop app.",
        "isMe": true,
        "time": "09:06 PM",
      },
      {
        "text":
            "Thank you for the info. We are looking into our sync servers. Please hold on.",
        "isMe": false,
        "time": "09:10 PM",
      },
    ];
    notifyListeners();
  }

  // Ticket Chats List
  List<TicketChatModel> _ticketChats = [];
  List<TicketChatModel> get ticketChats => _ticketChats;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  Future<void> loadCurrentUserId() async {
    if (_currentUserId != null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _currentUserId = user.id;
      }
    } catch (e) {
      debugPrint("Error loading current user ID: $e");
    }
  }

  // Fetch Ticket Chats
  Future<void> fetchTicketChats(String ticketId) async {
    await loadCurrentUserId();
    try {
      final response = await ApiService().get('/chats/$ticketId');
      final dynamic responseData = response.data;

      List<dynamic> listData = [];
      if (responseData is List) {
        listData = responseData;
      } else if (responseData is Map<String, dynamic>) {
        listData = responseData['data'] is List ? responseData['data'] : [];
      } else if (responseData is String) {
        final decoded = jsonDecode(responseData);
        if (decoded is List) {
          listData = decoded;
        } else if (decoded is Map<String, dynamic>) {
          listData = decoded['data'] is List ? decoded['data'] : [];
        }
      }

      _ticketChats = listData
          .map((item) => TicketChatModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error fetching ticket chats: $e");
      _ticketChats = [];
    } finally {
      notifyListeners();
    }
  }

  // Send Ticket Message
  Future<bool> sendTicketMessage({
    required String ticketId,
    required String message,
    String? filePath,
  }) async {
    _isSendingMessage = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      if (sessionStr == null) return false;

      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      final String? userId = user.id;
      if (userId == null) return false;

      dynamic payloadData;

      if (filePath != null && filePath.isNotEmpty) {
        payloadData = dio.FormData.fromMap({
          'ticketId': ticketId,
          'userId': userId,
          'message': message,
          'attachment': await dio.MultipartFile.fromFile(
            filePath,
            filename: filePath.split('/').last,
          ),
        });
      } else {
        payloadData = {
          'ticketId': ticketId,
          'userId': userId,
          'message': message,
        };
      }

      final response = await ApiService().post('/chats', data: payloadData);
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true || response.statusCode == 200 || response.statusCode == 201) {
        await fetchTicketChats(ticketId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error sending ticket message: $e");
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }
}
