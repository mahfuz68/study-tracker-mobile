import 'puzzle_question.dart';

class Puzzle {
  final String id;
  final String title;
  final String topic;
  final String status;
  final String scenarioParagraph;
  final int? timeLimit;
  final List<PuzzleExtra> extras;
  final List<PuzzleQuestion> questions;

  Puzzle({
    required this.id,
    required this.title,
    required this.topic,
    required this.status,
    required this.scenarioParagraph,
    this.timeLimit,
    this.extras = const [],
    this.questions = const [],
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      topic: json['topic'] ?? '',
      status: json['status'] ?? 'DRAFT',
      scenarioParagraph: json['scenarioParagraph'] ?? '',
      timeLimit: json['timeLimit'],
      extras: (json['extras'] as List<dynamic>?)
              ?.map((e) => PuzzleExtra.fromJson(e))
              .toList() ??
          [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => PuzzleQuestion.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class PuzzleExtra {
  final String id;
  final String type;
  final int position;
  final Map<String, dynamic> content;

  PuzzleExtra({
    required this.id,
    required this.type,
    required this.position,
    required this.content,
  });

  factory PuzzleExtra.fromJson(Map<String, dynamic> json) {
    return PuzzleExtra(
      id: json['id'] ?? '',
      type: json['type'] ?? 'BULLETS',
      position: json['position'] ?? 0,
      content: json['content'] ?? {},
    );
  }
}

class PuzzleAttempt {
  final String id;
  final String puzzleId;
  final String userId;
  final String startedAt;
  final String? submittedAt;
  final int total;
  final int correct;
  final int wrong;
  final int skipped;
  final double? score;
  final bool? passed;
  final List<PuzzleAnswer>? answers;

  PuzzleAttempt({
    required this.id,
    required this.puzzleId,
    required this.userId,
    required this.startedAt,
    this.submittedAt,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.skipped,
    this.score,
    this.passed,
    this.answers,
  });

  factory PuzzleAttempt.fromJson(Map<String, dynamic> json) {
    return PuzzleAttempt(
      id: json['id'] ?? '',
      puzzleId: json['puzzleId'] ?? '',
      userId: json['userId'] ?? '',
      startedAt: json['startedAt'] ?? '',
      submittedAt: json['submittedAt'],
      total: json['total'] ?? 0,
      correct: json['correct'] ?? 0,
      wrong: json['wrong'] ?? 0,
      skipped: json['skipped'] ?? 0,
      score: json['score']?.toDouble(),
      passed: json['passed'],
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => PuzzleAnswer.fromJson(a))
          .toList(),
    );
  }
}

class PuzzleAnswer {
  final String id;
  final String attemptId;
  final String questionId;
  final String? selectedOptionId;
  final PuzzleQuestion? question;

  PuzzleAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.selectedOptionId,
    this.question,
  });

  factory PuzzleAnswer.fromJson(Map<String, dynamic> json) {
    return PuzzleAnswer(
      id: json['id'] ?? '',
      attemptId: json['attemptId'] ?? '',
      questionId: json['questionId'] ?? '',
      selectedOptionId: json['selectedOptionId'],
      question: json['question'] != null
          ? PuzzleQuestion.fromJson(json['question'])
          : null,
    );
  }
}
