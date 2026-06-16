class Topic {
  final int id;
  final int studyDayId;
  final String subject;
  final String topic;
  final int durationMin;
  final int order;

  Topic({
    required this.id,
    required this.studyDayId,
    required this.subject,
    required this.topic,
    required this.durationMin,
    required this.order,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] ?? 0,
      studyDayId: json['studyDayId'] ?? 0,
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      durationMin: json['durationMin'] ?? 0,
      order: json['order'] ?? 0,
    );
  }
}
