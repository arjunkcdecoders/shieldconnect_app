class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? count;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.count,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromData) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromData(json['data']) : null,
      count: json['count'] as int?,
    );
  }
}
