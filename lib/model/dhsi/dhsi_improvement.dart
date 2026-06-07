class DhsiImprovement {
  final int points;
  final String text;

  DhsiImprovement({
    required this.points,
    required this.text,
  });

  factory DhsiImprovement.fromJson(Map<String, dynamic> json) {
    return DhsiImprovement(
      points: json['points'] ?? 0,
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'text': text,
    };
  }
}
