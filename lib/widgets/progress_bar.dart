import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Animated progress bar with a gradient fill that tweens to its target
/// value over ~400ms. Matches the spec's "Animated progress bar" pattern.
class ProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;

  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: AppTheme.border),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient:
                          color != null ? null : AppTheme.progressGradient,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
