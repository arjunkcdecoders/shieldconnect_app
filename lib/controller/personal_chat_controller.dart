import 'package:flutter/material.dart';

class PersonalChatController extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  Map<String, dynamic>? _personalDetails;
  Map<String, dynamic>? get personalDetails => _personalDetails;

  Map<String, dynamic>? _headerDetails;
  Map<String, dynamic>? get headerDetails => _headerDetails;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController messageController = TextEditingController();

  Future<void> init(String chatId, {bool isGroup = false}) async {
    _isLoading = true;
    notifyListeners();

    await fetchHeaderDetails(chatId, isGroup: isGroup);
    await fetchChatHistory(chatId);
    if (!isGroup) {
      await fetchPersonalChatDetails(chatId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPersonalChatDetails(String userId) async {
    // Mock fetching personal chat details (Contact Info)
    await Future.delayed(const Duration(milliseconds: 400));
    _personalDetails = {
      "name": "Maisie Williams",
      "bio": "I'm a designer and adventurer. Let's create something amazing! ✨",
      "phoneNumber": "+1 234 567 890",
      "avatar": "assets/images/maisie_avatar.png",
      "medias": [
        "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
        "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
        "https://images.unsplash.com/photo-1518770660439-4636190af475?w=200",
      ],
      "groupsInCommon": [
        {"name": "Design Team", "members": 12},
        {"name": "Project Shield", "members": 5},
      ],
    };
    notifyListeners();
  }

  Future<void> fetchHeaderDetails(String chatId, {bool isGroup = false}) async {
    // Mock fetching header details
    await Future.delayed(const Duration(milliseconds: 300));
    if (isGroup) {
      _headerDetails = {
        "name": "Design Team",
        "members": "Alice, Bob, Charlie, You",
        "avatar": "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
        "isGroup": true,
      };
    } else {
      _headerDetails = {
        "name": "Maisie Williams",
        "status": "Online",
        "avatar": "assets/images/maisie_avatar.png",
        "isGroup": false,
      };
    }
    notifyListeners();
  }

  Future<void> fetchChatHistory(String chatId) async {
    // Mock fetching chat history
    await Future.delayed(const Duration(milliseconds: 500));
    _messages = [
      {
        "sender": "Alice",
        "text": "Hello everyone!",
        "time": "10:00 am",
        "isOutgoing": false,
        "type": "text"
      },
      {
        "sender": "You",
        "text": "Hey Alice!",
        "time": "10:02 am",
        "isOutgoing": true,
        "type": "text"
      },
      {
        "sender": "Bob",
        "text": "Check this out!",
        "time": "10:05 am",
        "isOutgoing": false,
        "type": "text"
      },
    ];
    notifyListeners();
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    final newMessage = {
      "sender": "You",
      "text": messageController.text.trim(),
      "time": "Now",
      "isOutgoing": true,
      "type": "text"
    };

    _messages.add(newMessage);
    messageController.clear();
    notifyListeners();
  }

  Future<void> pickMedia() async {
    // Mock picking media
    await Future.delayed(const Duration(milliseconds: 400));
    final mediaMessage = {
      "sender": "You",
      "text": "Sent an image",
      "time": "Now",
      "isOutgoing": true,
      "type": "image",
      "url": "assets/images/mock_image.png"
    };
    _messages.add(mediaMessage);
    notifyListeners();
  }

  Future<void> recordAudio() async {
    // Mock recording audio
    await Future.delayed(const Duration(seconds: 1));
    final audioMessage = {
      "sender": "You",
      "text": "Voice Message",
      "time": "Now",
      "isOutgoing": true,
      "type": "audio",
      "duration": "0:05"
    };
    _messages.add(audioMessage);
    notifyListeners();
  }

  Future<void> sendLocation() async {
    // Mock sending location
    await Future.delayed(const Duration(milliseconds: 500));
    final locationMessage = {
      "sender": "You",
      "text": "Shared a location",
      "time": "Now",
      "isOutgoing": true,
      "type": "location",
      "lat": 0.0,
      "lng": 0.0
    };
    _messages.add(locationMessage);
    notifyListeners();
  }

  void editMessage(int index, String newText) {
    if (index >= 0 && index < _messages.length) {
      _messages[index]["text"] = newText;
      _messages[index]["isEdited"] = true;
      notifyListeners();
    }
  }

  void deleteForMe(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }

  void deleteForEveryone(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages[index]["text"] = "This message was deleted";
      _messages[index]["isDeleted"] = true;
      _messages[index]["type"] = "text";
      notifyListeners();
    }
  }

  void replyToMessage(int index, String replyText) {
    if (index >= 0 && index < _messages.length) {
      final replyMessage = {
        "sender": "You",
        "text": replyText,
        "time": "Now",
        "isOutgoing": true,
        "type": "text",
        "replyTo": _messages[index]["text"],
        "replyToSender": _messages[index]["sender"],
      };
      _messages.add(replyMessage);
      notifyListeners();
    }
  }

  Future<void> forwardMessage(int index, List<String> targetChatIds) async {
    // Mock forwarding
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    // Mock delete chat
    await Future.delayed(const Duration(milliseconds: 400));
    _messages.clear();
    notifyListeners();
  }

  Future<void> reportUser(String userId, String reason) async {
    // Mock report
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> blockUser(String userId) async {
    // Mock block
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Map<String, dynamic> getMessageInfo(int index) {
    if (index >= 0 && index < _messages.length) {
      return {
        "sentAt": "10:00 AM",
        "deliveredAt": "10:01 AM",
        "readAt": "10:05 AM",
      };
    }
    return {};
  }

  List<String> getMockEmojis() {
    return ["😊", "🥰", "🚀", "🔥", "🌈", "🎈", "🍕", "🎸", "🐱", "🐶", "🐻", "🐼"];
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
