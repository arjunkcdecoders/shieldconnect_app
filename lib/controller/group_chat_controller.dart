import 'package:flutter/material.dart';

class GroupChatController extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  Map<String, dynamic>? _groupDetails;
  Map<String, dynamic>? get groupDetails => _groupDetails;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController messageController = TextEditingController();

  Future<void> init(String groupId) async {
    _isLoading = true;
    notifyListeners();

    await fetchGroupDetails(groupId);
    await fetchChatHistory(groupId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGroupDetails(String groupId) async {
    // Mock fetching group detailed info (Group Info Screen)
    await Future.delayed(const Duration(milliseconds: 400));
    _groupDetails = {
      "name": "Project Shield",
      "description": "Collaborative space for the Project Shield design and development team. 🛡️",
      "avatar": "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
      "admin": "You",
      "memberCount": 5,
      "onlineCount": 3,
      "members": [
        {"name": "You", "role": "Admin", "avatar": "assets/images/user_avatar.png"},
        {"name": "Alice Johnson", "role": "Member", "avatar": "assets/images/obchild1.png"},
        {"name": "Bob Wilson", "role": "Member", "avatar": "assets/images/obchild2.png"},
        {"name": "Charlie Day", "role": "Member", "avatar": "assets/images/maisie_avatar.png"},
        {"name": "Dave Smith", "role": "Member", "avatar": "assets/images/obchild1.png"},
      ],
      "medias": [
        "https://images.unsplash.com/photo-1545241047-6083a3684587?w=200",
        "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200",
        "https://images.unsplash.com/photo-1518770660439-4636190af475?w=200",
      ],
    };
    notifyListeners();
  }

  Future<void> addMember(String userId) async {
    // Mock add member
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> removeMember(String userId) async {
    // Mock remove member
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> leaveGroup(String groupId) async {
    // Mock leave group
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> fetchChatHistory(String groupId) async {
    // Mock fetching group chat history
    await Future.delayed(const Duration(milliseconds: 600));
    _messages = [
      {
        "sender": "Alice Johnson",
        "text": "Did everyone see the new update?",
        "time": "09:45 am",
        "isOutgoing": false,
        "type": "text",
        "avatar": "assets/images/obchild1.png"
      },
      {
        "sender": "Bob Wilson",
        "text": "Yes! Looks great.",
        "time": "09:47 am",
        "isOutgoing": false,
        "type": "text",
        "avatar": "assets/images/obchild2.png"
      },
      {
        "sender": "You",
        "text": "I'm working on the next phase now.",
        "time": "09:50 am",
        "isOutgoing": true,
        "type": "text"
      },
      {
        "sender": "System",
        "title": "Group Rules Updated",
        "subtitle": "Please check the new guidelines in group info.",
        "time": "10:00 am",
        "type": "status",
        "asset": "assets/images/approved.png",
        "isOutgoing": false
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
      "text": "Shared a file",
      "time": "Now",
      "isOutgoing": true,
      "type": "image",
      "url": "https://images.unsplash.com/photo-1545241047-6083a3684587?w=400"
    };
    _messages.add(mediaMessage);
    notifyListeners();
  }

  Future<void> recordAudio() async {
    // Mock recording audio
    await Future.delayed(const Duration(seconds: 1));
    final audioMessage = {
      "sender": "You",
      "text": "Voice Note",
      "time": "Now",
      "isOutgoing": true,
      "type": "audio",
      "duration": "0:12"
    };
    _messages.add(audioMessage);
    notifyListeners();
  }

  Future<void> sendLocation() async {
    // Mock sending location
    await Future.delayed(const Duration(milliseconds: 500));
    final locationMessage = {
      "sender": "You",
      "text": "Current Location",
      "time": "Now",
      "isOutgoing": true,
      "type": "location",
      "lat": 34.0522,
      "lng": -118.2437
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

  Future<void> forwardMessage(int index, List<String> targetGroupIds) async {
    // Mock forwarding
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> deleteChat(String groupId) async {
    // Mock delete
    await Future.delayed(const Duration(milliseconds: 400));
    _messages.clear();
    notifyListeners();
  }

  Future<void> reportGroup(String groupId, String reason) async {
    // Mock report
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Map<String, dynamic> getMessageInfo(int index) {
    if (index >= 0 && index < _messages.length) {
      return {
        "sentAt": "09:50 AM",
        "deliveredTo": ["Alice", "Bob", "Charlie"],
        "readBy": ["Alice", "Bob"],
      };
    }
    return {};
  }

  List<String> getMockEmojis() {
    return ["🔥", "🚀", "💡", "✅", "🎉", "👍", "🙌", "💯", "🎯", "✨", "🎈", "🌟"];
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
