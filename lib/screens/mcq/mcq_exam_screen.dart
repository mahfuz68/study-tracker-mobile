import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mcq_provider.dart';

// Design tokens matching the JSX reference
class _ExamColors {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceHover = Color(0xFF1A1A1A);
  static const border = Color(0xFF222222);
  static const emerald = Color(0xFF00C896);
  static const emeraldDim = Color(0x1F00C896); // rgba(0,200,150,0.12)
  static const emeraldGlow = Color(0x4000C896); // rgba(0,200,150,0.25)
  static const amber = Color(0xFFF59E0B);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF888888);
  static const textDim = Color(0xFF555555);
}

class McqExamScreen extends StatefulWidget {
  const McqExamScreen({super.key});

  @override
  State<McqExamScreen> createState() => _McqExamScreenState();
}

class _McqExamScreenState extends State<McqExamScreen> {
  Timer? _globalTimer;
  int _totalSecondsRemaining = 0;
  int _tabSwitches = 0;
  bool _showSavedFeedback = false;
  int? _selectedOption;

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
    for (int i = 0; i < mcq.totalQuestions; i++) {
      if (!mcq.locked[i]) mcq.lockAnswer(i);
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
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
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _ExamColors.bg,
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
                  _buildHeader(mcq),
                  _buildTimerStrip(mcq),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryLabels(q),
                          const SizedBox(height: 20),
                          _buildQuestionCard(q),
                          const SizedBox(height: 20),
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

  // ─── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader(McqProvider mcq) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _ExamColors.border)),
        color: _ExamColors.bg,
      ),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: _ExamColors.textMuted),
          ),
          const Spacer(),
          // Q# / Total
          RichText(
            text: TextSpan(
              text: 'Q',
              style: const TextStyle(color: _ExamColors.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              children: [
                TextSpan(
                  text: '${mcq.currentIndex + 1}',
                  style: const TextStyle(color: _ExamColors.emerald, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '/${mcq.totalQuestions}',
                  style: const TextStyle(color: _ExamColors.text, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Score chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _ExamColors.emeraldDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ExamColors.emerald.withOpacity(0.3)),
            ),
            child: Text(
              '${mcq.answeredCount}/${mcq.totalQuestions}',
              style: const TextStyle(color: _ExamColors.emerald, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          // Grid icon
          GestureDetector(
            onTap: () => _showNavigator(context),
            child: const Icon(Icons.grid_view_rounded, size: 20, color: _ExamColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Timer + Question Dots Strip ──────────────────────────────────────

  Widget _buildTimerStrip(McqProvider mcq) {
    final isLowTime = _totalSecondsRemaining < 30;
    final timerColor = isLowTime ? const Color(0xFFFF4757) : _ExamColors.emerald;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _ExamColors.border)),
      ),
      child: Row(
        children: [
          // Timer pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isLowTime ? const Color(0x1FFF4757) : _ExamColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isLowTime ? const Color(0x4DFF4757) : _ExamColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, color: timerColor, size: 16),
                const SizedBox(width: 5),
                Text(
                  '${(_totalSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_totalSecondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Question dots strip
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(mcq.totalQuestions, (i) {
                  final isCurrent = i == mcq.currentIndex;
                  final isAnswered = mcq.locked[i] || mcq.answers[i] != null;
                  final isMarked = mcq.markedForReview.contains(i);

                  final size = isCurrent ? 28.0 : 22.0;
                  final radius = isCurrent ? 8.0 : 6.0;

                  Color bgColor;
                  Color textColor;
                  Border? border;

                  if (isCurrent) {
                    bgColor = _ExamColors.emerald;
                    textColor = _ExamColors.bg;
                    border = Border.all(color: _ExamColors.emerald, width: 1.5);
                  } else if (isMarked) {
                    bgColor = _ExamColors.amber.withOpacity(0.15);
                    textColor = _ExamColors.amber;
                    border = Border.all(color: _ExamColors.amber.withOpacity(0.5));
                  } else if (isAnswered) {
                    bgColor = _ExamColors.emeraldDim;
                    textColor = _ExamColors.emerald;
                    border = Border.all(color: _ExamColors.emerald.withOpacity(0.6), width: 1.5);
                  } else {
                    bgColor = _ExamColors.surface;
                    textColor = _ExamColors.textDim;
                    border = Border.all(color: _ExamColors.border, width: 1.5);
                  }

                  return GestureDetector(
                    onTap: () => mcq.goToQuestion(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: size,
                      height: size,
                      margin: const EdgeInsets.only(right: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(radius),
                        border: border,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: isCurrent ? 11 : 10,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                }),
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
              color: _ExamColors.emerald,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        if (q.topic.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            q.topic,
            style: const TextStyle(color: _ExamColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
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
        color: _ExamColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ExamColors.border),
      ),
      child: Text.rich(
        TextSpan(
          text: q.question,
          style: const TextStyle(color: _ExamColors.text, fontSize: 16, fontWeight: FontWeight.w400, height: 1.7),
          children: q.explanation != null
              ? [
                  TextSpan(
                    text: '  (${q.explanation})',
                    style: const TextStyle(color: _ExamColors.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  // ─── Option Card ──────────────────────────────────────────────────────

  Widget _buildOptionCard(McqProvider mcq, dynamic q, int idx, int optionIndex) {
    final isSelected = _selectedOption == optionIndex && !mcq.locked[idx];
    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: mcq.locked[idx]
            ? null
            : () {
                setState(() => _selectedOption = optionIndex);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(isSelected ? 1.01 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? _ExamColors.emeraldDim : _ExamColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _ExamColors.emerald : _ExamColors.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: _ExamColors.emeraldGlow, blurRadius: 0, spreadRadius: 3)]
                : null,
          ),
          child: Row(
            children: [
              // Letter badge (32x32, rounded 10)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _ExamColors.emerald : _ExamColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _ExamColors.emerald : _ExamColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  letters[optionIndex],
                  style: TextStyle(
                    color: isSelected ? _ExamColors.bg : _ExamColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Answer text
              Expanded(
                child: Text(
                  q.options[optionIndex],
                  style: TextStyle(
                    fontSize: 18,
                    color: isSelected ? _ExamColors.text : _ExamColors.text.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              // Checkmark on selection
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: const Icon(Icons.check_circle, color: _ExamColors.emerald, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────

  Widget _buildBottomBar(McqProvider mcq) {
    final hasSelection = _selectedOption != null;
    final isFlagged = mcq.markedForReview.contains(mcq.currentIndex);
    final isLast = mcq.currentIndex == mcq.totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _ExamColors.border)),
        color: _ExamColors.bg,
      ),
      child: Row(
        children: [
          // Prev chevron
          _navButton(
            icon: Icons.chevron_left_rounded,
            enabled: mcq.currentIndex > 0,
            onTap: mcq.previousQuestion,
          ),

          // Flag button
          GestureDetector(
            onTap: () => mcq.toggleMarkForReview(mcq.currentIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFlagged ? _ExamColors.amber.withOpacity(0.12) : _ExamColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isFlagged ? _ExamColors.amber.withOpacity(0.5) : _ExamColors.border),
              ),
              child: Icon(
                isFlagged ? Icons.flag : Icons.flag_outlined,
                color: isFlagged ? _ExamColors.amber : _ExamColors.textMuted,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Dynamic center CTA
          if (_showSavedFeedback)
            Expanded(
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _ExamColors.emerald,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '✓ Saved',
                  style: TextStyle(color: _ExamColors.bg, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else if (hasSelection)
            Expanded(
              child: GestureDetector(
                onTap: () => _confirmAndNext(mcq),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_ExamColors.emerald, Color(0xFF00A87A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Confirm & Submit' : 'Confirm & Next',
                        style: const TextStyle(color: _ExamColors.bg, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: _ExamColors.bg, size: 20),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: () => _skipQuestion(mcq),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _ExamColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _ExamColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Submit' : 'Skip',
                        style: const TextStyle(color: _ExamColors.textMuted, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: _ExamColors.textMuted, size: 20),
                    ],
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
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ExamColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _ExamColors.border),
        ),
        child: Icon(icon, size: 20, color: enabled ? _ExamColors.textMuted : _ExamColors.textDim),
      ),
    );
  }

  // ─── Question Navigator ───────────────────────────────────────────────

  void _showNavigator(BuildContext context) {
    final mcq = context.read<McqProvider>();
    final skippedCount = mcq.totalQuestions - mcq.answeredCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: GestureDetector(
              onTap: () {}, // prevent close on sheet tap
              child: Container(
                margin: const EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.5),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: _ExamColors.border)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _ExamColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Questions',
                          style: TextStyle(color: _ExamColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '$skippedCount skipped',
                          style: const TextStyle(color: _ExamColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 5-column grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
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
                          bgColor = _ExamColors.emerald;
                          textColor = _ExamColors.bg;
                          border = Border.all(color: _ExamColors.emerald, width: 1.5);
                        } else if (isMarked) {
                          bgColor = _ExamColors.amber.withOpacity(0.15);
                          textColor = _ExamColors.amber;
                          border = Border.all(color: _ExamColors.amber.withOpacity(0.4));
                        } else if (isAnswered) {
                          bgColor = _ExamColors.emeraldDim;
                          textColor = _ExamColors.emerald;
                          border = Border.all(color: _ExamColors.emerald.withOpacity(0.6), width: 1.5);
                        } else {
                          bgColor = _ExamColors.surface;
                          textColor = _ExamColors.textMuted;
                          border = Border.all(color: _ExamColors.border);
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
                              borderRadius: BorderRadius.circular(12),
                              border: border,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendDot(_ExamColors.emerald, 'Answered'),
                        const SizedBox(width: 20),
                        _legendDot(_ExamColors.amber, 'Marked'),
                        const SizedBox(width: 20),
                        _legendDot(_ExamColors.textDim, 'Skipped'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _ExamColors.textMuted, fontSize: 11)),
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
