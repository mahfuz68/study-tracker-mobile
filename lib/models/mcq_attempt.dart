import 'question.dart';

class McqAttempt {
  final int id;
  final String userId;
  final String? subject;
  final String? topic;
  final int total;
  final int correct;
  final int wrong;
  final int skipped;
  final double score;
  final double cutMark;
  final bool passed;
  final String createdAt;
  final List<McqAnswer>? answers;

  McqAttempt({
    required this.id,
    required this.userId,
    this.subject,
    this.topic,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.score,
    required this.cutMark,
    required this.passed,
    required this.createdAt,
    this.answers,
  });

  factory McqAttempt.fromJson(Map<String, dynamic> json) {
    return McqAttempt(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      subject: json['subject'],
      topic: json['topic'],
      total: json['total'] ?? 0,
      correct: json['correct'] ?? 0,
      wrong: json['wrong'] ?? 0,
      skipped: json['skipped'] ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      cutMark: (json['cutMark'] ?? 0).toDouble(),
      passed: json['passed'] ?? false,
      createdAt: json['createdAt'] ?? '',
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => McqAnswer.fromJson(a))
          .toList(),
    );
  }
}

class McqAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final int? chosen;
  final bool? isCorrect;
  final Question? question;

  McqAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.chosen,
    this.isCorrect,
    this.question,
  });

  factory McqAnswer.fromJson(Map<String, dynamic> json) {
    return McqAnswer(
      id: json['id'] ?? 0,
      attemptId: json['attemptId'] ?? 0,
      questionId: json['questionId'] ?? 0,
      chosen: json['chosen'],
      isCorrect: json['isCorrect'],
      question: json['question'] != null
          ? Question.fromJson(json['question'])
          : null,
    );
  }
}
