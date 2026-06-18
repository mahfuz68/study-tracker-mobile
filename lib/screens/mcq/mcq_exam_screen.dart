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

class _McqExamScreenState extends State<McqExamScreen>
    with SingleTickerProviderStateMixin {
  Timer? _globalTimer;
  int _totalSecondsRemaining = 0;
  int _tabSwitches = 0;
  bool _showSavedFeedback = false;
  int? _selectedOption;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
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
    for (int i = 0; i < mcq.totalQuestions; i++) {
      if (!mcq.locked[i]) {
        mcq.lockAnswer(i);
      }
    }
    _submitExam(mcq);
  }

  void _confirmAndNext(McqProvider mcq) {
    if (_selectedOption == null) return;
    mcq.lockAnswer(mcq.currentIndex);
    setState(() => _showSavedFeedback = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _showSavedFeedback = false);
      _selectedOption = null;

      if (mcq.allLocked || mcq.currentIndex == mcq.totalQuestions - 1) {
        _submitExam(mcq);
      } else {
        final next = _findNextUnlocked(mcq);
        if (next != null) {
          mcq.goToQuestion(next);
        } else {
          _submitExam(mcq);
        }
      }
    });
  }

  void _skipQuestion(McqProvider mcq) {
    if (mcq.currentIndex == mcq.totalQuestions - 1) {
      _submitExam(mcq);
    } else {
      mcq.nextQuestion();
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
    _scaleController.dispose();
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
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Consumer<McqProvider>(
            builder: (context, mcq, _) {
              if (mcq.questions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final idx = mcq.currentIndex;
              final q = mcq.questions[idx];

              return Column(
                children: [
                  _buildAppBar(mcq),
                  _buildTimerStrip(mcq),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryLabels(q),
                          const SizedBox(height: 14),
                          _buildQuestionCard(q),
                          const SizedBox(height: 16),
                          ...List.generate(4, (i) => _buildOptionCard(mcq, q, idx, i)),
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
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────

  Widget _buildAppBar(McqProvider mcq) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppTheme.textPrimary,
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          // Q# / Total title
          RichText(
            text: TextSpan(
              text: 'Q${mcq.currentIndex + 1}',
              style: const TextStyle(
                color: Color(0xFF00C896),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: '/${mcq.totalQuestions}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00C896).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF00C896)),
                const SizedBox(width: 4),
                Text(
                  '${mcq.answeredCount}/${mcq.totalQuestions}',
                  style: const TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Grid navigator button
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, size: 22),
            color: AppTheme.textSecondary,
            onPressed: () => _showNavigator(context),
          ),
        ],
      ),
    );
  }

  // ─── Timer + Question Dots Strip ──────────────────────────────────────

  Widget _buildTimerStrip(McqProvider mcq) {
    final totalExamTime = mcq.totalQuestions * mcq.timePerQuestion;
    final isCritical = _totalSecondsRemaining <= 30;
    final timerColor = isCritical ? AppTheme.errorRed : const Color(0xFF00C896);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Timer pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: timerColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, color: timerColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${(_totalSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_totalSecondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Question dots (horizontal scroll)
          Expanded(
            child: SizedBox(
              height: 26,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mcq.totalQuestions,
                itemBuilder: (context, i) {
                  final isCurrent = i == mcq.currentIndex;
                  final isAnswered = mcq.locked[i] || mcq.answers[i] != null;
                  final isMarked = mcq.markedForReview.contains(i);

                  Color bgColor;
                  Color textColor;
                  Border? border;

                  if (isCurrent) {
                    bgColor = const Color(0xFF00C896);
                    textColor = Colors.white;
                    border = Border.all(color: const Color(0xFF00C896), width: 2);
                  } else if (isMarked) {
                    bgColor = AppTheme.warningAmber.withOpacity(0.2);
                    textColor = AppTheme.warningAmber;
                    border = Border.all(color: AppTheme.warningAmber.withOpacity(0.5));
                  } else if (isAnswered) {
                    bgColor = const Color(0xFF00C896).withOpacity(0.15);
                    textColor = const Color(0xFF00C896);
                    border = null;
                  } else {
                    bgColor = AppTheme.cardHigher;
                    textColor = AppTheme.textSecondary;
                    border = null;
                  }

                  return GestureDetector(
                    onTap: () => mcq.goToQuestion(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(right: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: border,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category + Topic Labels ──────────────────────────────────────────

  Widget _buildCategoryLabels(dynamic q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.subject.isNotEmpty)
          Text(
            q.subject.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF00C896),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        if (q.topic.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            q.topic,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Question Card ────────────────────────────────────────────────────

  Widget _buildQuestionCard(dynamic q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        q.question,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

  // ─── Option Card ──────────────────────────────────────────────────────

  Widget _buildOptionCard(McqProvider mcq, dynamic q, int idx, int optionIndex) {
    final isSelected = _selectedOption == optionIndex && !mcq.locked[idx];
    final isLocked = mcq.locked[idx];
    final isCorrectOption = q.correct == optionIndex;

    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: isLocked
            ? null
            : () {
                setState(() => _selectedOption = optionIndex);
                _scaleController.forward().then((_) => _scaleController.reverse());
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00C896).withOpacity(0.08)
                : AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00C896)
                  : isLocked && isCorrectOption
                      ? AppTheme.successGreen.withOpacity(0.5)
                      : AppTheme.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Letter badge
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00C896)
                      : isLocked && isCorrectOption
                          ? AppTheme.successGreen.withOpacity(0.2)
                          : AppTheme.cardHigher,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  letters[optionIndex],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isLocked && isCorrectOption
                            ? AppTheme.successGreen
                            : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Answer text
              Expanded(
                child: Text(
                  q.options[optionIndex],
                  style: TextStyle(
                    color: isSelected || (isLocked && isCorrectOption)
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              // Checkmark on selection
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00C896),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────

  Widget _buildBottomBar(McqProvider mcq) {
    final isLast = mcq.currentIndex == mcq.totalQuestions - 1;
    final hasSelection = _selectedOption != null;
    final isFlagged = mcq.markedForReview.contains(mcq.currentIndex);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous chevron
            _navButton(
              icon: Icons.chevron_left_rounded,
              enabled: mcq.currentIndex > 0,
              onTap: mcq.previousQuestion,
            ),

            // Flag toggle
            GestureDetector(
              onTap: () => mcq.toggleMarkForReview(mcq.currentIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isFlagged
                      ? AppTheme.warningAmber.withOpacity(0.15)
                      : AppTheme.cardHigher,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFlagged
                        ? AppTheme.warningAmber.withOpacity(0.4)
                        : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFlagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isFlagged ? AppTheme.warningAmber : AppTheme.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFlagged ? 'Flagged' : 'Flag',
                      style: TextStyle(
                        color: isFlagged ? AppTheme.warningAmber : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Dynamic center CTA
            if (_showSavedFeedback)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: AppTheme.successGreen, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '✓ Saved',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else if (hasSelection)
              GestureDetector(
                onTap: () => _confirmAndNext(mcq),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C896), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C896).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isLast ? 'Confirm & Submit →' : 'Confirm & Next →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _skipQuestion(mcq),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardHigher,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    isLast ? 'Submit →' : 'Skip →',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(width: 10),

            // Next chevron
            _navButton(
              icon: Icons.chevron_right_rounded,
              enabled: mcq.currentIndex < mcq.totalQuestions - 1,
              onTap: mcq.nextQuestion,
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
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.cardHigher : AppTheme.cardHigher.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppTheme.border : AppTheme.border.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary.withOpacity(0.4),
        ),
      ),
    );
  }

  // ─── Question Navigator ───────────────────────────────────────────────

  void _showNavigator(BuildContext context) {
    final mcq = context.read<McqProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Question Navigator',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5-column grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: mcq.totalQuestions,
                itemBuilder: (context, i) {
                  final isAnswered = mcq.locked[i] || mcq.answers[i] != null;
                  final isCurrent = i == mcq.currentIndex;
                  final isMarked = mcq.markedForReview.contains(i);

                  Color bgColor;
                  Color textColor;
                  Border? border;

                  if (isCurrent) {
                    bgColor = const Color(0xFF00C896);
                    textColor = Colors.white;
                    border = Border.all(color: const Color(0xFF00C896), width: 2);
                  } else if (isMarked) {
                    bgColor = AppTheme.warningAmber.withOpacity(0.15);
                    textColor = AppTheme.warningAmber;
                    border = Border.all(color: AppTheme.warningAmber.withOpacity(0.4));
                  } else if (isAnswered) {
                    bgColor = const Color(0xFF00C896).withOpacity(0.12);
                    textColor = const Color(0xFF00C896);
                    border = null;
                  } else {
                    bgColor = AppTheme.cardHigher;
                    textColor = AppTheme.textSecondary;
                    border = Border.all(color: AppTheme.border);
                  }

                  return GestureDetector(
                    onTap: () {
                      mcq.goToQuestion(i);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: border,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isMarked)
                            const Positioned(
                              top: 3,
                              right: 3,
                              child: Icon(Icons.bookmark_rounded, size: 10, color: AppTheme.warningAmber),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(const Color(0xFF00C896), 'Answered'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.warningAmber, 'Flagged'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.textSecondary, 'Unanswered'),
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  // ─── Submit Dialog ────────────────────────────────────────────────────

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
