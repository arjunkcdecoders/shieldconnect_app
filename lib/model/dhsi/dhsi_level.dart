class DhsiLevel {
  final int currentLevel;
  final String currentLevelName;
  final String nextLevelName;
  final int pointsToNext;

  DhsiLevel({
    required this.currentLevel,
    required this.currentLevelName,
    required this.nextLevelName,
    required this.pointsToNext,
  });

  factory DhsiLevel.fromJson(Map<String, dynamic> json) {
    return DhsiLevel(
      currentLevel: json['currentLevel'] ?? 0,
      currentLevelName: json['currentLevelName'] ?? '',
      nextLevelName: json['nextLevelName'] ?? '',
      pointsToNext: json['pointsToNext'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'currentLevelName': currentLevelName,
      'nextLevelName': nextLevelName,
      'pointsToNext': pointsToNext,
    };
  }
}
