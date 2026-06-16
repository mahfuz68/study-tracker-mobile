class StudyReport {
  final String userName;
  final String generatedAt;
  final double completionRate;
  final int completedTopics;
  final int totalTopics;
  final int studyTimeMin;
  final double avgExamMark;
  final List<ReportDay> days;

  StudyReport({
    required this.userName,
    required this.generatedAt,
    required this.completionRate,
    required this.completedTopics,
    required this.totalTopics,
    required this.studyTimeMin,
    required this.avgExamMark,
    this.days = const [],
  });

  factory StudyReport.fromJson(Map<String, dynamic> json) {
    return StudyReport(
      userName: json['userName'] ?? '',
      generatedAt: json['generatedAt'] ?? '',
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      completedTopics: json['completedTopics'] ?? 0,
      totalTopics: json['totalTopics'] ?? 0,
      studyTimeMin: json['studyTimeMin'] ?? 0,
      avgExamMark: (json['avgExamMark'] ?? 0).toDouble(),
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => ReportDay.fromJson(d))
              .toList() ??
          [],
    );
  }
}

class ReportDay {
  final int dayNumber;
  final int completedTopics;
  final int totalTopics;
  final List<ReportTopic> topics;

  ReportDay({
    required this.dayNumber,
    required this.completedTopics,
    required this.totalTopics,
    this.topics = const [],
  });

  factory ReportDay.fromJson(Map<String, dynamic> json) {
    return ReportDay(
      dayNumber: json['dayNumber'] ?? 0,
      completedTopics: json['completedTopics'] ?? 0,
      totalTopics: json['totalTopics'] ?? 0,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => ReportTopic.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class ReportTopic {
  final String subject;
  final String topic;
  final bool isComplete;
  final int? examMark;

  ReportTopic({
    required this.subject,
    required this.topic,
    required this.isComplete,
    this.examMark,
  });

  factory ReportTopic.fromJson(Map<String, dynamic> json) {
    return ReportTopic(
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      isComplete: json['isComplete'] ?? false,
      examMark: json['examMark'],
    );
  }
}
