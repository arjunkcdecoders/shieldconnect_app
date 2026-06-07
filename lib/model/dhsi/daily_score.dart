class DailyScore {
  final String day;
  final int score;
  final bool isToday;

  DailyScore({
    required this.day,
    required this.score,
    required this.isToday,
  });

  factory DailyScore.fromJson(Map<String, dynamic> json) {
    return DailyScore(
      day: json['day'] ?? '',
      score: json['score'] ?? 0,
      isToday: json['isToday'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'score': score,
      'isToday': isToday,
    };
  }
}
