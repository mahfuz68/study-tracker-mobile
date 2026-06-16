class Progress {
  final int id;
  final String userId;
  final int topicId;
  final String date;
  final bool isComplete;
  final bool hasExam;
  final int? examMark;
  final String updatedAt;

  Progress({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.date,
    required this.isComplete,
    required this.hasExam,
    this.examMark,
    required this.updatedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      topicId: json['topicId'] ?? 0,
      date: json['date'] ?? '',
      isComplete: json['isComplete'] ?? false,
      hasExam: json['hasExam'] ?? false,
      examMark: json['examMark'],
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'date': date,
        'isComplete': isComplete,
        'hasExam': hasExam,
        'examMark': examMark,
      };
}
