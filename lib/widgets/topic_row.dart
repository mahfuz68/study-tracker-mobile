import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/topic.dart';

/// Topic card matching the spec:
///   - 16 radius, 1A1A1A card, 0.5 border (turns green @ 30% on complete)
///   - 22×22 animated checkbox on the left
///   - Subject label in green above topic name
///   - Duration badge on the right
///
/// One-way lock: once [isComplete] is true, the entire row becomes
/// non-interactive ([IgnorePointer] around the InkWell) and is visually
/// greyed out with strikethrough text. Tapping a completed row does
/// nothing — completion is permanent.
class TopicRow extends StatelessWidget {
  final Topic topic;
  final bool isComplete;
  final int? examMark;
  final bool hasExam;
  final VoidCallback onToggle;
  final VoidCallback? onExamTap;

  const TopicRow({
    super.key,
    required this.topic,
    required this.isComplete,
    this.examMark,
    this.hasExam = false,
    required this.onToggle,
    this.onExamTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? AppTheme.primaryGreen.withOpacity(0.4)
              : AppTheme.border,
          width: 0.5,
        ),
      ),
      child: IgnorePointer(
        // Once completed, the row is locked. The whole InkWell becomes
        // a no-op — taps are absorbed and the visual feedback is
        // suppressed. The exam badge (if shown) is also disabled.
        ignoring: isComplete,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isComplete ? null : onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Opacity(
              // Slight dim of the whole row when complete, in addition
              // to the strikethrough on the title.
              opacity: isComplete ? 0.7 : 1.0,
              child: Row(
                children: [
                  // ── Animated checkbox ─────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppTheme.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isComplete
                            ? AppTheme.primaryGreen
                            : AppTheme.textTertiary.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: isComplete
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('checked'),
                              color: Colors.white,
                              size: 14,
                            )
                          : const SizedBox.shrink(key: ValueKey('unchecked')),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          topic.subject,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          topic.topic,
                          style: TextStyle(
                            color: isComplete
                                ? AppTheme.textPrimary.withOpacity(0.55)
                                : AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isComplete
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasExam || examMark != null) ...[
                    InkWell(
                      onTap: onExamTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: examMark != null
                              ? AppTheme.accentGold.withOpacity(0.15)
                              : AppTheme.infoBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          examMark != null ? '$examMark' : 'Exam',
                          style: TextStyle(
                            color: examMark != null
                                ? AppTheme.accentGold
                                : AppTheme.infoBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // MCQ exam button — always shown for every topic
                  // (not gated on hasExam). Tapping this starts an
                  // MCQ exam for this topic directly.
                  if (!isComplete) ...[
                    InkWell(
                      onTap: onExamTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.quiz_rounded,
                                size: 14, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            const Text(
                              'MCQ',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.cardHigher,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${topic.durationMin}m',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
