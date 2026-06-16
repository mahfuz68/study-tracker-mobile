import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mcq_provider.dart';

class McqResultScreen extends StatelessWidget {
  const McqResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<McqProvider>(
        builder: (context, mcq, _) {
          final a = mcq.lastAttempt;
          if (a == null) {
            return const Center(child: Text('No results'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: a.passed
                        ? [AppTheme.successGreen.withOpacity(0.2), AppTheme.successGreen.withOpacity(0.05)]
                        : [AppTheme.errorRed.withOpacity(0.2), AppTheme.errorRed.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: a.passed
                        ? AppTheme.successGreen.withOpacity(0.3)
                        : AppTheme.errorRed.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      a.passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      color: a.passed ? AppTheme.successGreen : AppTheme.errorRed,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      a.passed ? 'Congratulations!' : 'Keep Trying!',
                      style: TextStyle(
                        color: a.passed ? AppTheme.successGreen : AppTheme.errorRed,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${a.score.toStringAsFixed(1)} / ${a.total}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cut mark: ${a.cutMark.toStringAsFixed(1)} • ${a.passed ? 'Passed' : 'Failed'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _statBox('Correct', '${a.correct}', AppTheme.successGreen),
                  _statBox('Wrong', '${a.wrong}', AppTheme.errorRed),
                  _statBox('Skipped', '${a.skipped}', AppTheme.warningAmber),
                  _statBox('Total', '${a.total}', AppTheme.textPrimary),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/mcq', (route) => route.isFirst),
                  child: const Text('New Exam', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/mcq/history'),
                  child: const Text('View History'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
