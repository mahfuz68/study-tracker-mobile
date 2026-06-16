import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _showChangeForm = false;
  bool _changingPw = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user?.isAdmin == true
                        ? AppTheme.accentGold.withOpacity(0.15)
                        : AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role ?? 'USER',
                    style: TextStyle(
                      color: user?.isAdmin == true
                          ? AppTheme.accentGold
                          : AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Info',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _infoRow(Icons.person, 'Name', user?.name ?? ''),
                _infoRow(Icons.email, 'Email', user?.email ?? ''),
                _infoRow(Icons.badge, 'Role', user?.role ?? ''),
                if (user?.createdAt != null)
                  _infoRow(Icons.calendar_today, 'Member since',
                      _formatDate(user!.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(
                () => _showChangeForm = !_showChangeForm),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  const Text('Change Password',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  const Spacer(),
                  Icon(
                    _showChangeForm
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_showChangeForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _currentPwController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPwController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPwController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changingPw ? null : _changePassword,
                      child: _changingPw
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(auth),
              icon: const Icon(Icons.logout, color: AppTheme.errorRed),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppTheme.errorRed)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.errorRed.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text(label + ': ',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
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

  void _changePassword() async {
    final current = _currentPwController.text;
    final next = _newPwController.text;
    final confirm = _confirmPwController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _changingPw = true);
    try {
      await AuthService().changePassword(current, next);
      if (!mounted) return;
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      setState(() {
        _showChangeForm = false;
        _changingPw = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _changingPw = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }
}

// ── LOGOUT BOTTOM SHEET ──────────────────────────────────────────
// Same design as the exit bottom sheet: dark bg, orbit animation,
// heavy title / light body, stacked buttons. The icon pulses with
// a green glow; "Stay Signed In" is the primary action, "Sign Out"
// is the quiet ghost action below.
// Palette: bg #0E0E1C · card #1C1C32 · brand #00C896 · red #FF5A5A
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
                            color:
                                const Color(0xFF00C896).withOpacity(0.45),
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

// ── ORBIT PAINTER ──────────────────────────────────────────────
// Same painter used by the exit sheet — draws two glowing arcs
// rotating around a centre point.
class _OrbitPainter extends CustomPainter {
  final double progress;
  _OrbitPainter(this.progress);

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
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress;
}
