import '../models/progress.dart' as model;
import '../models/study_day.dart';
import 'api_client.dart';

class ProgressSummary {
  final List<StudyDay> days;
  final List<model.Progress> allProgress;

  const ProgressSummary({required this.days, required this.allProgress});
}

class ProgressService {
  final ApiClient _api = ApiClient();

  /// Returns the full study plan plus ALL of the current user's progress
  /// rows across every day. The Go backend's `GET /api/progress/summary`
  /// already returns both fields — we just previously discarded
  /// `progresses` on the client.
  Future<ProgressSummary> getStudyPlan() async {
    final data = await _api.get('/api/progress/summary');
    final daysJson = (data['days'] as List<dynamic>?) ?? const [];
    final days = daysJson
        .map((d) => StudyDay.fromJson(d as Map<String, dynamic>))
        .toList();

    final progJson = (data['progresses'] as List<dynamic>?) ?? const [];
    final allProgress = progJson
        .map((p) => model.Progress.fromJson(p as Map<String, dynamic>))
        .toList();

    return ProgressSummary(days: days, allProgress: allProgress);
  }

  Future<ProgressSummary> getProgressSummary() async {
    return await getStudyPlan();
  }

  /// Returns progress rows for a specific day. Used after a toggle so the
  /// dashboard's per-day topic list reflects the change without a full
  /// refetch. (Note: this returns ONE day's progress, not the all-days
  /// collection.)
  Future<List<model.Progress>> getDayProgress(int dayNumber) async {
    final data = await _api.get('/api/progress',
        query: {'dayNumber': dayNumber.toString()});
    final raw = data['data'];
    if (raw is List) {
      return raw
          .map((p) => model.Progress.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<model.Progress> updateProgress(
      Map<String, dynamic> progressData) async {
    final data = await _api.put('/api/progress', body: progressData);
    return model.Progress.fromJson(data);
  }

  Future<String> generateShareToken() async {
    final data = await _api.post('/api/report/token');
    return data['token'] as String;
  }
}