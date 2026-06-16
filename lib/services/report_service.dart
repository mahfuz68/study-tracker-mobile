import '../models/report.dart';
import 'api_client.dart';

class ReportService {
  final ApiClient _api = ApiClient();

  Future<StudyReport> getReport(String token) async {
    final data = await _api.get('/api/report/share/$token');
    final userName = data['userName'] as String? ?? '';
    final days = data['days'] as List<dynamic>? ?? [];
    final progresses = data['progresses'] as List<dynamic>? ?? [];

    final progressMap = <int, Map<String, dynamic>>{};
    for (final p in progresses) {
      final row = p as Map<String, dynamic>;
      progressMap[row['topicId'] as int] = row;
    }

    int completed = 0;
    int total = 0;
    final reportDays = <ReportDay>[];

    for (final day in days) {
      final d = day as Map<String, dynamic>;
      final topics = (d['topics'] as List<dynamic>?) ?? [];
      int dayCompleted = 0;
      final reportTopics = <ReportTopic>[];

      for (final t in topics) {
        final topic = t as Map<String, dynamic>;
        total++;
        final p = progressMap[topic['id'] as int];
        final isComplete = p != null && p['isComplete'] == true;
        if (isComplete) dayCompleted++;
        reportTopics.add(ReportTopic(
          subject: topic['subject'] ?? '',
          topic: topic['topic'] ?? '',
          isComplete: isComplete,
          examMark: p?['examMark'] as int?,
        ));
      }

      completed += dayCompleted;
      reportDays.add(ReportDay(
        dayNumber: d['dayNumber'] ?? 0,
        completedTopics: dayCompleted,
        totalTopics: topics.length,
        topics: reportTopics,
      ));
    }

    return StudyReport(
      userName: userName,
      generatedAt: DateTime.now().toIso8601String(),
      completionRate: total > 0 ? completed / total : 0.0,
      completedTopics: completed,
      totalTopics: total,
      studyTimeMin: 0,
      avgExamMark: 0.0,
      days: reportDays,
    );
  }
}
