import 'user_model.dart';
import 'message_model.dart';
import 'friend_model.dart';

class ConversationModel {
  final ConversationEntity? conversation;
  final MessageModel? lastMessage;
  final int? unreadCount;
  final bool? isFavorite;
  final bool? isConnected;
  final FriendModel? relationship;
  final String? requestedBy;
  final bool? hasLeft;
  final DateTime? leftAt;
  final Map<String, dynamic>? chatParams;

  ConversationModel({
    this.conversation,
    this.lastMessage,
    this.unreadCount,
    this.isFavorite,
    this.isConnected,
    this.relationship,
    this.requestedBy,
    this.hasLeft,
    this.leftAt,
    this.chatParams,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversation: json['conversation'] != null
          ? ConversationEntity.fromJson(
              json['conversation'] as Map<String, dynamic>,
            )
          : null,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int?,
      isFavorite: json['is_favorite'] as bool?,
      isConnected: json['is_connected'] as bool?,
      relationship: json['relationship'] != null
          ? FriendModel.fromJson(json['relationship'] as Map<String, dynamic>)
          : null,
      requestedBy: json['requested_by'] as String?,
      hasLeft: json['has_left'] as bool?,
      leftAt: json['left_at'] != null
          ? DateTime.tryParse(json['left_at'] as String)
          : null,
      chatParams: json['chat_params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation': conversation?.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_favorite': isFavorite,
      'is_connected': isConnected,
      'relationship': relationship?.toJson(),
      'requested_by': requestedBy,
      'has_left': hasLeft,
      'left_at': leftAt?.toIso8601String(),
      'chat_params': chatParams,
    };
  }
}

class ConversationEntity {
  final String? id;
  final String? name;
  final String? image;
  final String? bio;
  final bool? isOnline;
  final DateTime? lastSeen;
  final bool? showLastSeen;
  final bool? showProfilePic;
  final bool? showBio;
  final bool? showReadReceipts;
  final bool? showTypingIndicator;
  final String? type; // 'user' or 'group'

  ConversationEntity({
    this.id,
    this.name,
    this.image,
    this.bio,
    this.isOnline,
    this.lastSeen,
    this.showLastSeen,
    this.showProfilePic,
    this.showBio,
    this.showReadReceipts,
    this.showTypingIndicator,
    this.type,
  });

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    return ConversationEntity(
      id: json['id'] as String? ?? json['_id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['is_online'] as bool?,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
      showLastSeen: json['show_last_seen'] as bool?,
      showProfilePic: json['show_profile_pic'] as bool?,
      showBio: json['show_bio'] as bool?,
      showReadReceipts: json['show_read_receipts'] as bool?,
      showTypingIndicator: json['show_typing_indicator'] as bool?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'bio': bio,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'show_last_seen': showLastSeen,
      'show_profile_pic': showProfilePic,
      'show_bio': showBio,
      'show_read_receipts': showReadReceipts,
      'show_typing_indicator': showTypingIndicator,
      'type': type,
    };
  }
}
