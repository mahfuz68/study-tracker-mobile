import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Bottom-nav tabs. Icons only (no labels). Per the spec, the four tabs
  /// are Schedule, Progress, MCQ, Saved. Puzzles / Leaderboard / Admin
  /// routes still exist but are reachable from the side drawer / profile.
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.calendar_today_rounded,
      outlineIcon: Icons.calendar_today_outlined,
      route: '/dashboard',
    ),
    _NavItem(
      icon: Icons.insights_rounded,
      outlineIcon: Icons.show_chart_rounded,
      route: '/progress',
    ),
    _NavItem(
      icon: Icons.checklist_rounded,
      outlineIcon: Icons.checklist_outlined,
      route: '/mcq',
    ),
    _NavItem(
      icon: Icons.star_rounded,
      outlineIcon: Icons.star_outline_rounded,
      route: '/puzzles',
    ),
  ];

  int get _selectedIndex {
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName == null) return 0;
    for (int i = 0; i < _navItems.length; i++) {
      if (_navItems[i].route == routeName) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 720)
            _buildSidebar(),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar:
          MediaQuery.of(context).size.width <= 720
              ? _buildBottomNav()
              : null,
    );
  }

  Widget _buildSidebar() {
    final auth = context.watch<AuthProvider>();
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(
          right: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Study Tracker',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _sidebarSection('Main'),
                _sidebarItem(Icons.calendar_today_rounded, 'Schedule',
                    '/dashboard', context),
                _sidebarItem(Icons.insights_rounded, 'Progress',
                    '/progress', context),
                _sidebarItem(Icons.quiz_rounded, 'MCQ Exam', '/mcq', context),
                _sidebarItem(Icons.extension_rounded, 'Puzzles',
                    '/puzzles', context),
                _sidebarItem(Icons.leaderboard_rounded, 'Leaderboard',
                    '/leaderboard', context),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 8),
                  _sidebarSection('Admin'),
                  _sidebarItem(Icons.dashboard_rounded, 'Dashboard',
                      '/admin', context),
                  _sidebarItem(Icons.view_list_rounded, 'Routine',
                      '/admin/routine', context),
                  _sidebarItem(Icons.help_outline_rounded, 'Questions',
                      '/admin/questions', context),
                  _sidebarItem(Icons.extension_rounded, 'Puzzles',
                      '/admin/puzzles', context),
                  _sidebarItem(Icons.people_alt_rounded, 'Users',
                      '/admin/users', context),
                ],
                const SizedBox(height: 8),
                _sidebarSection('Account'),
                _sidebarItem(Icons.notifications_rounded, 'Notifications',
                    '/notifications', context),
                _sidebarItem(Icons.person_rounded, 'Profile',
                    '/profile', context),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.border.withOpacity(0.5), width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      (auth.user?.name ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'User',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.email ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => auth.logout(),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.logout_rounded,
                          color: AppTheme.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _sidebarItem(
      IconData icon, String label, String route, BuildContext c) {
    final isActive = ModalRoute.of(c)?.settings.name == route ||
        (route == '/dashboard' && ModalRoute.of(c)?.settings.name == null);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [
                  Color(0x3310B981),
                  Color(0x1A10B981),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3), width: 0.5)
            : null,
      ),
      child: ListTile(
        leading: Icon(icon,
            size: 20,
            color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => Navigator.pushReplacementNamed(c, route),
      ),
    );
  }

  /// Icons-only bottom nav with frosted background, per the design spec.
  Widget _buildBottomNav() {
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
                  final isActive = index == _selectedIndex;
                  return _NavIconButton(
                    icon: isActive
                        ? _navItems[index].icon
                        : _navItems[index].outlineIcon,
                    isActive: isActive,
                    onTap: () {
                      if (index == _selectedIndex) return;
                      Navigator.pushReplacementNamed(
                          context, _navItems[index].route);
                    },
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

class _NavItem {
  final IconData icon;
  final IconData outlineIcon;
  final String route;
  _NavItem({
    required this.icon,
    required this.outlineIcon,
    required this.route,
  });
}
