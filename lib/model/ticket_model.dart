import 'user_model.dart';

class TicketModel {
  final String? id;
  final String? ticketId;
  final String? userId;
  final UserModel? user;
  final String? subject;
  final String? category;
  final String? priority;
  final String? status;
  final String? assignedTo;
  final dynamic assignedAdmin; // Could be AdminUserModel if it existed, but using dynamic for now
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TicketModel({
    this.id,
    this.ticketId,
    this.userId,
    this.user,
    this.subject,
    this.category,
    this.priority,
    this.status,
    this.assignedTo,
    this.assignedAdmin,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      ticketId: json['ticketId'] as String?,
      userId: json['userId'] is String ? json['userId'] as String? : (json['userId'] is Map ? json['userId']['_id'] as String? : (json['user_id'] is String ? json['user_id'] as String? : null)),
      user: json['userId'] is Map<String, dynamic> ? UserModel.fromJson(json['userId'] as Map<String, dynamic>) : (json['user_id'] is Map<String, dynamic> ? UserModel.fromJson(json['user_id'] as Map<String, dynamic>) : null),
      subject: json['subject'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      assignedTo: json['assignedTo'] is String ? json['assignedTo'] as String? : (json['assignedTo'] is Map ? json['assignedTo']['_id'] as String? : null),
      assignedAdmin: json['assignedTo'] is Map<String, dynamic> ? json['assignedTo'] : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ticketId': ticketId,
      'userId': user?.toJson() ?? userId,
      'subject': subject,
      'category': category,
      'priority': priority,
      'status': status,
      'assignedTo': assignedAdmin ?? assignedTo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
