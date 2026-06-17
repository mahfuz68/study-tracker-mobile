import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mcq_provider.dart';
import '../../providers/navigation_controller.dart';

class McqSetupScreen extends StatefulWidget {
  const McqSetupScreen({super.key});

  @override
  State<McqSetupScreen> createState() => _McqSetupScreenState();
}

class _McqSetupScreenState extends State<McqSetupScreen> {
  int _questionCount = 10;
  bool _requestApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mcq = context.read<McqProvider>();
      mcq.resetExam();
      mcq.loadSubjects();
      _applyRequest();
    });
  }

  void _applyRequest() {
    if (_requestApplied) return;
    final request =
        context.read<NavigationController>().pendingMcq;
    if (request != null) {
      if (request.subject != null) {
        context.read<McqProvider>().selectSubject(request.subject!);
      }
      if (request.topic != null) {
        context.read<McqProvider>().selectTopic(request.topic!);
      }
      context.read<NavigationController>().consumeMcqRequest();
      _requestApplied = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exam Setup',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              const SizedBox(height: 6),
              const Text(
                'Configure your MCQ exam parameters below.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _SubjectDropdown(),
              const SizedBox(height: 12),
              _TopicDropdown(),
              const SizedBox(height: 28),
              const Text('Number of Questions',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _StepperCounter(
                value: _questionCount,
                min: 1,
                max: 50,
                step: 1,
                onChanged: (v) => setState(() => _questionCount = v),
              ),
              const SizedBox(height: 32),
              Consumer<McqProvider>(
                builder: (context, mcq, _) {
                  return _StartExamButton(
                    loading: mcq.isLoading,
                    onPressed: () => _startExam(context),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startExam(BuildContext context) async {
    final mcq = context.read<McqProvider>();
    await mcq.startExam(
      subject: mcq.selectedSubject,
      topic: mcq.selectedTopic,
      limit: _questionCount,
    );
    if (mcq.error == null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _McqExamScreen()),
      );
    }
  }
}

/// Dropdown wrapper that mirrors the old _IconField look — leading icon +
/// bordered container with a DropdownButton inside.
class _DropdownShell extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _DropdownShell({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Subject selector backed by [McqProvider.subjects].
class _SubjectDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<McqProvider>(
      builder: (context, mcq, _) {
        return _DropdownShell(
          icon: Icons.menu_book_outlined,
          child: DropdownButton<String>(
            value: mcq.selectedSubject,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppTheme.card,
            icon: Icon(
              mcq.subjectsLoading
                  ? Icons.hourglass_bottom
                  : Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            hint: const Text(
              'Subject (optional)',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
            items: mcq.subjects
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                .toList(),
            onChanged: (value) {
              mcq.selectSubject(value);
            },
          ),
        );
      },
    );
  }
}

/// Topic selector backed by [McqProvider.topics].
class _TopicDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<McqProvider>(
      builder: (context, mcq, _) {
        return _DropdownShell(
          icon: Icons.folder_outlined,
          child: DropdownButton<String>(
            value: mcq.selectedTopic,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppTheme.card,
            icon: Icon(
              mcq.topicsLoading
                  ? Icons.hourglass_bottom
                  : Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            hint: Text(
              mcq.selectedSubject == null
                  ? 'Select a subject first'
                  : 'Topic (optional)',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
            items: mcq.topics
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    ))
                .toList(),
            onChanged: mcq.selectedSubject == null
                ? null
                : (value) {
                    mcq.selectTopic(value);
                  },
          ),
        );
      },
    );
  }
}

/// Joined minus / number / plus counter.
class _StepperCounter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _StepperCounter({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged((value - step).clamp(min, max)),
            radius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            showRightBorder: true,
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppTheme.cardHigher),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged((value + step).clamp(min, max)),
            radius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            showLeftBorder: true,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final BorderRadius radius;
  final bool showRightBorder;
  final bool showLeftBorder;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.radius,
    this.showRightBorder = false,
    this.showLeftBorder = false,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        borderRadius: widget.radius,
        child: AnimatedScale(
          scale: _down ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.cardHigher,
              borderRadius: widget.radius,
              border: Border(
                right: widget.showRightBorder
                    ? const BorderSide(color: AppTheme.border, width: 0.5)
                    : BorderSide.none,
                left: widget.showLeftBorder
                    ? const BorderSide(color: AppTheme.border, width: 0.5)
                    : BorderSide.none,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.enabled
                  ? AppTheme.textPrimary
                  : AppTheme.textTertiary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Green-gradient "Start Exam" button with glow + press scale.
class _StartExamButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _StartExamButton({required this.loading, required this.onPressed});

  @override
  State<_StartExamButton> createState() => _StartExamButtonState();
}

class _StartExamButtonState extends State<_StartExamButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppTheme.startExamGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : const Text(
                  'Start Exam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

class _McqExamScreen extends StatefulWidget {
  const _McqExamScreen();

  @override
  State<_McqExamScreen> createState() => _McqExamScreenState();
}

class _McqExamScreenState extends State<_McqExamScreen> {
  Timer? _globalTimer;
  int _totalSecondsRemaining = 0;

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _McqResultScreen()),
      );
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
        appBar: AppBar(
          title: Consumer<McqProvider>(
            builder: (_, mcq, __) => Text(
              'Q${mcq.currentIndex + 1}/${mcq.totalQuestions}',
            ),
          ),
          actions: [
            Consumer<McqProvider>(
              builder: (_, mcq, __) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${mcq.answeredCount}/${mcq.totalQuestions}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.grid_view, size: 20),
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
                        if (q.subject.isNotEmpty || q.topic.isNotEmpty)
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
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
                                          fontSize: 13,
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
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isLocked)
                                      const Icon(Icons.lock,
                                          color: AppTheme.textSecondary, size: 16),
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
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
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
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
            _navButton(
              icon: Icons.chevron_left,
              enabled: mcq.currentIndex > 0,
              onTap: mcq.previousQuestion,
            ),
            const SizedBox(width: 4),
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
                mcq.markedForReview.contains(mcq.currentIndex) ? 'Flagged' : 'Review',
                style: TextStyle(
                  color: mcq.markedForReview.contains(mcq.currentIndex)
                      ? AppTheme.warningAmber
                      : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const Spacer(),
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
    final skippedCount = mcq.totalQuestions - mcq.answeredCount - mcq.lockedCount;
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
              const SizedBox(height: 16),
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
              if (skippedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      '$skippedCount question(s) skipped',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  void _showSubmitDialog(McqProvider mcq) {
    final skipped = mcq.totalQuestions - mcq.answeredCount - mcq.lockedCount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _submitRow('Answered', '${mcq.answeredCount}/${mcq.totalQuestions}',
                AppTheme.primaryGreen),
            const SizedBox(height: 6),
            _submitRow('Skipped', '$skipped', AppTheme.warningAmber),
            const SizedBox(height: 6),
            _submitRow('Flagged', '${mcq.markedForReview.length}',
                AppTheme.warningAmber),
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

  Widget _submitRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _McqResultScreen extends StatelessWidget {
  const _McqResultScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<McqProvider>(
        builder: (context, mcq, _) {
          final attempt = mcq.lastAttempt;
          if (attempt == null) {
            return const Center(child: Text('No results'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: attempt.passed
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: attempt.passed
                        ? AppTheme.successGreen.withOpacity(0.3)
                        : AppTheme.errorRed.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      attempt.passed
                          ? Icons.emoji_events
                          : Icons.replay,
                      color: attempt.passed
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      attempt.passed ? 'Passed!' : 'Failed',
                      style: TextStyle(
                        color: attempt.passed
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${attempt.score.toStringAsFixed(1)} (Cut: ${attempt.cutMark.toStringAsFixed(1)})',
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
                  _resultItem('Total', '${attempt.total}',
                      AppTheme.textPrimary),
                  _resultItem('Correct', '${attempt.correct}',
                      AppTheme.successGreen),
                  _resultItem('Wrong', '${attempt.wrong}',
                      AppTheme.errorRed),
                  _resultItem('Skipped', '${attempt.skipped}',
                      AppTheme.warningAmber),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to MainScaffold, then reset the exam and
                    // switch to the MCQ tab.
                    Navigator.popUntil(context, (route) => route.isFirst);
                    context.read<McqProvider>().resetExam();
                    context.read<NavigationController>().switchTo(2); // MCQ tab
                  },
                  child: const Text('Take Another Exam'),
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

  Widget _resultItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
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