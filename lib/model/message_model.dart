import 'user_model.dart';
import 'group_model.dart';

class MessageModel {
  final String? id;
  final String? senderId;
  final UserModel? sender;
  final String? recipientId;
  final UserModel? recipient;
  final String? groupId;
  final GroupModel? group;
  final String? content;
  final String? messageType;
  final String? fileUrl;
  final String? fileName;
  final String? moderationStatus;
  final dynamic moderatedBy; // Mixed type in mongoose
  final List<String>? deletedFor;
  final bool? isDeletedForEveryone;
  final bool? isForwarded;
  final String? parentMessageId;
  final MessageModel? parentMessage;
  final bool? isEdited;
  final String? status;
  final DateTime? readAt;
  final List<ReadBy>? readBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MessageModel({
    this.id,
    this.senderId,
    this.sender,
    this.recipientId,
    this.recipient,
    this.groupId,
    this.group,
    this.content,
    this.messageType,
    this.fileUrl,
    this.fileName,
    this.moderationStatus,
    this.moderatedBy,
    this.deletedFor,
    this.isDeletedForEveryone,
    this.isForwarded,
    this.parentMessageId,
    this.parentMessage,
    this.isEdited,
    this.status,
    this.readAt,
    this.readBy,
    this.createdAt,
    this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      senderId: json['sender_id'] is String
          ? json['sender_id'] as String?
          : (json['sender_id'] is Map
                ? json['sender_id']['_id'] as String?
                : null),
      sender: json['sender_id'] is Map<String, dynamic>
          ? UserModel.fromJson(json['sender_id'] as Map<String, dynamic>)
          : null,
      recipientId: json['recipient_id'] is String
          ? json['recipient_id'] as String?
          : (json['recipient_id'] is Map
                ? json['recipient_id']['_id'] as String?
                : null),
      recipient: json['recipient_id'] is Map<String, dynamic>
          ? UserModel.fromJson(json['recipient_id'] as Map<String, dynamic>)
          : null,
      groupId: json['group_id'] is String
          ? json['group_id'] as String?
          : (json['group_id'] is Map
                ? json['group_id']['_id'] as String?
                : null),
      group: json['group_id'] is Map<String, dynamic>
          ? GroupModel.fromJson(json['group_id'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String?,
      messageType: json['message_type'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      moderationStatus: json['moderation_status'] as String?,
      moderatedBy: json['moderated_by'],
      deletedFor: (json['deleted_for'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isDeletedForEveryone: json['is_deleted_for_everyone'] as bool? ?? false,
      isForwarded: json['is_forwarded'] as bool? ?? false,
      parentMessageId: json['parent_message_id'] is String
          ? json['parent_message_id'] as String?
          : (json['parent_message_id'] is Map
                ? json['parent_message_id']['_id'] as String?
                : (json['parentMessageId'] as String?)),
      parentMessage: json['parent_message_id'] is Map<String, dynamic>
          ? MessageModel.fromJson(
              json['parent_message_id'] as Map<String, dynamic>,
            )
          : (json['parentMessage'] is Map<String, dynamic>
                ? MessageModel.fromJson(
                    json['parentMessage'] as Map<String, dynamic>,
                  )
                : null),
      isEdited: json['is_edited'] as bool? ?? false,
      status: json['status'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      readBy: (json['read_by'] as List<dynamic>?)
          ?.map((e) => ReadBy.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String)
                : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : (json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'] as String)
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender_id': sender?.toJson() ?? senderId,
      'recipient_id': recipient?.toJson() ?? recipientId,
      'group_id': group?.toJson() ?? groupId,
      'content': content,
      'message_type': messageType,
      'file_url': fileUrl,
      'file_name': fileName,
      'moderation_status': moderationStatus,
      'moderated_by': moderatedBy,
      'deleted_for': deletedFor,
      'is_deleted_for_everyone': isDeletedForEveryone,
      'is_forwarded': isForwarded,
      'parent_message_id': parentMessage?.toJson() ?? parentMessageId,
      'is_edited': isEdited,
      'status': status,
      'read_at': readAt?.toIso8601String(),
      'read_by': readBy?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class ReadBy {
  final String? userId;
  final UserModel? user;
  final DateTime? readAt;

  ReadBy({this.userId, this.user, this.readAt});

  factory ReadBy.fromJson(Map<String, dynamic> json) {
    return ReadBy(
      userId: json['user_id'] is String
          ? json['user_id'] as String?
          : (json['user_id'] is Map ? json['user_id']['_id'] as String? : null),
      user: json['user_id'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user_id'] as Map<String, dynamic>)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user?.toJson() ?? userId,
      'read_at': readAt?.toIso8601String(),
    };
  }
}
