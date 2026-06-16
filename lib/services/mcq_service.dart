import '../models/question.dart';
import '../models/mcq_attempt.dart';
import 'api_client.dart';

class McqService {
  final ApiClient _api = ApiClient();

  /// Distinct subjects available in the Question table. Used to
  /// populate the MCQ setup's subject Dropdown.
  Future<List<String>> getSubjects() async {
    final data = await _api.get('/api/mcq/subjects');
    final list = data['data'] is List
        ? data['data'] as List
        : (data is List ? data : null);
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Distinct topics for [subject]. Re-fetched when the user changes
  /// the subject in the MCQ setup dropdown.
  Future<List<String>> getTopics({required String subject}) async {
    final data = await _api.get(
      '/api/mcq/topics',
      query: {'subject': subject},
    );
    final list = data['data'] is List
        ? data['data'] as List
        : (data is List ? data : null);
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<List<Question>> startExam({
    String? subject,
    String? topic,
    int limit = 10,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
    };
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (topic != null && topic.isNotEmpty) query['topic'] = topic;

    final data = await _api.get('/api/mcq/start', query: query);
    // Backend returns: { "questions": [...], "total": 5, "limit": 10 }
    final list = data['questions'] as List<dynamic>;
    final questions =
        list.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();
    questions.shuffle();
    return questions.take(limit).toList();
  }

  Future<McqAttempt> submitExam({
    required List<Map<String, dynamic>> answers,
    String? subject,
    String? topic,
  }) async {
    final body = <String, dynamic>{
      'answers': answers,
    };
    if (subject != null && subject.isNotEmpty) body['subject'] = subject;
    if (topic != null && topic.isNotEmpty) body['topic'] = topic;

    final data = await _api.post('/api/mcq/submit', body: body);
    // Backend returns flat: { "attemptId": 1, "total": 10, "correct": 8, ... }
    // No nested attempt or questions arrays.
    return McqAttempt.fromJson({
      'id': data['attemptId'],
      'userId': data['userId'] ?? '',
      'total': data['total'] ?? 0,
      'correct': data['correct'] ?? 0,
      'wrong': data['wrong'] ?? 0,
      'skipped': data['skipped'] ?? 0,
      'score': data['score'] ?? 0,
      'cutMark': data['cutMark'] ?? 0,
      'passed': data['passed'] ?? false,
      'answers': <Map<String, dynamic>>[],
    });
  }

  Future<List<McqAttempt>> getAttempts({
    int limit = 20,
    String? subject,
    String? topic,
    bool? passed,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
    };
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (topic != null && topic.isNotEmpty) query['topic'] = topic;
    if (passed != null) query['passed'] = passed.toString();

    final data = await _api.get('/api/mcq/attempts', query: query);
    // Backend returns data wrapped in {"data": [...]} or flat
    final raw = data['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((a) => McqAttempt.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<McqAttempt> getAttemptDetail(int id) async {
    final data = await _api.get('/api/mcq/attempts/$id');
    // Backend returns flat attempt fields with nested answers[].question
    return McqAttempt.fromJson(data);
  }
}
