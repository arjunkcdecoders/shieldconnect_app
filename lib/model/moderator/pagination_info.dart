class PaginationInfo {
  final int page;
  final int limit;
  final int totalPages;
  final int totalRecords;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.totalRecords,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['total_pages'] ?? 1,
      totalRecords: json['total_records'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total_pages': totalPages,
      'total_records': totalRecords,
    };
  }
}
