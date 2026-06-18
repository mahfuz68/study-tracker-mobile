import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/study_day.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mcq_provider.dart';
import '../../providers/navigation_controller.dart';
import '../../providers/puzzle_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/cache_service.dart';
import '../../widgets/day_selector.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/topic_row.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

  Future<void> _initialLoad() async {
    final provider = context.read<ProgressProvider>();
    final cache = context.read<CacheService>();

    // Check if daily cache bust is needed (4:00 AM threshold)
    if (await cache.shouldBustDailyCache()) {
      // Force background refresh of all cached data
      await Future.wait([
        provider.loadStudyPlan(),
        context.read<McqProvider>().loadSubjects(),
        context.read<PuzzleProvider>().loadPuzzles(),
      ]);
      await cache.markDailyCacheBusted();
    } else {
      await provider.loadStudyPlan();
    }
    if (!mounted) return;
    // Auto-select the latest day whose date is on or before today.
    final pick = provider.latestDayOnOrBefore(DateTime.now());
    if (pick != null && pick.dayNumber != provider.currentDay) {
      provider.setCurrentDay(pick.dayNumber);
      await provider.loadDayProgress(pick.dayNumber);
    } else {
      await provider.loadDayProgress(provider.currentDay);
    }
  }

  Future<void> _pickDate(ProgressProvider provider) async {
    final now = DateTime.now();
    final earliest = provider.studyPlan
        .map((d) => d.date == null ? null : DateTime.tryParse(d.date!))
        .whereType<DateTime>()
        .fold<DateTime?>(null, (acc, d) => acc == null || d.isBefore(acc) ? d : acc)
        ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: earliest,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryGreen,
            onPrimary: Colors.white,
            surface: AppTheme.card,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final match = provider.findDayByDate(picked);
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No study plan is scheduled for that date.')),
      );
      return;
    }
    provider.setCurrentDay(match.dayNumber);
    await provider.loadDayProgress(match.dayNumber);
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
            if (provider.studyPlan.isEmpty) {
              return const Center(
                child: Text('No study plan found',
                    style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            final day = provider.currentStudyDay;
            if (day == null) {
              return const SizedBox.shrink();
            }

            // Current-day topic completion (for the topic list and bar).
            final completedToday = provider.currentProgress
                .where((p) => p.isComplete)
                .length;
            final totalToday = day.topics.length;
            final dayCompletion =
                totalToday > 0 ? (completedToday / totalToday) : 0.0;

            // Cross-day aggregates (for the "X / Y completed" line and
            // percent). The user spec wants the dashboard to reflect ALL
            // days, not just the current one.
            final totalCompleted = provider.totalCompleted;
            final totalTopics = provider.totalTopics;
            final overallCompletion = provider.completionRate;
            final percent = (overallCompletion * 100).round();

            return RefreshIndicator(
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.card,
              onRefresh: _initialLoad,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onCalendarTap: () => _pickDate(provider)),
                    const SizedBox(height: 20),
                    DaySelector(
                      currentDay: provider.currentDay,
                      totalDays: provider.totalDays,
                      onPrevious: () {
                        final newDay = provider.currentDay - 1;
                        if (newDay < 1) return;
                        provider.setCurrentDay(newDay);
                        provider.loadDayProgress(newDay);
                      },
                      onNext: () {
                        final newDay = provider.currentDay + 1;
                        if (newDay > provider.totalDays) return;
                        provider.setCurrentDay(newDay);
                        provider.loadDayProgress(newDay);
                      },
                    ),
                    const SizedBox(height: 20),
                    _ProgressHeader(
                      day: day,
                      completed: totalCompleted,
                      total: totalTopics,
                      percent: percent,
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(value: overallCompletion),
                    const SizedBox(height: 8),
                    // Sub-line showing today's slice, since the user
                    // is looking at a specific day.
                    Text(
                      totalToday == 0
                          ? 'No topics scheduled'
                          : '$completedToday / $totalToday on this day',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Topics',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...day.topics.map((topic) {
                      final matches = provider.currentProgress
                          .where((p) => p.topicId == topic.id)
                          .toList();
                      final p = matches.isNotEmpty ? matches.first : null;
                      final isComplete = p?.isComplete ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TopicRow(
                          topic: topic,
                          isComplete: isComplete,
                          examMark: p?.examMark,
                          hasExam: p?.hasExam ?? false,
                          onToggle: isComplete
                              ? () {} // one-way lock: no-op
                              : () {
                                  provider.toggleComplete(
                                    topic.id,
                                    DateTime.now()
                                        .toIso8601String()
                                        .split('T')[0],
                                    true, // always true — never uncheck
                                  );
                                },
                          onExamTap: () {
                            // Switch to the MCQ tab (no route push) and
                            // pre-fill the requested subject/topic.
                            context.read<NavigationController>().requestMcq(
                                  subject: topic.subject,
                                  topic: topic.topic,
                                );
                          },
                        ),
                      );
                    }),
                    if (provider.error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(
                        message: 'Failed to update: ${provider.error}',
                        onDismiss: () => provider.setError(null),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCalendarTap;
  const _Header({required this.onCalendarTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = (auth.user?.name ?? 'U').isNotEmpty
        ? auth.user!.name.substring(0, 1).toUpperCase()
        : 'U';
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Dashboard',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 18,
            onPressed: onCalendarTap,
            icon: const Icon(Icons.calendar_today_rounded,
                color: AppTheme.textTertiary),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final StudyDay day;
  final int completed;
  final int total;
  final int percent;

  const _ProgressHeader({
    required this.day,
    required this.completed,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(day.date);
    final hasProgress = completed > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Day ${day.dayNumber}${dateLabel != null ? ' — $dateLabel' : ''}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$completed / $total completed',
                  style: TextStyle(
                    color: hasProgress
                        ? AppTheme.primaryGreen
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (day.label != null && day.label!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            day.label!,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  static String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      // Backend returns "YYYY-MM-DD". Parse as a local date.
      final parts = raw.split('-');
      if (parts.length != 3) return null;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DateFormat('MMMM d, y').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  color: AppTheme.textTertiary, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}