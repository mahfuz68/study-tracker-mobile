import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mcq_provider.dart';
import 'mcq_review_screen.dart';

class McqHistoryScreen extends StatefulWidget {
  const McqHistoryScreen({super.key});

  @override
  State<McqHistoryScreen> createState() => _McqHistoryScreenState();
}

class _McqHistoryScreenState extends State<McqHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<McqProvider>().loadAttempts(limit: 50);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Exam History', style: AppTheme.display(26, weight: FontWeight.w800)),
      ),
      body: Consumer<McqProvider>(
        builder: (context, mcq, _) {
          if (mcq.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final attempts = mcq.attempts;
          if (attempts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.border),
                  SizedBox(height: 16),
                  Text('No exam history yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => mcq.loadAttempts(limit: 50),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final a = attempts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => McqReviewScreen(attemptId: a.id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: a.passed
                                  ? AppTheme.successGreen.withOpacity(0.15)
                                  : AppTheme.errorRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${a.score.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: a.passed
                                    ? AppTheme.successGreen
                                    : AppTheme.errorRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: a.passed
                                            ? AppTheme.successGreen
                                                .withOpacity(0.15)
                                            : AppTheme.errorRed
                                                .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        a.passed ? 'PASS' : 'FAIL',
                                        style: TextStyle(
                                          color: a.passed
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'JetBrains Mono',
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${a.correct}/${a.total} correct',
                                        style: AppTheme.body(14,
                                            weight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(a.createdAt),
                                  style: AppTheme.body(11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppTheme.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
