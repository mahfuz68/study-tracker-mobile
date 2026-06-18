import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/mcq_provider.dart';
import 'providers/puzzle_provider.dart';
import 'providers/navigation_controller.dart';
import 'providers/admin_provider.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService().initialize();
  final cacheService = await CacheService.create();

  runApp(
    MultiProvider(
      providers: [
        Provider<CacheService>.value(value: cacheService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ProgressProvider(ctx.read<CacheService>())),
        ChangeNotifierProvider(create: (ctx) => McqProvider(ctx.read<CacheService>())),
        ChangeNotifierProvider(create: (ctx) => PuzzleProvider(ctx.read<CacheService>())),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const StudyProgressApp(),
    ),
  );
}