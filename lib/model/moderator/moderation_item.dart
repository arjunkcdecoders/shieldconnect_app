import 'sender_details.dart';
import 'moderator_details.dart';

class ModerationItem {
  final String id;
  final SenderDetails? senderId;
  final String messageType; // text, image, video, audio, etc.
  final String? content;
  final String? fileUrl;
  final String moderationStatus; // Moderation, Approved, Blocked, Escalate
  final String? moderatedBy;
  final String createdAt;
  final String updatedAt;
  
  // Profile Update fields
  final bool isProfileUpdate;
  final String? profileType; // user, group
  final String? pendingName;
  final String? pendingBio;
  final String? pendingAvatar;

  // Moderator review details
  final ModeratorDetails? moderatorDetails;

  ModerationItem({
    required this.id,
    this.senderId,
    required this.messageType,
    this.content,
    this.fileUrl,
    required this.moderationStatus,
    this.moderatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isProfileUpdate = false,
    this.profileType,
    this.pendingName,
    this.pendingBio,
    this.pendingAvatar,
    this.moderatorDetails,
  });

  factory ModerationItem.fromJson(Map<String, dynamic> json) {
    return ModerationItem(
      id: json['_id'] ?? '',
      senderId: json['sender_id'] != null ? SenderDetails.fromJson(json['sender_id']) : null,
      messageType: json['message_type'] ?? 'text',
      content: json['content'],
      fileUrl: json['file_url'],
      moderationStatus: json['moderation_status'] ?? 'Pending',
      moderatedBy: json['moderated_by'],
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      updatedAt: json['updated_at'] ?? json['updatedAt'] ?? '',
      isProfileUpdate: json['is_profile_update'] ?? false,
      profileType: json['profile_type'],
      pendingName: json['pending_name'],
      pendingBio: json['pending_bio'],
      pendingAvatar: json['pending_avatar'],
      moderatorDetails: json['moderator_details'] != null
          ? ModeratorDetails.fromJson(json['moderator_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender_id': senderId?.toJson(),
      'message_type': messageType,
      'content': content,
      'file_url': fileUrl,
      'moderation_status': moderationStatus,
      'moderated_by': moderatedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_profile_update': isProfileUpdate,
      'profile_type': profileType,
      'pending_name': pendingName,
      'pending_bio': pendingBio,
      'pending_avatar': pendingAvatar,
      'moderator_details': moderatorDetails?.toJson(),
    };
  }
}
