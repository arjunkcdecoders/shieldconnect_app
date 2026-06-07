class DhsiLevelRange {
  final int level;
  final String name;
  final int minXp;
  final int? maxXp;

  DhsiLevelRange({
    required this.level,
    required this.name,
    required this.minXp,
    this.maxXp,
  });

  factory DhsiLevelRange.fromJson(Map<String, dynamic> json) {
    return DhsiLevelRange(
      level: json['level'] ?? 0,
      name: json['name'] ?? '',
      minXp: json['minXp'] ?? 0,
      maxXp: json['maxXp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'name': name,
      'minXp': minXp,
      'maxXp': maxXp,
    };
  }
}
