class AnnouncementModel {
  final String? id;
  final String? title;
  final String? content;
  final String? media;
  final String? mediaType;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AnnouncementModel({
    this.id,
    this.title,
    this.content,
    this.media,
    this.mediaType,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      media: json['media'] as String?,
      mediaType: json['mediaType'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'media': media,
      'mediaType': mediaType,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
