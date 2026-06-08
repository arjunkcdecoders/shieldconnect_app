class ModerationStatsResponse {
  final bool success;
  final ModerationStats? data;
  final String? message;

  ModerationStatsResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ModerationStatsResponse.fromJson(Map<String, dynamic> json) {
    return ModerationStatsResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? ModerationStats.fromJson(json['data']) : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
      'message': message,
    };
  }
}

class ModerationStats {
  final int pending;
  final int reviewedToday;
  final int escalations;
  final int usersCount;

  ModerationStats({
    required this.pending,
    required this.reviewedToday,
    required this.escalations,
    required this.usersCount,
  });

  factory ModerationStats.fromJson(Map<String, dynamic> json) {
    return ModerationStats(
      pending: json['pending'] ?? 0,
      reviewedToday: json['reviewedToday'] ?? 0,
      escalations: json['escalations'] ?? 0,
      usersCount: json['usersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending': pending,
      'reviewedToday': reviewedToday,
      'escalations': escalations,
      'usersCount': usersCount,
    };
  }
}
