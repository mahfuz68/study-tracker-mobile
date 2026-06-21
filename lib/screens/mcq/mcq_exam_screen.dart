import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mcq_provider.dart';
import '../../widgets/leave_confirmation_sheet.dart';
import 'mcq_result_screen.dart';

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
  final Map<int, int?> _selections = {}; // questionIndex → selected option
  final ScrollController _dotScrollController = ScrollController();

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

  void _skipQuestion(McqProvider mcq) {
    // If user selected an option, save it to the provider before moving on
    final selection = _selections[mcq.currentIndex];
    if (selection != null && !mcq.locked[mcq.currentIndex]) {
      mcq.selectAnswer(mcq.currentIndex, selection);
    }

    if (mcq.currentIndex == mcq.totalQuestions - 1) {
      _submitExam(mcq);
    } else {
      mcq.nextQuestion();
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _dotScrollController.dispose();
    super.dispose();
  }

  void _submitExam(McqProvider mcq) async {
    _globalTimer?.cancel();
    if (!mounted) return;

    // Sync all local selections to the provider before submitting
    for (final entry in _selections.entries) {
      if (entry.value != null) {
        mcq.selectAnswer(entry.key, entry.value!);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await mcq.submitExam();
    if (mounted) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const McqResultScreen()),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final mcq = context.read<McqProvider>();
    if (mcq.lockedCount == mcq.totalQuestions) return true;

    return showLeaveSheet(
      context,
      icon: Icons.menu_book_rounded,
      title: 'Leave Exam?',
      subtitle: 'You have unanswered questions.\nYour progress will be lost.',
      confirmLabel: 'Leave Exam',
    );
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
              border: Border.all(color: _ExamColors.emerald.withValues(alpha: 0.3)),
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
              controller: _dotScrollController,
              child: Row(
                children: List.generate(mcq.totalQuestions, (i) {
                  final isCurrent = i == mcq.currentIndex;
                  final isAnswered = mcq.locked[i] || mcq.answers[i] != null;
                  final isMarked = mcq.markedForReview.contains(i);

                  final size = isCurrent ? 28.0 : 22.0;
                  final radius = isCurrent ? 8.0 : 6.0;

                  // Auto-scroll to keep current dot visible
                  if (isCurrent) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_dotScrollController.hasClients) {
                        final target = (i * 27.0).clamp(
                          0.0,
                          _dotScrollController.position.maxScrollExtent,
                        );
                        _dotScrollController.animateTo(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }
                  Color bgColor;
                  Color textColor;
                  Border? border;

                  if (isCurrent) {
                    bgColor = _ExamColors.emerald;
                    textColor = _ExamColors.bg;
                    border = Border.all(color: _ExamColors.emerald, width: 1.5);
                  } else if (isMarked) {
                    bgColor = _ExamColors.amber.withValues(alpha: 0.15);
                    textColor = _ExamColors.amber;
                    border = Border.all(color: _ExamColors.amber.withValues(alpha: 0.5));
                  } else if (isAnswered) {
                    bgColor = _ExamColors.emeraldDim;
                    textColor = _ExamColors.emerald;
                    border = Border.all(color: _ExamColors.emerald.withValues(alpha: 0.6), width: 1.5);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.question,
            style: const TextStyle(
              color: _ExamColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.7,
            ),
          ),
          // if (q.explanation != null) ...[
          //   const SizedBox(height: 10),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: _ExamColors.bg,
          //       borderRadius: BorderRadius.circular(6),
          //       border: Border.all(color: _ExamColors.border),
          //     ),
          //     child: Text(
          //       q.explanation!,
          //       style: const TextStyle(
          //         color: _ExamColors.textMuted,
          //         fontSize: 11,
          //         fontWeight: FontWeight.w400,
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  // ─── Option Card ──────────────────────────────────────────────────────

  Widget _buildOptionCard(McqProvider mcq, dynamic q, int idx, int optionIndex) {
    final isSelected = _selections[idx] == optionIndex && !mcq.locked[idx];
    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: mcq.locked[idx]
            ? null
            : () {
                setState(() => _selections[idx] = optionIndex);
              },
        child: AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
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
                    color: isSelected ? _ExamColors.text : _ExamColors.text.withValues(alpha: 0.8),
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
        ), // AnimatedScale
      ),
    );
  }

  // ─── Bottom Bar (Glassmorphic) ────────────────────────────────────────

  Widget _buildBottomBar(McqProvider mcq) {
    final isFlagged = mcq.markedForReview.contains(mcq.currentIndex);
    final isLast = mcq.currentIndex == mcq.totalQuestions - 1;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: const BoxDecoration(
            color: Color(0xB30A0A0A), // ~70% opacity dark
            border: Border(
              top: BorderSide(color: Color(0x22FFFFFF), width: 0.5), // subtle white edge
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Prev chevron — saves selection before navigating back
                _navChevron(
                  icon: Icons.chevron_left_rounded,
                  enabled: mcq.currentIndex > 0,
                  onTap: () {
                    final selection = _selections[mcq.currentIndex];
                    if (selection != null && !mcq.locked[mcq.currentIndex]) {
                      mcq.selectAnswer(mcq.currentIndex, selection);
                    }
                    mcq.previousQuestion();
                  },
                ),

                const SizedBox(width: 8),

                // Flag button
                GestureDetector(
                  onTap: () => mcq.toggleMarkForReview(mcq.currentIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFlagged
                          ? _ExamColors.amber.withValues(alpha: 0.12)
                          : const Color(0x1AFFFFFF), // frosted white 10%
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFlagged
                            ? _ExamColors.amber.withValues(alpha: 0.5)
                            : const Color(0x15FFFFFF), // subtle white border
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isFlagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isFlagged ? _ExamColors.amber : _ExamColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Dynamic center CTA — always a Skip button
                Expanded(
                    child: GestureDetector(
                      onTap: () => _skipQuestion(mcq),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF), // frosted white 8%
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0x15FFFFFF), // subtle white border
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Submit' : 'Skip',
                              style: const TextStyle(
                                color: _ExamColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, color: _ExamColors.textDim, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Next chevron — also saves any selection before advancing
                _navChevron(
                  icon: Icons.chevron_right_rounded,
                  enabled: mcq.currentIndex < mcq.totalQuestions - 1,
                  onTap: () {
                    final selection = _selections[mcq.currentIndex];
                    if (selection != null && !mcq.locked[mcq.currentIndex]) {
                      mcq.selectAnswer(mcq.currentIndex, selection);
                    }
                    mcq.nextQuestion();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navChevron({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0x1AFFFFFF) // frosted white 10%
              : const Color(0x0DFFFFFF), // frosted white 5%
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? const Color(0x20FFFFFF) // subtle white border
                : const Color(0x10FFFFFF),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? _ExamColors.textMuted : _ExamColors.textDim.withValues(alpha: 0.5),
        ),
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: 0.75,
          expand: false,
          builder: (_, scrollController) {
            return Container(
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
                          bgColor = _ExamColors.amber.withValues(alpha: 0.15);
                          textColor = _ExamColors.amber;
                          border = Border.all(color: _ExamColors.amber.withValues(alpha: 0.4));
                        } else if (isAnswered) {
                          bgColor = _ExamColors.emeraldDim;
                          textColor = _ExamColors.emerald;
                          border = Border.all(color: _ExamColors.emerald.withValues(alpha: 0.6), width: 1.5);
                        } else {
                          bgColor = _ExamColors.surface;
                          textColor = _ExamColors.textMuted;
                          border = Border.all(color: _ExamColors.border);
                        }

                        return GestureDetector(
                          onTap: () {
                            // Save current selection before jumping
                            final selection = _selections[mcq.currentIndex];
                            if (selection != null && !mcq.locked[mcq.currentIndex]) {
                              mcq.selectAnswer(mcq.currentIndex, selection);
                            }
                            mcq.goToQuestion(i);
                            Navigator.pop(sheetCtx);
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
            );
          },
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
  final unanswered = mcq.totalQuestions - mcq.answeredCount;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF161616),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _ExamColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.send_rounded, size: 18, color: _ExamColors.emerald),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submit exam?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _ExamColors.text)),
                      SizedBox(height: 2),
                      Text("This action can't be undone",
                          style: TextStyle(fontSize: 12, color: _ExamColors.textDim)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Stat cards: Answered / Locked
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: 'Answered',
                    value: mcq.answeredCount,
                    total: mcq.totalQuestions,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    label: 'Locked',
                    value: mcq.lockedCount,
                    total: mcq.totalQuestions,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Flagged row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark_rounded, size: 15, color: _ExamColors.amber),
                      const SizedBox(width: 6),
                      const Text('Flagged for review',
                          style: TextStyle(fontSize: 13, color: _ExamColors.textMuted)),
                    ],
                  ),
                  Text('${mcq.markedForReview.length}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ExamColors.text)),
                ],
              ),
            ),

            // Tab-switch warning (only if > 0)
            if (_tabSwitches > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _ExamColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _ExamColors.amber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: _ExamColors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, color: _ExamColors.amber, height: 1.4),
                          children: [
                            const TextSpan(text: 'Tab switches detected: '),
                            TextSpan(
                              text: '$_tabSwitches',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const TextSpan(text: ' — this may be flagged for review'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Unanswered consequence note
            if (unanswered > 0) ...[
              const SizedBox(height: 14),
              Text(
                '$unanswered question${unanswered == 1 ? '' : 's'} unanswered and will be marked incorrect.',
                style: const TextStyle(fontSize: 12, color: _ExamColors.textDim, height: 1.4),
              ),
            ],

            const SizedBox(height: 18),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ExamColors.textMuted,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _submitExam(mcq);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ExamColors.emerald,
                      foregroundColor: const Color(0xFF173404),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _statCard({required String label, required int value, required int total}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _ExamColors.textDim)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: _ExamColors.text),
              children: [
                TextSpan(text: '$value'),
                TextSpan(
                  text: '/$total',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _ExamColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
