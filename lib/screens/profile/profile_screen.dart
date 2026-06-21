import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/auth_service.dart';

/// -------------------------------------------------------------------
/// Profile screen – dark, warm palette with a 7-segment streak ring
/// around the avatar.  Designed to reinforce motivation by showing
/// identity and consistency at a glance.
///
/// Visual spec (matches the JSX ProfileScreen reference):
///   bg  #090D0C · surface #111716 · surface2 #161E1C · border #222B28
///   emerald  #00C896 → #2ECC71 · danger  #FF4757
///   textPrimary  #F2F7F5 · textSecondary  #86A09A · textTertiary  #4D5B57
///
/// Typography: Space Grotesk (display) · Inter (body) · JetBrains Mono (data)
/// Layout:  cascading rise-in animation, max 420 px centred.
/// Signature:  the 7-segment arc ring is the one memorable element.
/// -------------------------------------------------------------------

// ── Colour palette ──────────────────────────────────────────────────
const _c = <String, Color>{
  'bg': Color(0xFF090D0C),
  'surface': Color(0xFF111716),
  'surface2': Color(0xFF161E1C),
  'border': Color(0xFF222B28),
  'emerald1': Color(0xFF00C896),
  'emerald2': Color(0xFF2ECC71),
  'danger': Color(0xFFFF4757),
  'textPrimary': Color(0xFFF2F7F5),
  'textSecondary': Color(0xFF86A09A),
  'textTertiary': Color(0xFF4D5B57),
};

Color get _bg => _c['bg']!;
Color get _surface => _c['surface']!;
Color get _surface2 => _c['surface2']!;
Color get _border => _c['border']!;
Color get _emerald1 => _c['emerald1']!;
// ignore: unused_element
Color get _emerald2 => _c['emerald2']!; // kept for completeness
Color get _danger => _c['danger']!;
Color get _textPrimary => _c['textPrimary']!;
Color get _textSecondary => _c['textSecondary']!;
Color get _textTertiary => _c['textTertiary']!;

// ── Typography helpers ──────────────────────────────────────────────
TextStyle _display(double size,
        {FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: weight, color: color ?? _textPrimary);

TextStyle _body(double size,
        {FontWeight weight = FontWeight.w400, Color? color}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: weight, color: color ?? _textPrimary);

TextStyle _mono(double size,
        {FontWeight weight = FontWeight.w500, Color? color, double letterSpacing = 0}) =>
    GoogleFonts.jetBrainsMono(
        fontSize: size, fontWeight: weight, color: color ?? _textPrimary, letterSpacing: letterSpacing);

// ── Streak-ring painter ─────────────────────────────────────────────
/// Draws N filled-or-empty arc segments around a circle, like a
/// progress ring for days of the week.
class _StreakPainter extends CustomPainter {
  final int total;
  final int filled;
  final double radius;
  final double gapDeg;

  _StreakPainter({
    this.total = 7,
    this.filled = 0,
    this.radius = 54,
    this.gapDeg = 9,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final segAngle = 360 / total;
    const strokeW = 6.0;

    for (int i = 0; i < total; i++) {
      final startDeg = -90 + i * segAngle + gapDeg / 2;
      final endDeg = -90 + (i + 1) * segAngle - gapDeg / 2;
      final startRad = startDeg * pi / 180;
      final sweepRad = (endDeg - startDeg) * pi / 180;

      final isFilled = i < filled;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      if (isFilled) {
        // Gradient for filled segments
        final gRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
        paint.shader = const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(gRect);
      } else {
        paint.color = _border;
      }

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startRad,
        sweepRad,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StreakPainter old) =>
      old.filled != filled || old.total != total;
}

// ── Password strength ───────────────────────────────────────────────
({int score, String label, Color color}) _strength(String pw) {
  if (pw.isEmpty) return (score: 0, label: '', color: _danger);
  int score = 0;
  if (pw.length >= 8) score++;
  if (pw.contains(RegExp(r'[A-Z]'))) score++;
  if (pw.contains(RegExp(r'[0-9]'))) score++;
  if (pw.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
  const meta = [
    (label: 'Too short', color: Color(0xFFFF4757)),
    (label: 'Weak', color: Color(0xFFFF4757)),
    (label: 'Fair', color: Color(0xFFF4A93B)),
    (label: 'Good', color: Color(0xFF00C896)),
    (label: 'Strong', color: Color(0xFF2ECC71)),
  ];
  return (score: score, label: meta[score].label, color: meta[score].color);
}

// ── Password field widget ───────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool show;
  final VoidCallback onToggleShow;

  const _PasswordField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.show,
    required this.onToggleShow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        obscureText: !show,
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        ),
        onChanged: onChanged,
        style: _body(15, color: _textPrimary),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: _body(14, color: _textTertiary),
          filled: true,
          fillColor: _surface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5),
          ),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              size: 16, color: _textTertiary),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 16,
              color: _textTertiary,
            ),
            onPressed: onToggleShow,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Password form state
  bool _open = false;
  final _currentPw = ValueNotifier('');
  final _newPw = ValueNotifier('');
  final _confirmPw = ValueNotifier('');
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _changingPw = false;

  // For staggered rise-in, track whether we've animated yet
  late final AnimationController _staggerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staggerCtrl.forward();
      context.read<ProgressProvider>().loadStudyPlan();
    });
  }

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _currentPw.value.isNotEmpty &&
      _newPw.value.length >= 8 &&
      _newPw.value == _confirmPw.value;

  void _changePassword() async {
    final current = _currentPw.value;
    final next = _newPw.value;
    final confirm = _confirmPw.value;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }
    if (next != confirm) {
      _showSnack('Passwords do not match');
      return;
    }
    if (next.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }

    setState(() => _changingPw = true);
    try {
      await AuthService().changePassword(current, next);
      if (!mounted) return;
      _currentPw.value = '';
      _newPw.value = '';
      _confirmPw.value = '';
      setState(() {
        _open = false;
        _changingPw = false;
      });
      _showSnack('Password updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _changingPw = false);
      _showSnack(
          'Failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: _body(14, color: _textPrimary)),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmLogout(AuthProvider auth) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LogoutBottomSheet(),
    );
    if (ok != true || !mounted) return;
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // ── top bar ─────────────────────────────────
                _AnimatedTile(
                  delay: 0.0,
                  ctrl: _staggerCtrl,
                  child: _buildTopBar(),
                ),
                // ── hero ───────────────────────────────────
                _AnimatedTile(
                  delay: 0.08,
                  ctrl: _staggerCtrl,
                  child: _buildHero(user, progress.studyPlan.isNotEmpty ? _computeStreak(progress) : 0),
                ),
                const SizedBox(height: 20),
                // ── stat chips ──────────────────────────────
                _AnimatedTile(
                  delay: 0.16,
                  ctrl: _staggerCtrl,
                  child: _buildStats(user, progress),
                ),
                const SizedBox(height: 20),
                // ── account info ────────────────────────────
                _AnimatedTile(
                  delay: 0.24,
                  ctrl: _staggerCtrl,
                  child: _buildAccountInfo(user),
                ),
                const SizedBox(height: 14),
                // ── security ────────────────────────────────
                _AnimatedTile(
                  delay: 0.32,
                  ctrl: _staggerCtrl,
                  child: _buildSecurity(),
                ),
                const SizedBox(height: 28),
                // ── danger zone ─────────────────────────────
                _AnimatedTile(
                  delay: 0.40,
                  ctrl: _staggerCtrl,
                  child: _buildDangerZone(auth),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _iconButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
          const Spacer(),
          Text('Profile', style: _display(19, weight: FontWeight.w600)),
          const Spacer(),
          _iconButton(Icons.edit_rounded, () {
            // TODO: edit profile
          }),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: _textSecondary),
        onPressed: onTap,
      ),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────────
  Widget _buildHero(User? user, int streak) {
    // Derive initials
    final name = user?.name ?? '';
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name.substring(0, min(2, name.length)).toUpperCase()
            : 'U';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // glow behind avatar
        Positioned(
          top: 20,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _emerald1.withOpacity(0.13),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 28),
            // avatar + streak ring
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _StreakPainter(
                      total: 7,
                      filled: streak,
                      radius: 54,
                      gapDeg: 9,
                    ),
                  ),
                  // avatar circle
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C896), Color(0xFF128A6E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: _display(30,
                          weight: FontWeight.bold, color: const Color(0xFF06120F)),
                    ),
                  ),
                  // shield badge
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A2A0A),
                        shape: BoxShape.circle,
                        border: Border.all(color: _bg, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 14,
                        color: Color(0xFFE2A33D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: _display(22, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: _body(14, color: _textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '$streak OF 7 DAYS · THIS WEEK',
              style: _mono(11,
                  weight: FontWeight.w600, color: _textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  /// Compute consecutive days fully completed, scanning backwards.
  static int _computeStreak(ProgressProvider progress) {
    final plan = progress.studyPlan;
    if (plan.isEmpty) return 0;
    int streak = 0;
    for (int i = plan.length - 1; i >= 0; i--) {
      final day = plan[i];
      final topicIds = day.topics.map((t) => t.id).toSet();
      final doneCount =
          progress.allProgress.where((p) => topicIds.contains(p.topicId) && p.isComplete).length;
      if (doneCount >= day.topics.length && day.topics.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── STAT CHIPS ────────────────────────────────────────────────────
  Widget _buildStats(User? user, ProgressProvider progress) {
    final streak = _computeStreak(progress);
    final topicsDone = progress.totalCompleted;
    final memberSince = _fmtDate(user?.createdAt);

    final chips = [
      _StatChipData(
        icon: Icons.local_fire_department_rounded,
        value: '$streak',
        label: 'day streak',
      ),
      _StatChipData(
        icon: Icons.task_alt_rounded,
        value: '$topicsDone',
        label: 'topics done',
      ),
      _StatChipData(
        icon: Icons.calendar_month_rounded,
        value: memberSince.isNotEmpty ? memberSince : 'N/A',
        label: 'member since',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _StatChip(data: chips[0])),
          const SizedBox(width: 10),
          Expanded(child: _StatChip(data: chips[1])),
          const SizedBox(width: 10),
          Expanded(child: _StatChip(data: chips[2])),
        ],
      ),
    );
  }

  // ── ACCOUNT INFO ──────────────────────────────────────────────────
  Widget _buildAccountInfo(User? user) {
    final rows = [
      _InfoRowData(Icons.person_outline_rounded, 'Name', user?.name ?? ''),
      _InfoRowData(Icons.email_outlined, 'Email', user?.email ?? ''),
      _InfoRowData(Icons.badge_outlined, 'Role', user?.role ?? ''),
      _InfoRowData(
          Icons.calendar_today_outlined, 'Member since', _fmtDate(user?.createdAt)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account info', style: _display(15, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...List.generate(rows.length, (i) {
              final r = rows[i];
              return Container(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12, bottom: 12),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(
                          top: BorderSide(color: _border, width: 1),
                        ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(r.icon, size: 14, color: _textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.label,
                          style: _body(13, color: _textSecondary)),
                    ),
                    Text(r.value, style: _body(14, weight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── SECURITY / CHANGE PASSWORD ────────────────────────────────────
  Widget _buildSecurity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: _open ? Radius.zero : const Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.lock_outline_rounded,
                          size: 14, color: Color(0xFF86A09A)),
                    ),
                    const SizedBox(width: 12),
                    Text('Change password',
                        style: _body(14, weight: FontWeight.w500)),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.expand_more_rounded,
                          size: 17, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildPasswordForm(),
              crossFadeState: _open
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    final strength = _strength(_newPw.value);
    final mismatch = _confirmPw.value.isNotEmpty && _newPw.value != _confirmPw.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _PasswordField(
            label: 'Current password',
            value: _currentPw.value,
            onChanged: (v) => _currentPw.value = v,
            show: _showCurrent,
            onToggleShow: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'New password',
            value: _newPw.value,
            onChanged: (v) => _newPw.value = v,
            show: _showNext,
            onToggleShow: () => setState(() => _showNext = !_showNext),
          ),
          // strength meter
          if (_newPw.value.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(4, (i) {
                      final isActive = i < strength.score;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: isActive ? strength.color : _border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strength.label,
                  style: _mono(10, color: strength.color, weight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _PasswordField(
            label: 'Confirm new password',
            value: _confirmPw.value,
            onChanged: (v) => _confirmPw.value = v,
            show: _showConfirm,
            onToggleShow: () => setState(() => _showConfirm = !_showConfirm),
          ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 12, color: Color(0xFFFF4757)),
                  const SizedBox(width: 4),
                  Text("Passwords don't match",
                      style: _body(11, color: _danger)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canSubmit && !_changingPw ? _changePassword : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSubmit ? _emerald1 : _surface2,
                disabledBackgroundColor: _surface2,
                foregroundColor: _canSubmit ? const Color(0xFF06120F) : _textTertiary,
                disabledForegroundColor: _textTertiary,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _changingPw
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF06120F)),
                    )
                  : Text('Update password',
                      style: _display(14, weight: FontWeight.w600,
                          color: _canSubmit ? const Color(0xFF06120F) : _textTertiary)),
            ),
          ),
        ],
      ),
    );
  }

  // ── DANGER ZONE ───────────────────────────────────────────────────
  Widget _buildDangerZone(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'DANGER ZONE',
            style: _mono(10,
                weight: FontWeight.w600,
                color: _textTertiary,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(auth),
              icon: const Icon(Icons.logout_rounded, size: 16,
                  color: Color(0xFFFF4757)),
              label: Text('Log out',
                  style: _body(14,
                      weight: FontWeight.w500, color: _danger)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: const Color(0xFFFF4757).withOpacity(0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Stat chip helper types ──────────────────────────────────────────
class _StatChipData {
  final IconData icon;
  final String value;
  final String label;
  _StatChipData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class _StatChip extends StatelessWidget {
  final _StatChipData data;
  const _StatChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(data.icon, size: 16, color: _emerald1),
          const SizedBox(height: 6),
          Text(data.value,
              style: _mono(15, weight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 2),
          Text(data.label,
              style: _body(10, color: _textTertiary)),
        ],
      ),
    );
  }
}

// ── Info row helper type ────────────────────────────────────────────
class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  _InfoRowData(this.icon, this.label, this.value);
}

// ── Staggered entrance tile ─────────────────────────────────────────
class _AnimatedTile extends StatelessWidget {
  final double delay;
  final AnimationController ctrl;
  final Widget child;

  const _AnimatedTile({
    required this.delay,
    required this.ctrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final elapsed = ctrl.value; // 0..1
        final t = ((elapsed - delay) / 0.6).clamp(0.0, 1.0);
        // ease-out cubic
        final eased = 1.0 - pow(1.0 - t, 3);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 12 * (1.0 - eased)),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOGOUT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════
// Design spec:  bottom-sheet style, orbit animation, heavy title / light
// body, stacked full-width buttons.
// Palette:  bg #0E0E1C · card #1C1C32 · brand #00C896 · red #FF5A5A
// muted #A0A0C0

class _LogoutBottomSheet extends StatefulWidget {
  const _LogoutBottomSheet();

  @override
  State<_LogoutBottomSheet> createState() => _LogoutBottomSheetState();
}

class _LogoutBottomSheetState extends State<_LogoutBottomSheet>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl;
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
                        final opacity = 0.18 + 0.14 * _pulseCtrl.value;
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
                          painter: _LogoutOrbitPainter(_orbitCtrl.value),
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
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── title ───────────────────────────────────
              const Text(
                'Sign out?',
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
                'Your streak will pause until you\nsign in again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFA0A0C0).withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),

              // ── "Stay Signed In" button (primary green) ─
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
                    'Stay Signed In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── "Sign Out" button (ghost) ───────────────
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
                    'Sign Out',
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

// ── LOGOUT ORBIT PAINTER ────────────────────────────────────────────
// Draws two glowing arcs rotating around a centre point.
class _LogoutOrbitPainter extends CustomPainter {
  final double progress;
  _LogoutOrbitPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 4;

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
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      progress * 2 * pi,
      pi * 0.7,
      false,
      paint1,
    );

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
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      progress * 2 * pi + pi,
      pi * 0.4,
      false,
      paint2,
    );
  }

  @override
  bool shouldRepaint(_LogoutOrbitPainter old) => old.progress != progress;
}
