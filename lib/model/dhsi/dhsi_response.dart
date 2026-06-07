import 'dhsi_data.dart';

class DhsiResponse {
  final bool success;
  final DhsiData? data;

  DhsiResponse({
    required this.success,
    this.data,
  });

  factory DhsiResponse.fromJson(Map<String, dynamic> json) {
    return DhsiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? DhsiData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}
