import 'daily_score.dart';

class DhsiTrend {
  final int thisWeekScore;
  final int lastWeekScore;
  final int diff;
  final List<DailyScore> dailyScores;

  DhsiTrend({
    required this.thisWeekScore,
    required this.lastWeekScore,
    required this.diff,
    required this.dailyScores,
  });

  factory DhsiTrend.fromJson(Map<String, dynamic> json) {
    var dailyScoresList = json['dailyScores'] as List?;
    return DhsiTrend(
      thisWeekScore: json['thisWeekScore'] ?? 0,
      lastWeekScore: json['lastWeekScore'] ?? 0,
      diff: json['diff'] ?? 0,
      dailyScores: dailyScoresList != null
          ? dailyScoresList.map((x) => DailyScore.fromJson(x)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thisWeekScore': thisWeekScore,
      'lastWeekScore': lastWeekScore,
      'diff': diff,
      'dailyScores': dailyScores.map((x) => x.toJson()).toList(),
    };
  }
}
