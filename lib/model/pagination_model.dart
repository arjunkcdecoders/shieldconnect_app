class PaginationModel {
  final int? page;
  final int? limit;
  final int? totalPages;
  final int? totalRecords;

  PaginationModel({
    this.page,
    this.limit,
    this.totalPages,
    this.totalRecords,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      totalPages: json['total_pages'] as int?,
      totalRecords: json['total_records'] as int?,
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
