import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/puzzle_question.dart';
import '../../providers/puzzle_provider.dart';

class PuzzlePlayerScreen extends StatefulWidget {
  final String puzzleId;
  const PuzzlePlayerScreen({super.key, required this.puzzleId});

  @override
  State<PuzzlePlayerScreen> createState() => _PuzzlePlayerScreenState();
}

class _PuzzlePlayerScreenState extends State<PuzzlePlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleProvider>().loadPuzzleDetail(widget.puzzleId);
    });
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Puzzle?'),
        content: const Text(
          'Your progress on this puzzle will be lost.',
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
      appBar: AppBar(title: const Text('Puzzle')),
      body: Consumer<PuzzleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final puzzle = provider.currentPuzzle;
          if (puzzle == null) {
            return const Center(
              child: Text('Puzzle not found',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final attempt = provider.lastAttempt;
          if (attempt != null) {
            return _buildResults(provider, attempt);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildScenarioCard(puzzle),
              const SizedBox(height: 12),
              ...puzzle.extras.map((e) => _buildExtra(e)),
              const SizedBox(height: 12),
              ...puzzle.questions.map((q) => _buildQuestionCard(provider, q)),
              const SizedBox(height: 20),
              _buildSubmitButton(provider),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildScenarioCard(dynamic puzzle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(puzzle.title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(puzzle.scenarioParagraph,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildExtra(dynamic extra) {
    if (extra.type == 'TABLE') {
      final headers = List<String>.from(extra.content['headers'] ?? []);
      final rows = (extra.content['rows'] as List<dynamic>?)
              ?.map((r) => List<String>.from(r))
              .toList() ?? [];
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Table(
          border: TableBorder.all(color: AppTheme.borderColor, width: 0.5),
          children: [
            if (headers.isNotEmpty)
              TableRow(
                children: headers.map((h) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(h,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                )).toList(),
              ),
            ...rows.map((row) => TableRow(
              children: row.map((c) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(c,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              )).toList(),
            )),
          ],
        ),
      );
    }

    final items = List<String>.from(extra.content['items'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBlue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clues',
              style: TextStyle(
                  color: AppTheme.infoBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(color: AppTheme.infoBlue)),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(PuzzleProvider provider, dynamic q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q${q.position}. ${q.text}',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...q.options.map<Widget>((opt) {
            final selected = provider.selectedOptions[q.id] == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => provider.selectOption(q.id, opt.id),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryGreen.withOpacity(0.15)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryGreen
                              : AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(opt.text,
                            style: const TextStyle(
                                color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(PuzzleProvider provider) {
    final hasAnswers = provider.selectedOptions.values.any((v) => v != null);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasAnswers ? () => _submit(provider) : null,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: const Text('Submit Answers', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildResults(PuzzleProvider provider, dynamic attempt) {
    final puzzle = provider.currentPuzzle;
    final answers = attempt.answers ?? [];
    final questions = puzzle?.questions ?? [];

    // Build a map of questionId -> selectedOptionId from attempt answers
    final answerMap = {for (final a in answers) a.questionId: a.selectedOptionId};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Score header ──
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: attempt.passed == true
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
              color: attempt.passed == true
                  ? AppTheme.successGreen.withOpacity(0.3)
                  : AppTheme.errorRed.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                attempt.passed == true
                    ? Icons.emoji_events
                    : Icons.sentiment_dissatisfied,
                color: attempt.passed == true
                    ? AppTheme.successGreen
                    : AppTheme.errorRed,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                attempt.passed == true ? 'Congratulations!' : 'Not passed',
                style: TextStyle(
                  color: attempt.passed == true
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${attempt.score?.toStringAsFixed(2) ?? "N/A"} · ${attempt.correct}/${attempt.total} correct',
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
            _statBox('Total', '${attempt.total}', AppTheme.textPrimary),
            _statBox('Correct', '${attempt.correct}', AppTheme.successGreen),
            _statBox('Wrong', '${attempt.wrong}', AppTheme.errorRed),
            _statBox('Skipped', '${attempt.skipped}', AppTheme.warningAmber),
          ],
        ),
        const SizedBox(height: 28),

        // ── Answer Review header ──
        const Text(
          'Answer Review',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),

        // ── Per-question review ──
        ...List.generate(questions.length, (index) {
          final q = questions[index];
          final selectedOptionId = answerMap[q.id];
          final isSkipped = selectedOptionId == null;

          // Find the selected option
          PuzzleOption? selectedOpt;
          for (final opt in q.options) {
            if (opt.id == selectedOptionId) selectedOpt = opt;
          }

          final isCorrect = selectedOpt?.isCorrect ?? false;

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
                    Expanded(
                      child: Text(
                        'Q${q.position}. ${q.text}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Options list
                ...q.options.map((opt) {
                  final isSelected = opt.id == selectedOptionId;
                  final isAnswer = opt.isCorrect;

                  Color dotColor;
                  if (isAnswer) {
                    dotColor = AppTheme.successGreen;
                  } else if (isSelected && !isCorrect) {
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
                            '${opt.label}. ${opt.text}',
                            style: TextStyle(
                              color: isSelected || isAnswer
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontWeight: isSelected || isAnswer
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isAnswer)
                          const Icon(Icons.check,
                              color: AppTheme.successGreen, size: 16),
                        if (isSelected && !isCorrect)
                          const Icon(Icons.close,
                              color: AppTheme.errorRed, size: 16),
                      ],
                    ),
                  );
                }),

                // Explanation
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
        }),

        const SizedBox(height: 20),

        // ── Action buttons ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.read<PuzzleProvider>().reset();
              context
                  .read<PuzzleProvider>()
                  .loadPuzzleDetail(widget.puzzleId);
            },
            child: const Text('Retry', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to List'),
          ),
        ),
        const SizedBox(height: 32),
      ],
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

  void _submit(PuzzleProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await provider.submitPuzzle(widget.puzzleId);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
    }
  }
}
