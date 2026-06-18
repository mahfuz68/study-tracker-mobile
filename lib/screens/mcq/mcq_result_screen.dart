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

          final answers = a.answers ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Score header ──
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: a.passed
                        ? [
                            AppTheme.successGreen.withOpacity(0.2),
                            AppTheme.successGreen.withOpacity(0.05),
                          ]
                        : [
                            AppTheme.errorRed.withOpacity(0.2),
                            AppTheme.errorRed.withOpacity(0.05),
                          ],
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
                      a.passed
                          ? Icons.emoji_events
                          : Icons.sentiment_dissatisfied,
                      color: a.passed
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      a.passed ? 'Congratulations!' : 'Not passed',
                      style: TextStyle(
                        color: a.passed
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${a.score.toStringAsFixed(2)} · ${a.correct}/${a.total} correct',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Stats row ──
              Row(
                children: [
                  _statBox('Total', '${a.total}', AppTheme.textPrimary),
                  _statBox('Correct', '${a.correct}', AppTheme.successGreen),
                  _statBox('Wrong', '${a.wrong}', AppTheme.errorRed),
                  _statBox('Skipped', '${a.skipped}', AppTheme.warningAmber),
                ],
              ),

              // ── Answer Review ──
              if (answers.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'Answer Review',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(answers.length, (index) {
                  final ans = answers[index];
                  final q = ans.question;
                  if (q == null) return const SizedBox.shrink();

                  final isCorrect = ans.isCorrect ?? false;
                  final isSkipped = ans.chosen == null;
                  final correctIndex = q.correct ?? -1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSkipped
                            ? AppTheme.warningAmber.withOpacity(0.3)
                            : isCorrect
                                ? AppTheme.successGreen.withOpacity(0.3)
                                : AppTheme.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question header with status icon
                        Row(
                          children: [
                            Icon(
                              isSkipped
                                  ? Icons.skip_next
                                  : isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                              color: isSkipped
                                  ? AppTheme.warningAmber
                                  : isCorrect
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question ${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.question,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Options
                        ...List.generate(4, (i) {
                          final isChosen = ans.chosen == i;
                          final isAnswer = i == correctIndex;

                          Color dotColor;
                          if (isAnswer) {
                            dotColor = AppTheme.successGreen;
                          } else if (isChosen && !isCorrect) {
                            dotColor = AppTheme.errorRed;
                          } else {
                            dotColor = AppTheme.borderColor;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${q.labels[i]}. ${q.options[i]}',
                                    style: TextStyle(
                                      color: isChosen || isAnswer
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      fontWeight: isChosen || isAnswer
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (isAnswer)
                                  const Icon(Icons.check,
                                      color: AppTheme.successGreen, size: 16),
                                if (isChosen && !isCorrect)
                                  const Icon(Icons.close,
                                      color: AppTheme.errorRed, size: 16),
                              ],
                            ),
                          );
                        }),

                        // Explanation
                        if (q.explanation != null &&
                            q.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.infoBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              q.explanation!,
                              style: const TextStyle(
                                color: AppTheme.infoBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // ── Action buttons ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/mcq', (route) => route.isFirst),
                  child:
                      const Text('New Exam', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/mcq/history'),
                  child: const Text('View History'),
                ),
              ),
              const SizedBox(height: 32),
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
