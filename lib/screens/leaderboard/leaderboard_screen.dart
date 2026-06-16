import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/leaderboard_entry.dart';
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
    try {
      _entries = await _service.getLeaderboard();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('Failed to load', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final entries = _entries ?? [];
    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries yet', style: TextStyle(color: AppTheme.textSecondary)),
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
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.completedCount}',
                  style: TextStyle(
                    color: colors[i],
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('topics',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10)),
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
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.completionRate,
                    backgroundColor: AppTheme.borderColor,
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
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
