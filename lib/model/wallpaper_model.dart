class WallpaperModel {
  final String? id;
  final String? name;
  final String? wallpaperImage;
  final String? status;
  final bool? isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WallpaperModel({
    this.id,
    this.name,
    this.wallpaperImage,
    this.status,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      wallpaperImage: json['wallpaper_image'] as String? ?? json['wallpaper_image'] as String?,
      status: json['status'] as String?,
      isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'wallpaper_image': wallpaperImage,
      'status': status,
      'isDefault': isDefault,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
