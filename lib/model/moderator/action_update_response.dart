class ActionUpdateResponse {
  final bool success;
  final String message;
  final dynamic data; // Can map to a Map or List depending on whether it was a message or user update

  ActionUpdateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ActionUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ActionUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}
