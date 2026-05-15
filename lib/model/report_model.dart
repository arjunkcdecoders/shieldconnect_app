import 'user_model.dart';

class ReportModel {
  final String? id;
  final String? reporterId;
  final UserModel? reporter;
  final String? reportedUserId;
  final UserModel? reportedUser;
  final String? reason;
  final String? description;
  final String? status;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReportModel({
    this.id,
    this.reporterId,
    this.reporter,
    this.reportedUserId,
    this.reportedUser,
    this.reason,
    this.description,
    this.status,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      reporterId: json['reporterId'] is String ? json['reporterId'] as String? : (json['reporterId'] is Map ? json['reporterId']['_id'] as String? : (json['reporter_id'] is String ? json['reporter_id'] as String? : null)),
      reporter: json['reporterId'] is Map<String, dynamic> ? UserModel.fromJson(json['reporterId'] as Map<String, dynamic>) : (json['reporter_id'] is Map<String, dynamic> ? UserModel.fromJson(json['reporter_id'] as Map<String, dynamic>) : null),
      reportedUserId: json['reportedUserId'] is String ? json['reportedUserId'] as String? : (json['reportedUserId'] is Map ? json['reportedUserId']['_id'] as String? : (json['reported_user_id'] is String ? json['reported_user_id'] as String? : null)),
      reportedUser: json['reportedUserId'] is Map<String, dynamic> ? UserModel.fromJson(json['reportedUserId'] as Map<String, dynamic>) : (json['reported_user_id'] is Map<String, dynamic> ? UserModel.fromJson(json['reported_user_id'] as Map<String, dynamic>) : null),
      reason: json['reason'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reporterId': reporter?.toJson() ?? reporterId,
      'reportedUserId': reportedUser?.toJson() ?? reportedUserId,
      'reason': reason,
      'description': description,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
