import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/navigation_controller.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/mcq/mcq_setup_screen.dart';
import '../screens/puzzles/puzzle_list_screen.dart';

/// Persistent main shell with bottom navigation.
///
/// The four primary tabs (Dashboard, Progress, MCQ, Puzzles) are kept
/// alive in an [IndexedStack] so switching tabs does not rebuild their
/// state and does not push a new route. The system back button is left
/// to the parent [Navigator] — sub-pages (Profile, Admin, etc.) are
/// pushed on top of this shell, so pressing back pops them and only
/// exits the app when there is nothing left to pop.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _navItems = <_NavItem>[
    _NavItem(
      icon: Icons.calendar_today_rounded,
      outlineIcon: Icons.calendar_today_outlined,
      label: 'Schedule',
    ),
    _NavItem(
      icon: Icons.insights_rounded,
      outlineIcon: Icons.show_chart_rounded,
      label: 'Progress',
    ),
    _NavItem(
      icon: Icons.checklist_rounded,
      outlineIcon: Icons.checklist_outlined,
      label: 'MCQ',
    ),
    _NavItem(
      icon: Icons.extension_rounded,
      outlineIcon: Icons.extension_outlined,
      label: 'Puzzles',
    ),
  ];

  late final List<Widget> _pages = const [
    DashboardScreen(),
    ProgressScreen(),
    McqSetupScreen(),
    PuzzleListScreen(),
  ];

  /// Show the exit confirmation bottom sheet. Returns true if the user
  /// confirmed they want to exit.
  Future<bool> _onWillPop() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ExitBottomSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          bottom: false,
          child: IndexedStack(
            index: nav.tabIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: _buildBottomNav(nav),
      ),
    );
  }

  Widget _buildBottomNav(NavigationController nav) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.navBarBg,
            border: Border(top: BorderSide(color: AppTheme.navBarBorder)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  final isActive = index == nav.tabIndex;
                  return _NavIconButton(
                    icon: isActive
                        ? _navItems[index].icon
                        : _navItems[index].outlineIcon,
                    isActive: isActive,
                    onTap: () => nav.switchTo(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
  });
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primaryGreen.withOpacity(0.08),
        highlightColor: AppTheme.primaryGreen.withOpacity(0.04),
        child: SizedBox(
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  icon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: isActive
                      ? AppTheme.primaryGreen
                      : AppTheme.textSecondary,
                ),
              ),
              Positioned(
                bottom: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 4 : 0,
                  height: isActive ? 4 : 0,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── EXIT BOTTOM SHEET ──────────────────────────────────────────
// Design spec: bottom-sheet style, streak-orbit animation, heavy
// title / light body, stacked full-width buttons (green "Keep going"
// on top, ghost "Exit" below).
// Palette: bg #0E0E1C · card #1C1C32 · brand #00C896 · red #FF5A5A
// muted #A0A0C0

class _ExitBottomSheet extends StatefulWidget {
  const _ExitBottomSheet();

  @override
  State<_ExitBottomSheet> createState() => _ExitBottomSheetState();
}

class _ExitBottomSheetState extends State<_ExitBottomSheet>
    with TickerProviderStateMixin {
  // Orbit / streak animation: two glowing arcs that orbit the icon.
  late final AnimationController _orbitCtrl;
  // Soft pulsing glow behind the icon.
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
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
          color: Color(0xFF0E0E1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF1C1C32), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── drag handle ──────────────────────────────
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFA0A0C0).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // ── orbit / streak icon ─────────────────────
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse glow
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final opacity =
                            0.18 + 0.14 * _pulseCtrl.value;
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C896)
                                    .withOpacity(opacity),
                                blurRadius: 36,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Orbit arcs
                    AnimatedBuilder(
                      animation: _orbitCtrl,
                      builder: (_, __) {
                        return CustomPaint(
                          size: const Size(100, 100),
                          painter: _OrbitPainter(_orbitCtrl.value),
                        );
                      },
                    ),
                    // Central icon
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C896), Color(0xFF00996B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C896).withOpacity(0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── title ───────────────────────────────────
              const Text(
                'Your streak is on fire!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF0F0F0),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // ── body ────────────────────────────────────
              Text(
                'Don\'t let your study streak fade away.\nCome back tomorrow to keep it going.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFA0A0C0).withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),

              // ── "Keep going" button (primary green) ─────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Keep Going',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── "Exit" button (ghost) ───────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA0A0C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ORBIT PAINTER ──────────────────────────────────────────────
// Draws two glowing arcs that rotate around a centre point, giving
// a "study streak / orbit" feel.
class _OrbitPainter extends CustomPainter {
  final double progress; // 0..1, driven by AnimationController
  _OrbitPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 4;

    // Arc 1 — full-length arc
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 0.7,
        colors: const [
          Color(0x0000C896),
          Color(0xFF00C896),
          Color(0x0000C896),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      progress * 2 * pi,
      pi * 0.7,
      false,
      paint1,
    );

    // Arc 2 — shorter trailing arc
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 0.4,
        colors: const [
          Color(0x0000C896),
          Color(0x8800C896),
          Color(0x0000C896),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      progress * 2 * pi + pi,
      pi * 0.4,
      false,
      paint2,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress;
}