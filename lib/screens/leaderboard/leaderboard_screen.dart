import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/cache_service.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _service = LeaderboardService();
  List<LeaderboardEntry>? _entries;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cache = context.read<CacheService>();

    final cached = await cache.get('leaderboard', ttl: const Duration(hours: 6));
    if (cached != null) {
      final totalTopics = cached['totalTopics'] as int? ?? 0;
      _entries = (cached['rows'] as List<dynamic>?)?.map((r) {
        final row = r as Map<String, dynamic>;
        return LeaderboardEntry(
          userId: row['name'] as String? ?? '',
          name: row['name'] as String? ?? '',
          completedCount: row['completed'] as int? ?? 0,
          totalTopics: totalTopics,
          completionRate: totalTopics > 0
              ? ((row['rate'] as num?)?.toDouble() ?? 0) / 100.0
              : 0.0,
        );
      }).toList();
      if (mounted) setState(() => _loading = false);
    }

    try {
      _entries = await _service.getLeaderboard();
      await cache.set('leaderboard', {
        'rows': _entries!.map((e) => {
          'name': e.name,
          'completed': e.completedCount,
          'rate': e.completionRate * 100,
        }).toList(),
        'totalTopics': _entries!.isNotEmpty ? _entries!.first.totalTopics : 0,
      });
    } catch (e) {
      if (_entries == null) _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Leaderboard', style: AppTheme.display(26, weight: FontWeight.w800)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('Failed to load',
                style: AppTheme.body(14, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final entries = _entries ?? [];
    if (entries.isEmpty) {
      return Center(
        child: Text('No entries yet',
            style: AppTheme.body(15, color: AppTheme.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPodium(entries),
          const SizedBox(height: 24),
          ...entries.asMap().entries.map((e) =>
              _buildRow(e.key + 1, e.value)),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final top3 = entries.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    final medals = ['🥇', '🥈', '🥉'];
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];

    return Row(
      children: List.generate(top3.length, (i) {
        final e = top3[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: i == 0 ? 4 : 2,
              right: i == 2 ? 4 : 2,
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: colors[i].withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors[i].withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(medals[i], style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  e.name,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(13, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.completedCount}',
                  style: TextStyle(
                    color: colors[i],
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                Text('topics',
                    style: AppTheme.body(10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRow(int rank, LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank',
                style: AppTheme.body(14,
                    weight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: AppTheme.body(14, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.completionRate,
                    backgroundColor: AppTheme.border,
                    valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primaryGreen),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(entry.completionRate * 100).round()}%',
            style: AppTheme.body(14,
                weight: FontWeight.w700, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }
}