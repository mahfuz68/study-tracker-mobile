import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mcq_provider.dart';

class McqExamScreen extends StatefulWidget {
  const McqExamScreen({super.key});

  @override
  State<McqExamScreen> createState() => _McqExamScreenState();
}

class _McqExamScreenState extends State<McqExamScreen> {
  final Map<int, int> _remainingTime = {};
  final Map<int, Timer> _timers = {};
  int _tabSwitches = 0;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    final mcq = context.read<McqProvider>();
    for (int i = 0; i < mcq.totalQuestions; i++) {
      _remainingTime[i] = mcq.timePerQuestion;
      _timers[i] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _remainingTime[i] = (_remainingTime[i] ?? mcq.timePerQuestion) - 1;
          if (_remainingTime[i]! <= 0) {
            timer.cancel();
            mcq.lockAnswer(i);
            _autoAdvance(mcq);
          }
        });
      });
    }
  }

  void _autoAdvance(McqProvider mcq) {
    if (mcq.allLocked) {
      _submitExam(mcq);
    } else {
      final next = _findNextUnlocked(mcq);
      if (next != null) mcq.goToQuestion(next);
    }
  }

  int? _findNextUnlocked(McqProvider mcq) {
    for (int i = mcq.currentIndex + 1; i < mcq.totalQuestions; i++) {
      if (!mcq.locked[i]) return i;
    }
    for (int i = 0; i < mcq.currentIndex; i++) {
      if (!mcq.locked[i]) return i;
    }
    return null;
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _submitExam(McqProvider mcq) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await mcq.submitExam();
    if (mounted) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/mcq/result');
    }
  }

  Future<bool> _onWillPop() async {
    final mcq = context.read<McqProvider>();
    if (mcq.lockedCount == mcq.totalQuestions) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Exam?'),
        content: const Text(
          'You have unanswered questions. Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Consumer<McqProvider>(
          builder: (_, mcq, __) => Text(
            'Q${mcq.currentIndex + 1}/${mcq.totalQuestions}',
          ),
        ),
        actions: [
          Consumer<McqProvider>(
            builder: (_, mcq, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${mcq.answeredCount}/${mcq.totalQuestions}',
                  style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () => _showNavigator(context),
          ),
        ],
      ),
      body: Consumer<McqProvider>(
        builder: (context, mcq, _) {
          if (mcq.questions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final idx = mcq.currentIndex;
          final q = mcq.questions[idx];
          final remaining = _remainingTime[idx] ?? mcq.timePerQuestion;

          return Column(
            children: [
              _buildTimerBar(remaining, mcq),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.question,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(4, (i) {
                        final isSelected = mcq.answers[idx] == i;
                        final isLocked = mcq.locked[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: isLocked ? null : () => mcq.selectAnswer(idx, i),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryGreen.withOpacity(0.15)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : isLocked
                                          ? AppTheme.borderColor.withOpacity(0.5)
                                          : AppTheme.borderColor,
                                  width: isSelected ? 1.5 : 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : AppTheme.borderColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      q.labels[i],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      q.options[i],
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.textPrimary
                                            : isLocked
                                                ? AppTheme.textSecondary.withOpacity(0.6)
                                                : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(mcq),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimerBar(int remaining, McqProvider mcq) {
    final isWarning = remaining <= 10;
    final isCaution = remaining <= 20 && !isWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surfaceElevated,
      child: Row(
        children: [
          Icon(Icons.timer,
              color: isWarning
                  ? AppTheme.errorRed
                  : isCaution
                      ? AppTheme.warningAmber
                      : AppTheme.primaryGreen,
              size: 18),
          const SizedBox(width: 6),
          Text(
            '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isWarning
                  ? AppTheme.errorRed
                  : isCaution
                      ? AppTheme.warningAmber
                      : AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(mcq.totalQuestions, (i) {
              Color c;
              if (mcq.locked[i]) {
                c = AppTheme.primaryGreen;
              } else if (mcq.answers[i] != null) {
                c = AppTheme.infoBlue;
              } else if (mcq.markedForReview.contains(i)) {
                c = AppTheme.warningAmber;
              } else {
                c = AppTheme.borderColor;
              }
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(McqProvider mcq) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: mcq.currentIndex > 0 ? mcq.previousQuestion : null,
              icon: const Icon(Icons.chevron_left),
              color: AppTheme.textPrimary,
            ),
            TextButton.icon(
              onPressed: () => mcq.toggleMarkForReview(mcq.currentIndex),
              icon: Icon(
                mcq.markedForReview.contains(mcq.currentIndex)
                    ? Icons.flag
                    : Icons.flag_outlined,
                color: mcq.markedForReview.contains(mcq.currentIndex)
                    ? AppTheme.warningAmber
                    : AppTheme.textSecondary,
              ),
              label: Text(
                mcq.markedForReview.contains(mcq.currentIndex)
                    ? 'Flagged'
                    : 'Flag',
                style: TextStyle(
                  color: mcq.markedForReview.contains(mcq.currentIndex)
                      ? AppTheme.warningAmber
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            IconButton(
              onPressed: mcq.currentIndex < mcq.totalQuestions - 1
                  ? mcq.nextQuestion
                  : null,
              icon: const Icon(Icons.chevron_right),
              color: AppTheme.textPrimary,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: mcq.answeredCount > 0
                  ? () => _showSubmitDialog(mcq)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigator(BuildContext context) {
    final mcq = context.read<McqProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Question Navigator',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(mcq.totalQuestions, (i) {
                  Color c;
                  if (mcq.locked[i]) {
                    c = AppTheme.primaryGreen;
                  } else if (mcq.answers[i] != null) {
                    c = AppTheme.infoBlue;
                  } else if (mcq.markedForReview.contains(i)) {
                    c = AppTheme.warningAmber;
                  } else {
                    c = AppTheme.borderColor;
                  }
                  return InkWell(
                    onTap: () {
                      mcq.goToQuestion(i);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == mcq.currentIndex
                            ? c
                            : c.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: i == mcq.currentIndex
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i == mcq.currentIndex
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSubmitDialog(McqProvider mcq) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Answered: ${mcq.answeredCount}/${mcq.totalQuestions}'),
            Text('Locked: ${mcq.lockedCount}/${mcq.totalQuestions}'),
            Text('Flagged: ${mcq.markedForReview.length}'),
            if (_tabSwitches > 0)
              Text('Tab switches: $_tabSwitches',
                  style: const TextStyle(color: AppTheme.warningAmber)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam(mcq);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
      ),
    );
  }
}
