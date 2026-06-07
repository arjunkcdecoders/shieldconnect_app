import 'settings_model.dart';
import 'friend_model.dart';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? password;
  final String? role;
  final String? approvalStatus;
  final String? avatar;
  final String? phone;
  final String? bio;
  final bool? isVerified;
  final DateTime? lastLogin;
  final bool? isOnline;
  final DateTime? lastSeen;
  final String? moderatorId;
  final String? statusPrivacy;
  final List<String>? statusPrivacyList;
  final List<String>? archivedChats;
  final List<String>? favoriteChats;
  final bool? showLastSeen;
  final bool? showProfilePic;
  final bool? showBio;
  final bool? showReadReceipts;
  final bool? showTypingIndicator;
  final String? chatWallpaper;
  final String? statusReason;
  final String? resetPasswordOTP;
  final DateTime? resetPasswordExpires;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isModerator;
  final String? region;
  
  // Fields found in API responses
  final String? token;
  final FriendModel? relationship;
  final bool? hasMessages;
  final List<dynamic>? groupsInCommon;
  final List<dynamic>? sharedMedia;
  final SettingsModel? settings;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.password,
    this.role,
    this.approvalStatus,
    this.avatar,
    this.phone,
    this.bio,
    this.isVerified,
    this.lastLogin,
    this.isOnline,
    this.lastSeen,
    this.moderatorId,
    this.statusPrivacy,
    this.statusPrivacyList,
    this.archivedChats,
    this.favoriteChats,
    this.showLastSeen,
    this.showProfilePic,
    this.showBio,
    this.showReadReceipts,
    this.showTypingIndicator,
    this.chatWallpaper,
    this.statusReason,
    this.resetPasswordOTP,
    this.resetPasswordExpires,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.token,
    this.relationship,
    this.hasMessages,
    this.groupsInCommon,
    this.sharedMedia,
    this.settings,
    this.isModerator,
    this.region,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      role: json['role'] as String?,
      approvalStatus: json['approval_status'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool?,
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login'] as String) : null,
      isOnline: json['is_online'] as bool?,
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'] as String) : null,
      moderatorId: json['moderator_id'] as String?,
      statusPrivacy: json['status_privacy'] as String?,
      statusPrivacyList: (json['status_privacy_list'] as List<dynamic>?)?.map((e) => e as String).toList(),
      archivedChats: (json['archived_chats'] as List<dynamic>?)?.map((e) => e as String).toList(),
      favoriteChats: (json['favorite_chats'] as List<dynamic>?)?.map((e) => e as String).toList(),
      showLastSeen: json['show_last_seen'] as bool?,
      showProfilePic: json['show_profile_pic'] as bool?,
      showBio: json['show_bio'] as bool?,
      showReadReceipts: json['show_read_receipts'] as bool?,
      showTypingIndicator: json['show_typing_indicator'] as bool?,
      chatWallpaper: json['chat_wallpaper'] as String?,
      statusReason: json['status_reason'] as String?,
      resetPasswordOTP: json['resetPasswordOTP'] as String?,
      resetPasswordExpires: json['resetPasswordExpires'] != null ? DateTime.tryParse(json['resetPasswordExpires'] as String) : null,
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
      token: json['token'] as String?,
      relationship: json['relationship'] != null ? FriendModel.fromJson(json['relationship'] as Map<String, dynamic>) : null,
      hasMessages: json['has_messages'] as bool?,
      groupsInCommon: json['groups_in_common'] as List<dynamic>?,
      sharedMedia: json['shared_media'] as List<dynamic>?,
      settings: json['settings'] != null ? SettingsModel.fromJson(json['settings'] as Map<String, dynamic>) : null,
      isModerator: json['is_moderator'] as bool? ?? json['isModerator'] as bool?,
      region: json['region'] is Map
          ? (json['region']['name'] as String? ?? json['region']['_id'] as String?)
          : json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'approval_status': approvalStatus,
      'avatar': avatar,
      'phone': phone,
      'bio': bio,
      'is_verified': isVerified,
      'last_login': lastLogin?.toIso8601String(),
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'moderator_id': moderatorId,
      'status_privacy': statusPrivacy,
      'status_privacy_list': statusPrivacyList,
      'archived_chats': archivedChats,
      'favorite_chats': favoriteChats,
      'show_last_seen': showLastSeen,
      'show_profile_pic': showProfilePic,
      'show_bio': showBio,
      'show_read_receipts': showReadReceipts,
      'show_typing_indicator': showTypingIndicator,
      'chat_wallpaper': chatWallpaper,
      'status_reason': statusReason,
      'resetPasswordOTP': resetPasswordOTP,
      'resetPasswordExpires': resetPasswordExpires?.toIso8601String(),
      'fcmToken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'token': token,
      'relationship': relationship?.toJson(),
      'has_messages': hasMessages,
      'groups_in_common': groupsInCommon,
      'shared_media': sharedMedia,
      'settings': settings?.toJson(),
      'is_moderator': isModerator,
      'region': region,
    };
  }
}

