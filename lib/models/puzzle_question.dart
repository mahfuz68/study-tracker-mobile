class PuzzleQuestion {
  final String id;
  final String puzzleId;
  final int position;
  final String text;
  final String? explanation;
  final List<PuzzleOption> options;

  PuzzleQuestion({
    required this.id,
    required this.puzzleId,
    required this.position,
    required this.text,
    this.explanation,
    this.options = const [],
  });

  factory PuzzleQuestion.fromJson(Map<String, dynamic> json) {
    return PuzzleQuestion(
      id: json['id'] ?? '',
      puzzleId: json['puzzleId'] ?? '',
      position: json['position'] ?? 0,
      text: json['text'] ?? '',
      explanation: json['explanation'],
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => PuzzleOption.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class PuzzleOption {
  final String id;
  final String questionId;
  final String label;
  final String text;
  final bool isCorrect;

  PuzzleOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.text,
    required this.isCorrect,
  });

  factory PuzzleOption.fromJson(Map<String, dynamic> json) {
    return PuzzleOption(
      id: json['id'] ?? '',
      questionId: json['questionId'] ?? '',
      label: json['label'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}
