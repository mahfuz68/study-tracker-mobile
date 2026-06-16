import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/mcq/mcq_history_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/routine_screen.dart';
import 'screens/admin/questions_screen.dart';
import 'screens/admin/puzzles_admin_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'widgets/main_scaffold.dart';

class StudyProgressApp extends StatelessWidget {
  const StudyProgressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Tracker',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AppStartup(),
      // The four primary tabs share a single route — switching between
      // them happens inside MainScaffold via IndexedStack and does not
      // push a new route. Sub-pages (Profile, Admin, MCQ history, etc.)
      // are still pushed on top of /home so the system back button pops
      // them naturally.
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainScaffold(),
        '/mcq/history': (_) => const McqHistoryScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/admin/routine': (_) => const RoutineScreen(),
        '/admin/questions': (_) => const QuestionsScreen(),
        '/admin/puzzles': (_) => const PuzzlesAdminScreen(),
        '/admin/users': (_) => const UsersScreen(),
        '/notifications': (_) => const NotificationScreen(),
      },
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    final seen = await OnboardingScreen.isSeen();
    if (!mounted) return;

    if (!seen) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}