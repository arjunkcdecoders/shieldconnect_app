import 'dhsi_user.dart';
import 'dhsi_level.dart';
import 'streak_day.dart';
import 'dhsi_trend.dart';
import 'dhsi_factors.dart';
import 'dhsi_improvement.dart';
import 'dhsi_level_range.dart';

class DhsiData {
  final int score;
  final String status;
  final int xp;
  final DhsiUser? user;
  final DhsiLevel? level;
  final int streak;
  final List<StreakDay> streakDays;
  final DhsiTrend? trend;
  final DhsiFactors? factors;
  final List<DhsiImprovement> improvements;
  final List<DhsiLevelRange> allLevels;

  DhsiData({
    required this.score,
    required this.status,
    required this.xp,
    this.user,
    this.level,
    required this.streak,
    required this.streakDays,
    this.trend,
    this.factors,
    required this.improvements,
    required this.allLevels,
  });

  factory DhsiData.fromJson(Map<String, dynamic> json) {
    var streakDaysList = json['streakDays'] as List?;
    var improvementsList = json['improvements'] as List?;
    var allLevelsList = json['allLevels'] as List?;

    return DhsiData(
      score: json['score'] ?? 0,
      status: json['status'] ?? '',
      xp: json['xp'] ?? 0,
      user: json['user'] != null ? DhsiUser.fromJson(json['user']) : null,
      level: json['level'] != null ? DhsiLevel.fromJson(json['level']) : null,
      streak: json['streak'] ?? 0,
      streakDays: streakDaysList != null
          ? streakDaysList.map((x) => StreakDay.fromJson(x)).toList()
          : [],
      trend: json['trend'] != null ? DhsiTrend.fromJson(json['trend']) : null,
      factors: json['factors'] != null ? DhsiFactors.fromJson(json['factors']) : null,
      improvements: improvementsList != null
          ? improvementsList.map((x) => DhsiImprovement.fromJson(x)).toList()
          : [],
      allLevels: allLevelsList != null
          ? allLevelsList.map((x) => DhsiLevelRange.fromJson(x)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status,
      'xp': xp,
      'user': user?.toJson(),
      'level': level?.toJson(),
      'streak': streak,
      'streakDays': streakDays.map((x) => x.toJson()).toList(),
      'trend': trend?.toJson(),
      'factors': factors?.toJson(),
      'improvements': improvements.map((x) => x.toJson()).toList(),
      'allLevels': allLevels.map((x) => x.toJson()).toList(),
    };
  }
}
