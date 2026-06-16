import 'dart:convert';
import '../models/leaderboard_entry.dart';
import 'api_client.dart';

class LeaderboardService {
  final ApiClient _api = ApiClient();

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final data = await _api.get('/api/leaderboard');
    final rows = data['rows'] as List<dynamic>? ?? [];
    final totalTopics = data['totalTopics'] as int? ?? 0;

    return rows.map((r) {
      final row = r as Map<String, dynamic>;
      return LeaderboardEntry(
        userId: utf8.encode(row['name'] as String? ?? '').toString(),
        name: row['name'] as String? ?? '',
        completedCount: row['completed'] as int? ?? 0,
        totalTopics: totalTopics,
        completionRate: totalTopics > 0
            ? ((row['rate'] as num?)?.toDouble() ?? 0) / 100.0
            : 0.0,
      );
    }).toList();
  }
}
