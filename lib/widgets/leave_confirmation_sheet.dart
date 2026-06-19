import 'package:flutter/material.dart';

/// Shared leave-confirmation bottom sheet used by MCQ exam and puzzle
/// player screens. Matches the app's dark / glassmorphic exit-sheet
/// language established in [MainScaffold].
///
/// Call via [showLeaveSheet] and await the result:
/// ```dart
/// final leave = await showLeaveSheet(
///   context,
///   icon: Icons.menu_book_rounded,
///   title: 'Leave Exam?',
///   subtitle: 'You have unanswered questions.\nYour progress will be lost.',
///   confirmLabel: 'Leave',
/// );
/// if (leave) Navigator.pop(context);
/// ```
Future<bool> showLeaveSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  String confirmLabel = 'Leave',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black54,
    builder: (_) => _LeaveSheet(
      icon: icon,
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
    ),
  );
  return result ?? false;
}

// ── Internal sheet widget ──────────────────────────────────────

class _LeaveSheet extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String confirmLabel;

  const _LeaveSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
  });

  @override
  State<_LeaveSheet> createState() => _LeaveSheetState();
}

class _LeaveSheetState extends State<_LeaveSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  // ── Palette ───────────────────────────────────────────────
  static const _bg = Color(0xFF0E0E1C);
  static const _card = Color(0xFF1C1C32);
  static const _danger = Color(0xFFFF5A5A);
  static const _muted = Color(0xFFA0A0C0);
  static const _text = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: _card, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              const SizedBox(height: 28),
              _animatedIcon(),
              const SizedBox(height: 24),
              _titleText(),
              const SizedBox(height: 10),
              _subtitleText(),
              const SizedBox(height: 32),
              _confirmButton(),
              const SizedBox(height: 10),
              _stayButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drag handle ───────────────────────────────────────────

  Widget _dragHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: _muted.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Animated icon with pulse glow ─────────────────────────

  Widget _animatedIcon() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse glow
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final opacity = 0.15 + 0.12 * _pulseCtrl.value;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _danger.withValues(alpha: opacity),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              );
            },
          ),
          // Icon circle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_danger, _danger.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _danger.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  // ── Title ─────────────────────────────────────────────────

  Widget _titleText() {
    return Text(
      widget.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    );
  }

  // ── Subtitle ──────────────────────────────────────────────

  Widget _subtitleText() {
    return Text(
      widget.subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _muted.withValues(alpha: 0.85),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
    );
  }

  // ── Confirm (Leave) button — red ──────────────────────────

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: _danger,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          widget.confirmLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  // ── Stay button — ghost ───────────────────────────────────

  Widget _stayButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: () => Navigator.pop(context, false),
        style: TextButton.styleFrom(
          foregroundColor: _muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Keep Going',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
