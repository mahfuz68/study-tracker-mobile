import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/mcq_attempt.dart';
import '../../models/study_day.dart';
import '../../providers/mcq_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _service = ProgressService();
  String? _shareToken;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProgressProvider>();
      p.loadStudyPlan();
      context.read<McqProvider>().loadAttempts(limit: 20);
    });
  }

  Future<void> _generateShareToken() async {
    setState(() => _sharing = true);
    try {
      final token = await _service.generateShareToken();
      if (!mounted) return;
      setState(() => _shareToken = token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate link: $e')),
      );
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Consumer<ProgressProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.studyPlan.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen, strokeWidth: 2.4),
              );
            }
            return RefreshIndicator(
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.card,
              onRefresh: () async {
                await provider.loadStudyPlan();
                if (!mounted) return;
                await context.read<McqProvider>().loadAttempts(limit: 20);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress',
                        style: AppTheme.display(26, weight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    _buildShareCard(),
                    const SizedBox(height: 24),
                    _buildStatsCards(provider),
                    const SizedBox(height: 24),
                    _buildCompletionChart(provider),
                    const SizedBox(height: 24),
                    _buildMcqHistory(),
                    const SizedBox(height: 24),
                    _buildDayProgressTable(provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.shareGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF059669), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.share_rounded, color: Color(0xFF34D399), size: 18),
              SizedBox(width: 10),
              Text('Share Progress',
                  style: TextStyle(
                      color: Color(0xFFF0FDF4),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate a link to share your study progress with others.',
            style: TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (_shareToken != null)
            _ShareTokenBox(
              token: _shareToken!,
              onCopy: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied!')),
                );
              },
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sharing ? null : _generateShareToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
                child: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Generate Share Link',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3)),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ProgressProvider provider) {
    final totalTopics = provider.totalTopics;
    final completionPct = (provider.completionRate * 100).round();
    final cards = [
      _StatCardData(
        label: 'Completion',
        value: '$completionPct%',
        color: AppTheme.primaryGreen,
        icon: Icons.check_circle_outline_rounded,
      ),
      _StatCardData(
        label: 'Days Tracked',
        value: '${provider.studyPlan.length}',
        color: AppTheme.infoBlue,
        icon: Icons.calendar_today_rounded,
      ),
      _StatCardData(
        label: 'Total Topics',
        value: '$totalTopics',
        color: AppTheme.accentGold,
        icon: Icons.menu_book_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cardW = (c.maxWidth - 24) / 3;
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              SizedBox(
                width: cardW,
                child: _StatCard(data: cards[i]),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCompletionChart(ProgressProvider provider) {
    final days = provider.studyPlan;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completion per Day',
              style: AppTheme.display(15, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (days.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No data yet',
                  style: TextStyle(color: AppTheme.textTertiary)),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                              color: AppTheme.textTertiary, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('D${days[idx].dayNumber}',
                                  style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.border.withOpacity(0.7),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(days.length, (i) {
                    final day = days[i];
                    final rate = provider.completionRateForDay(day.dayNumber);
                    final h = (rate * 100).clamp(0.0, 100.0);
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: h == 0 ? 4 : h,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          gradient: AppTheme.chartBarGradient,
                          color: h == 0 ? AppTheme.border : null,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMcqHistory() {
    return Consumer<McqProvider>(
      builder: (context, mcq, _) {
        final attempts = mcq.attempts;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('MCQ Exam Results',
                        style: AppTheme.display(15, weight: FontWeight.w700)),
                  ),
                  if (mcq.isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryGreen),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (attempts.isEmpty)
                Text('No exams taken yet.',
                    style: AppTheme.body(13, color: AppTheme.textTertiary))
              else
                ...attempts.map(_buildAttemptTile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttemptTile(McqAttempt a) {
    final dt = _formatDate(a.createdAt);
    final pct = a.total > 0 ? ((a.correct / a.total) * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: a.passed
                  ? AppTheme.primaryGreen.withOpacity(0.15)
                  : AppTheme.errorRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                color: a.passed
                    ? AppTheme.primaryGreen
                    : AppTheme.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${a.subject ?? 'General'}${a.topic != null && a.topic!.isNotEmpty ? ' — ${a.topic}' : ''}',
                  style: AppTheme.body(13, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('${a.correct}/${a.total} correct · $dt',
                    style: AppTheme.body(12,
                        weight: FontWeight.w500, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: a.passed
                  ? AppTheme.primaryGreen.withOpacity(0.12)
                  : AppTheme.errorRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              a.passed ? 'PASS' : 'FAIL',
              style: TextStyle(
                color: a.passed
                    ? AppTheme.primaryGreen
                    : AppTheme.errorRed,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgressTable(ProgressProvider provider) {
    if (provider.studyPlan.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Day-by-Day Progress',
            style: AppTheme.display(16, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...provider.studyPlan.map((day) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Day ${day.dayNumber}',
                        style: AppTheme.body(14, weight: FontWeight.w700)),
                    if (day.label != null)
                      Text(day.label!,
                          style: AppTheme.body(12,
                              color: AppTheme.textSecondary)),
                  ],
                ),
                if (day.topics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...day.topics.map((t) {
                    final done = provider.allProgress.any(
                      (p) => p.topicId == t.id && p.isComplete,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 14,
                            color: done
                                ? AppTheme.primaryGreen
                                : AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${t.subject} — ${t.topic}',
                              style: TextStyle(
                                color: done
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: done
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  static String? _formatDayDate(StudyDay day) {
    if (day.date == null) return null;
    try {
      final parts = day.date!.split('-');
      if (parts.length != 3) return null;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM d, y · h:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _StatCardData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  _StatCardData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.95,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, color: data.color, size: 20),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.value,
                style: TextStyle(
                  color: data.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(data.label,
                style: AppTheme.body(12,
                    weight: FontWeight.w500, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ShareTokenBox extends StatelessWidget {
  final String token;
  final VoidCallback onCopy;
  const _ShareTokenBox({required this.token, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Token: $token',
              style: AppTheme.body(12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}