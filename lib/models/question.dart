class Question {
  final int id;
  final String subject;
  final String topic;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int? correct;
  final String? explanation;

  Question({
    required this.id,
    required this.subject,
    required this.topic,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.correct,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      question: json['question'] ?? '',
      optionA: json['optionA'] ?? '',
      optionB: json['optionB'] ?? '',
      optionC: json['optionC'] ?? '',
      optionD: json['optionD'] ?? '',
      correct: json['correct'],
      explanation: json['explanation'],
    );
  }

  List<String> get options => [optionA, optionB, optionC, optionD];
  List<String> get labels => ['A', 'B', 'C', 'D'];
}
