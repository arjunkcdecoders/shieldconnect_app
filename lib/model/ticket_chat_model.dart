import 'user_model.dart';

class TicketChatModel {
  final String? id;
  final String? ticketId;
  final String? adminUserId;
  final dynamic adminUser;
  final String? userId;
  final UserModel? user;
  final String? message;
  final String? fileUrl;
  final String? fileName;
  final double? fileSize;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TicketChatModel({
    this.id,
    this.ticketId,
    this.adminUserId,
    this.adminUser,
    this.userId,
    this.user,
    this.message,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketChatModel.fromJson(Map<String, dynamic> json) {
    return TicketChatModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      ticketId: json['ticketId'] as String?,
      adminUserId: json['adminUserId'] is String ? json['adminUserId'] as String? : (json['adminUserId'] is Map ? json['adminUserId']['_id'] as String? : null),
      adminUser: json['adminUserId'] is Map<String, dynamic> ? json['adminUserId'] : null,
      userId: json['userId'] is String ? json['userId'] as String? : (json['userId'] is Map ? json['userId']['_id'] as String? : null),
      user: json['userId'] is Map<String, dynamic> ? UserModel.fromJson(json['userId'] as Map<String, dynamic>) : null,
      message: json['message'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ticketId': ticketId,
      'adminUserId': adminUser ?? adminUserId,
      'userId': user?.toJson() ?? userId,
      'message': message,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
