import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/mcq_attempt.dart';
import '../../services/mcq_service.dart';

class McqReviewScreen extends StatefulWidget {
  final int attemptId;
  const McqReviewScreen({super.key, required this.attemptId});

  @override
  State<McqReviewScreen> createState() => _McqReviewScreenState();
}

class _McqReviewScreenState extends State<McqReviewScreen> {
  late Future<McqAttempt> _future;

  @override
  void initState() {
    super.initState();
    _future = McqService().getAttemptDetail(widget.attemptId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer Review')),
      body: FutureBuilder<McqAttempt>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(
              child: Text('Failed to load review',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final attempt = snap.data!;
          final answers = attempt.answers ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: answers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _badge('Score', attempt.score.toStringAsFixed(1),
                          AppTheme.primaryGreen),
                      _badge('Correct', '${attempt.correct}',
                          AppTheme.successGreen),
                      _badge('Wrong', '${attempt.wrong}',
                          AppTheme.errorRed),
                      _badge('Skipped', '${attempt.skipped}',
                          AppTheme.warningAmber),
                    ],
                  ),
                );
              }

              final ans = answers[index - 1];
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
                        Text('Question ${index}',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(q.question,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14)),
                    const SizedBox(height: 12),
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
                            Text(
                              '${q.labels[i]}. ${q.options[i]}',
                              style: TextStyle(
                                color: isChosen || isAnswer
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontWeight:
                                    isChosen || isAnswer
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (q.explanation != null && q.explanation!.isNotEmpty) ...[
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
            },
          );
        },
      ),
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}
