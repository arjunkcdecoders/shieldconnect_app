class NotificationModel {
  final String? id;
  final String? recipientId;
  final String? type;
  final String? title;
  final String? message;
  final NotificationMetadata? metadata;
  final bool? isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotificationModel({
    this.id,
    this.recipientId,
    this.type,
    this.title,
    this.message,
    this.metadata,
    this.isRead,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      recipientId: json['recipientId'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      message: json['message'] as String?,
      metadata: json['metadata'] != null ? NotificationMetadata.fromJson(json['metadata'] as Map<String, dynamic>) : null,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'metadata': metadata?.toJson(),
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class NotificationMetadata {
  final String? ticketId;
  final String? customTicketId;

  NotificationMetadata({
    this.ticketId,
    this.customTicketId,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      ticketId: json['ticketId'] as String?,
      customTicketId: json['customTicketId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'customTicketId': customTicketId,
    };
  }
}
