class StickerModel {
  final String? id;
  final String? name;
  final String? stickerImage;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StickerModel({
    this.id,
    this.name,
    this.stickerImage,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StickerModel.fromJson(Map<String, dynamic> json) {
    return StickerModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      stickerImage: json['sticker_image'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'sticker_image': stickerImage,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
