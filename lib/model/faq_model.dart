class FaqModel {
  final String? id;
  final String? question;
  final String? answer;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FaqModel({
    this.id,
    this.question,
    this.answer,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
      'answer': answer,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
