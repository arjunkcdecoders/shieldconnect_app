class StreakDay {
  final String day;
  final bool checked;
  final bool isToday;

  StreakDay({
    required this.day,
    required this.checked,
    required this.isToday,
  });

  factory StreakDay.fromJson(Map<String, dynamic> json) {
    return StreakDay(
      day: json['day'] ?? '',
      checked: json['checked'] ?? false,
      isToday: json['isToday'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'checked': checked,
      'isToday': isToday,
    };
  }
}
