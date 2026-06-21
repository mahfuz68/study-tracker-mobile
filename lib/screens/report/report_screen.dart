import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/report.dart';
import '../../services/progress_service.dart';

class ReportScreen extends StatefulWidget {
  final String token;
  const ReportScreen({super.key, required this.token});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  StudyReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ProgressService();
      final days = await service.getProgressSummary();

      int completed = 0;
      int total = 0;
      for (final d in days) {
        total += d.topics.length;
      }

      _report = StudyReport(
        userName: '',
        generatedAt: DateTime.now().toIso8601String(),
        completionRate: total > 0 ? completed / total : 0.0,
        completedTopics: completed,
        totalTopics: total,
        studyTimeMin: 0,
        avgExamMark: 0.0,
        days: days.map((d) => ReportDay(
          dayNumber: d.dayNumber,
          completedTopics: 0,
          totalTopics: d.topics.length,
          topics: d.topics.map((t) => ReportTopic(
            subject: t.subject,
            topic: t.topic,
            isComplete: false,
          )).toList(),
        )).toList(),
      );
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Progress Report', style: AppTheme.display(26, weight: FontWeight.w800)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error!, style: AppTheme.body(14, color: AppTheme.errorRed)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final r = _report!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text('Study Progress Report',
                  style: AppTheme.display(20, weight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _stat(Icons.check_circle, '${r.completedTopics}', 'Completed'),
                  _stat(Icons.menu_book, '${r.totalTopics}', 'Total Topics'),
                  _stat(Icons.percent, '${(r.completionRate * 100).round()}%', 'Rate'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...r.days.map((day) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${day.dayNumber}',
                      style: AppTheme.body(14,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...day.topics.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              t.isComplete
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: t.isComplete
                                  ? AppTheme.successGreen
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text('${t.subject} - ${t.topic}',
                                style: AppTheme.body(13,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )),
                ],
              ),
            )),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 28),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono')),
          Text(label,
              style: AppTheme.body(11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}