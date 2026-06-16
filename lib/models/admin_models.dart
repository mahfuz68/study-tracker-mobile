class QuestionAdmin {
  final int id;
  final String subject;
  final String topic;
  final String question;
  final List<String> options;
  final int correct;

  QuestionAdmin({
    required this.id,
    required this.subject,
    required this.topic,
    required this.question,
    required this.options,
    required this.correct,
  });

  factory QuestionAdmin.fromJson(Map<String, dynamic> json) {
    return QuestionAdmin(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      question: json['question'] ?? '',
      options: [
        json['optionA'] ?? '',
        json['optionB'] ?? '',
        json['optionC'] ?? '',
        json['optionD'] ?? '',
      ],
      correct: json['correct'] ?? 0,
    );
  }
}

class UserAdmin {
  final String id;
  final String name;
  final String email;
  final String role;

  UserAdmin({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserAdmin.fromJson(Map<String, dynamic> json) {
    return UserAdmin(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
    );
  }
}
