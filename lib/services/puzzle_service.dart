import '../models/puzzle.dart';
import '../models/puzzle_question.dart';
import 'api_client.dart';

class PuzzleService {
  final ApiClient _api = ApiClient();

  Future<List<Puzzle>> getPuzzles() async {
    final data = await _api.get('/api/puzzles');
    // Go backend returns data wrapped in {"data": [...]} or flat
    final raw = data['data'];
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else {
      list = [data];
    }
    return list
        .map((p) => _mapPuzzleSummary(p as Map<String, dynamic>))
        .toList();
  }

  Future<Puzzle> getPuzzleDetail(String id) async {
    final data = await _api.get('/api/puzzles/$id');
    return _mapPuzzleFromDetail(data);
  }

  Puzzle _mapPuzzleSummary(Map<String, dynamic> data) {
    return Puzzle(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      topic: data['topic'] ?? '',
      status: data['status'] ?? 'DRAFT',
      scenarioParagraph: data['scenarioParagraph'] ?? '',
      timeLimit: data['timeLimit'],
      extras: const [],
      questions: const [],
    );
  }

  Puzzle _mapPuzzleFromDetail(Map<String, dynamic> data) {
    final extras = (data['extras'] as List<dynamic>?)
            ?.map((e) => PuzzleExtra.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final questions = (data['questions'] as List<dynamic>?)
            ?.map((q) => PuzzleQuestion.fromJson(q as Map<String, dynamic>))
            .toList() ??
        [];
    return Puzzle(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      topic: data['topic'] ?? '',
      status: data['status'] ?? 'DRAFT',
      scenarioParagraph: data['scenarioParagraph'] ?? '',
      timeLimit: data['timeLimit'],
      extras: extras,
      questions: questions,
    );
  }

  Future<PuzzleAttempt> submitAnswers(
    String puzzleId,
    List<Map<String, dynamic>> answers,
  ) async {
    final data = await _api.post(
      '/api/puzzles/$puzzleId/submit',
      body: {'answers': answers},
    );

    // Go backend returns a flat response: { attemptId, total, correct, wrong, score, passed }
    // No "questions" key - build answers from the original submitted answers
    return PuzzleAttempt(
      id: data['attemptId'] ?? '',
      puzzleId: puzzleId,
      userId: '',
      startedAt: DateTime.now().toIso8601String(),
      submittedAt: DateTime.now().toIso8601String(),
      total: data['total'] ?? 0,
      correct: data['correct'] ?? 0,
      wrong: data['wrong'] ?? 0,
      skipped: data['skipped'] ?? 0,
      score: (data['score'] as num?)?.toDouble(),
      passed: data['passed'],
      answers: answers.map((a) {
        return PuzzleAnswer(
          id: '',
          attemptId: data['attemptId'] ?? '',
          questionId: a['questionId'] ?? '',
          selectedOptionId: a['selectedOptionId'],
        );
      }).toList(),
    );
  }

  Future<Puzzle> createPuzzle(Map<String, dynamic> puzzle) async {
    final data = await _api.post('/api/admin/puzzles', body: puzzle);
    return _mapPuzzleFromDetail(data);
  }

  Future<Puzzle> updatePuzzle(String id, Map<String, dynamic> puzzle) async {
    final data = await _api.put('/api/admin/puzzles/$id', body: puzzle);
    return _mapPuzzleFromDetail(data);
  }

  Future<void> deletePuzzle(String id) async {
    await _api.delete('/api/admin/puzzles/$id');
  }
}
