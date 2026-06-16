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
  // Global exam timer — counts down from totalQuestions × timePerQuestion
  Timer? _globalTimer;
  int _totalSecondsRemaining = 0;
  int _tabSwitches = 0;

  @override
  void initState() {
    super.initState();
    _startGlobalTimer();
  }

  void _startGlobalTimer() {
    final mcq = context.read<McqProvider>();
    _totalSecondsRemaining = mcq.totalQuestions * mcq.timePerQuestion;

    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _totalSecondsRemaining--;
        if (_totalSecondsRemaining <= 0) {
          timer.cancel();
          _autoSubmitAll(mcq);
        }
      });
    });
  }

  void _autoSubmitAll(McqProvider mcq) {
    // Time's up — lock all unanswered questions and submit
    for (int i = 0; i < mcq.totalQuestions; i++) {
      if (!mcq.locked[i]) {
        mcq.lockAnswer(i);
      }
    }
    _submitExam(mcq);
  }

  int get _currentQuestionTimeRemaining {
    // Distribute remaining time proportionally — each question gets equal share
    final mcq = context.read<McqProvider>();
    final perQuestion = _totalSecondsRemaining > 0
        ? _totalSecondsRemaining ~/ (mcq.totalQuestions - mcq.currentIndex)
        : 0;
    return perQuestion;
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
    _globalTimer?.cancel();
    super.dispose();
  }

  void _submitExam(McqProvider mcq) async {
    _globalTimer?.cancel();
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

            return Column(
              children: [
                _buildTimerBar(mcq),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject / Topic labels
                        if (q.subject.isNotEmpty)
                          Text(
                            q.subject,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (q.topic.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              q.topic,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

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
      ),
    );
  }

  Widget _buildTimerBar(McqProvider mcq) {
    // Timer color: green → amber at 20% → red at 10%
    final totalExamTime = mcq.totalQuestions * mcq.timePerQuestion;
    final pct = totalExamTime > 0 ? _totalSecondsRemaining / totalExamTime : 0.0;
    final isWarning = pct <= 0.10;
    final isCaution = pct <= 0.20 && !isWarning;
    final timerColor = isWarning
        ? AppTheme.errorRed
        : isCaution
            ? AppTheme.warningAmber
            : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surfaceElevated,
      child: Row(
        children: [
          Icon(Icons.timer, color: timerColor, size: 18),
          const SizedBox(width: 6),
          Text(
            '${(_totalSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_totalSecondsRemaining % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              color: timerColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Numbered progress pills
          Row(
            children: List.generate(mcq.totalQuestions, (i) {
              final isCurrent = i == mcq.currentIndex;
              final isAnswered = mcq.answers[i] != null;
              Color c;
              if (isCurrent) {
                c = AppTheme.primaryGreen;
              } else if (mcq.locked[i] || isAnswered) {
                c = AppTheme.primaryGreen.withOpacity(0.2);
              } else {
                c = AppTheme.borderColor;
              }
              return GestureDetector(
                onTap: () => mcq.goToQuestion(i),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(6),
                    border: isCurrent
                        ? Border.all(color: AppTheme.primaryGreen, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white
                          : mcq.locked[i] || isAnswered
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(McqProvider mcq) {
    final isLast = mcq.currentIndex == mcq.totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            _navButton(
              icon: Icons.chevron_left,
              enabled: mcq.currentIndex > 0,
              onTap: mcq.previousQuestion,
            ),
            const SizedBox(width: 8),

            // Review / Flag button
            TextButton.icon(
              onPressed: () => mcq.toggleMarkForReview(mcq.currentIndex),
              icon: Icon(
                mcq.markedForReview.contains(mcq.currentIndex)
                    ? Icons.flag
                    : Icons.flag_outlined,
                color: mcq.markedForReview.contains(mcq.currentIndex)
                    ? AppTheme.warningAmber
                    : AppTheme.textSecondary,
                size: 18,
              ),
              label: Text(
                mcq.markedForReview.contains(mcq.currentIndex)
                    ? 'Flagged'
                    : 'Review',
                style: TextStyle(
                  color: mcq.markedForReview.contains(mcq.currentIndex)
                      ? AppTheme.warningAmber
                      : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const Spacer(),

            // Next (green bg) or Submit
            if (!isLast)
              _navButton(
                icon: Icons.chevron_right,
                enabled: true,
                onTap: mcq.nextQuestion,
                isGreen: true,
              )
            else
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: mcq.answeredCount > 0
                      ? () => _showSubmitDialog(mcq)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Submit',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isGreen = false,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 22),
        color: isGreen ? AppTheme.primaryGreen : AppTheme.textPrimary,
        style: isGreen
            ? IconButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            : null,
      ),
    );
  }

  void _showNavigator(BuildContext context) {
    final mcq = context.read<McqProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Question Navigator',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Question number grid — green if answered, gray if not
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(mcq.totalQuestions, (i) {
                  final isAnswered = mcq.answers[i] != null;
                  final isCurrent = i == mcq.currentIndex;
                  final isMarked = mcq.markedForReview.contains(i);

                  return GestureDetector(
                    onTap: () {
                      mcq.goToQuestion(i);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.primaryGreen
                            : isMarked
                                ? AppTheme.warningAmber.withOpacity(0.2)
                                : isAnswered || mcq.locked[i]
                                    ? AppTheme.primaryGreen.withOpacity(0.15)
                                    : AppTheme.surfaceHigher,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.primaryGreen
                              : isMarked
                                  ? AppTheme.warningAmber.withOpacity(0.5)
                                  : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : isMarked
                                      ? AppTheme.warningAmber
                                      : isAnswered || mcq.locked[i]
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMarked)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.warningAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(AppTheme.primaryGreen, 'Answered'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.warningAmber, 'Marked'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.surfaceHigher, 'Unanswered'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
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
    );
  }
}
