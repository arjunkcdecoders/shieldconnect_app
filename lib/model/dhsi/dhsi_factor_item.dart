class DhsiFactorItem {
  final String level;
  final String description;
  final int progressBarValue;

  DhsiFactorItem({
    required this.level,
    required this.description,
    required this.progressBarValue,
  });

  factory DhsiFactorItem.fromJson(Map<String, dynamic> json) {
    return DhsiFactorItem(
      level: json['level'] ?? '',
      description: json['description'] ?? '',
      progressBarValue: json['progressBarValue'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'description': description,
      'progressBarValue': progressBarValue,
    };
  }
}
