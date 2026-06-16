import 'topic.dart';

class StudyDay {
  final int id;
  final int dayNumber;
  final String? label;
  final String? date;
  final List<Topic> topics;

  StudyDay({
    required this.id,
    required this.dayNumber,
    this.label,
    this.date,
    this.topics = const [],
  });

  factory StudyDay.fromJson(Map<String, dynamic> json) {
    return StudyDay(
      id: json['id'] ?? 0,
      dayNumber: json['dayNumber'] ?? 0,
      label: json['label'],
      date: json['date'],
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => Topic.fromJson(t))
              .toList() ??
          [],
    );
  }
}
