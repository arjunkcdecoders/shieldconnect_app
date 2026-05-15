import 'package:flutter/material.dart';

class HelpSupportController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // FAQs
  List<Map<String, String>> _faqs = [];
  List<Map<String, String>> get faqs => _faqs;

  // Tickets
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> get tickets => _tickets;
  
  Map<String, dynamic>? _selectedTicket;
  Map<String, dynamic>? get selectedTicket => _selectedTicket;

  // Admin Chats
  List<Map<String, dynamic>> _adminMessages = [];
  List<Map<String, dynamic>> get adminMessages => _adminMessages;

  // Fetch FAQs
  Future<void> fetchFAQs() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _faqs = [
      {
        "q": "How to backup my chats?",
        "a": "Your chats are automatically backed up to our secure cloud servers every 24 hours."
      },
      {
        "q": "Can I use Shield Connect on multiple devices?",
        "a": "Yes, you can link up to 4 devices to your account simultaneously."
      },
      {
        "q": "How to delete my account?",
        "a": "You can delete your account from the 'Account' settings menu. This action is permanent."
      },
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Fetch All User Tickets
  Future<void> fetchUserTickets() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _tickets = [
      {
        "id": "TCKT-009",
        "subject": "Bug",
        "category": "Bug Report",
        "status": "Open",
        "lastUpdated": "5/6/2026"
      },
      {
        "id": "TCKT-008",
        "subject": "Account Recovery",
        "category": "General Inquiry",
        "status": "Closed",
        "lastUpdated": "1/6/2026"
      },
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Create Ticket
  Future<void> createTicket({
    required String subject,
    required String category,
    required String priority,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    
    // Add new mock ticket
    _tickets.insert(0, {
      "id": "TCKT-010",
      "subject": subject,
      "category": category,
      "status": "Open",
      "lastUpdated": "Today"
    });

    _isLoading = false;
    notifyListeners();
  }

  // Search / Filter Tickets
  void searchTickets(String query) {
    if (query.isEmpty) {
      fetchUserTickets();
      return;
    }
    
    _tickets = _tickets.where((ticket) {
      return ticket['subject'].toLowerCase().contains(query.toLowerCase()) ||
             ticket['id'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    
    notifyListeners();
  }

  // Fetch Ticket Details
  Future<void> fetchTicketDetails(String ticketId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    
    // Mock details
    _selectedTicket = {
      "id": ticketId,
      "subject": "Bug Report",
      "category": "Bug",
      "status": "OPEN",
      "priority": "MEDIUM",
      "createdDate": "May 6, 2026",
      "raisedBy": "Swiss",
      "assignedAgent": "Unassigned"
    };

    // Also fetch initial chats for this ticket
    await fetchTicketMessages(ticketId);

    _isLoading = false;
    notifyListeners();
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
        "text": "Hello! I'm sorry to hear that. Could you please provide more details?",
        "isMe": false, // Support/Admin message
        "time": "09:05 PM",
      },
      {
        "text": "It seems like messages from the last hour aren't appearing on my desktop app.",
        "isMe": true,
        "time": "09:06 PM",
      },
      {
        "text": "Thank you for the info. We are looking into our sync servers. Please hold on.",
        "isMe": false,
        "time": "09:10 PM",
      },
    ];
    notifyListeners();
  }

  // Send Message to Admin
  Future<void> sendMessageToAdmin(String text) async {
    // Immediate local update for UI responsiveness
    _adminMessages.add({
      "text": text,
      "isMe": true,
      "time": "Just now",
    });
    notifyListeners();

    // Simulate network sync
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Optional: Simulate admin reply
    await Future.delayed(const Duration(seconds: 2));
    _adminMessages.add({
      "text": "We have received your message. An agent will be with you shortly.",
      "isMe": false,
      "time": "Just now",
    });
    notifyListeners();
  }
}
