import 'pagination_info.dart';
import 'moderation_item.dart';

class ModerationHistoryResponse {
  final bool success;
  final int count;
  final String status;
  final PaginationInfo? pagination;
  final List<ModerationItem> data;

  ModerationHistoryResponse({
    required this.success,
    required this.count,
    required this.status,
    this.pagination,
    required this.data,
  });

  factory ModerationHistoryResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List?;
    List<ModerationItem> itemsList = list != null
        ? list.map((i) => ModerationItem.fromJson(i)).toList()
        : [];

    return ModerationHistoryResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      status: json['status'] ?? 'All',
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
      data: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'status': status,
      'pagination': pagination?.toJson(),
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
