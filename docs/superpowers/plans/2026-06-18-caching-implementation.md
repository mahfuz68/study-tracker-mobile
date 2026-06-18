# API Response Caching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show cached data instantly on app open, then refresh in background if stale.

**Architecture:** A `CacheService` wrapping SharedPreferences stores JSON responses with timestamps. Providers use cache-first loading: show cached data instantly, then fetch fresh data in background. A 4:00 AM daily cache bust ensures fresh data every morning.

**Tech Stack:** Flutter, SharedPreferences (existing dependency), Provider, dart:convert for JSON serialization.

## Global Constraints

- Use existing `SharedPreferences` dependency (no new packages)
- Cache keys must be prefixed with `cache_` to avoid collisions
- All cache operations must be async (SharedPreferences is async)
- Providers must not change their public API (consumers see no difference)
- The 4:00 AM bust uses local timezone, not UTC

---

### Task 1: Create CacheService

**Files:**
- Create: `lib/services/cache_service.dart`

**Interfaces:**
- Produces: `CacheService` class with `get`, `set`, `remove`, `clearAll`, `shouldBustDailyCache`, `markDailyCacheBusted`

- [ ] **Step 1: Create CacheService file**

```dart
// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps SharedPreferences to provide TTL-based JSON response caching.
///
/// Cache keys are stored as `cache_<key>` with a corresponding timestamp
/// at `cache_ts_<key>`. The `shouldBustDailyCache` method checks if the
/// last daily bust was before today's 4:00 AM local time.
class CacheService {
  static const _prefix = 'cache_';
  static const _timestampPrefix = 'cache_ts_';
  static const _dailyBustKey = 'cache_last_daily_bust';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  /// Initialize — call once at app startup.
  static Future<CacheService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CacheService(prefs);
  }

  /// Get cached JSON data. Returns null if not found or older than [ttl].
  Future<Map<String, dynamic>?> get(String key, {Duration? ttl}) async {
    final jsonStr = _prefs.getString('$_prefix$key');
    if (jsonStr == null) return null;

    // Check TTL if provided
    if (ttl != null) {
      final tsMs = _prefs.getInt('$_timestampPrefix$key');
      if (tsMs == null) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(tsMs);
      if (DateTime.now().difference(cachedAt) > ttl) return null;
    }

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Store JSON data with current timestamp.
  Future<void> set(String key, Map<String, dynamic> data) async {
    await _prefs.setString('$_prefix$key', jsonEncode(data));
    await _prefs.setInt(
      '$_timestampPrefix$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Remove a single cache entry.
  Future<void> remove(String key) async {
    await _prefs.remove('$_prefix$key');
    await _prefs.remove('$_timestampPrefix$key');
  }

  /// Remove all cache entries (keeps auth tokens and non-cache keys).
  Future<void> clearAll() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_prefix)) {
        await _prefs.remove(key);
      }
    }
  }

  /// Check if caches are older than today's 4:00 AM local time.
  /// Returns true if a daily bust is needed.
  Future<bool> shouldBustDailyCache() async {
    final lastBustMs = _prefs.getInt(_dailyBustKey);
    if (lastBustMs == null) return true;

    final lastBust = DateTime.fromMillisecondsSinceEpoch(lastBustMs);
    final now = DateTime.now();
    final today4am = DateTime(now.year, now.month, now.day, 4, 0, 0);

    return lastBust.isBefore(today4am);
  }

  /// Mark daily cache as busted (call after background refresh completes).
  Future<void> markDailyCacheBusted() async {
    await _prefs.setInt(
      _dailyBustKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/cache_service.dart
git commit -m "feat: add CacheService with TTL-based JSON caching"
```

---

### Task 2: Initialize CacheService in main.dart

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `CacheService` from Task 1
- Produces: `CacheService` available via `Provider.of<CacheService>(context)` throughout the app

- [ ] **Step 1: Update main.dart to initialize and provide CacheService**

```dart
// lib/main.dart
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
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => McqProvider()),
        ChangeNotifierProvider(create: (_) => PuzzleProvider()),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const StudyProgressApp(),
    ),
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize CacheService and provide to app"
```

---

### Task 3: Integrate caching into ProgressProvider

**Files:**
- Modify: `lib/providers/progress_provider.dart`

**Interfaces:**
- Consumes: `CacheService` from Provider
- Produces: Cache-first loading for `loadStudyPlan()` and `loadDayProgress()`

- [ ] **Step 1: Add cache-first loading to ProgressProvider**

Read the current `progress_provider.dart`. Find the `_service` field and add a `_cache` field. Then update `loadStudyPlan()` and `loadDayProgress()`.

The changes to make:

1. Add `import '../services/cache_service.dart';` at the top
2. Add a `_cache` field and constructor parameter (or fetch from Provider)
3. Update `loadStudyPlan()` to check cache first
4. Update `loadDayProgress()` to check cache first

```dart
// In progress_provider.dart — add import at top:
import '../services/cache_service.dart';
import 'package:provider/provider.dart';

// Add field alongside existing fields:
CacheService? _cache;

// In _initialLoad or wherever provider is first used, fetch cache:
// (This happens automatically via Provider.of in the widget)

// Replace loadStudyPlan() with:
Future<void> loadStudyPlan() async {
  _cache ??= _getCache();
  final cached = await _cache?.get('study_plan');
  if (cached != null) {
    _studyPlan = StudyPlan.fromJson(cached);
    notifyListeners();
  }

  try {
    _isLoading = true;
    notifyListeners();
    final fresh = await _service.getProgressSummary();
    _studyPlan = fresh;
    await _cache?.set('study_plan', fresh.toJson());
    _error = null;
  } catch (e) {
    if (_studyPlan == null) _error = e.toString();
  }

  _isLoading = false;
  notifyListeners();
}

// Replace loadDayProgress() with:
Future<void> loadDayProgress(int dayNumber) async {
  _cache ??= _getCache();
  final cached = await _cache?.get('day_$dayNumber');
  if (cached != null) {
    _dayProgress = (cached['data'] as List<dynamic>?)
            ?.map((p) => Progress.fromJson(p))
            .toList() ??
        [];
    notifyListeners();
  }

  try {
    final fresh = await _service.getDayProgress(dayNumber);
    _dayProgress = fresh;
    await _cache?.set('day_$dayNumber', {'data': fresh.map((p) => p.toJson()).toList()});
    _error = null;
  } catch (e) {
    if (_dayProgress.isEmpty) _error = e.toString();
  }

  notifyListeners();
}

// Add helper method to resolve CacheService from Provider:
CacheService? _getCache() {
  // Will be set via Provider.of in the widget tree
  return null;
}
```

**Better approach:** Since Provider injects dependencies, update the constructor to accept `CacheService`:

```dart
class ProgressProvider extends ChangeNotifier {
  final ProgressService _service = ProgressService();
  final CacheService _cache;

  ProgressProvider(this._cache);
  // ... rest of existing fields
}
```

Then update `main.dart` to pass cache:

```dart
ChangeNotifierProvider(create: (ctx) => ProgressProvider(ctx.read<CacheService>())),
```

- [ ] **Step 2: Run existing tests to verify no regressions**

Run: `flutter test`
Expected: All existing tests pass (or no tests exist yet)

- [ ] **Step 3: Commit**

```bash
git add lib/providers/progress_provider.dart lib/main.dart
git commit -m "feat: add cache-first loading to ProgressProvider"
```

---

### Task 4: Integrate caching into McqProvider

**Files:**
- Modify: `lib/providers/mcq_provider.dart`

**Interfaces:**
- Consumes: `CacheService` from Provider
- Produces: Cache-first loading for `loadSubjects()` and `loadTopics()`

- [ ] **Step 1: Add cache-first loading to McqProvider**

Make the same pattern changes as Task 3:

1. Add `import '../services/cache_service.dart';`
2. Add `CacheService _cache` field and constructor parameter
3. Update `loadSubjects()`:

```dart
Future<void> loadSubjects() async {
  final cached = await _cache.get('mcq_subjects', ttl: const Duration(days: 7));
  if (cached != null) {
    _subjects = (cached['data'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    _subjectsLoading = false;
    notifyListeners();
  }

  try {
    _subjectsLoading = true;
    notifyListeners();
    _subjects = await _service.getSubjects();
    await _cache.set('mcq_subjects', {'data': _subjects});
  } catch (e) {
    if (_subjects.isEmpty) _error = e.toString();
  }

  _subjectsLoading = false;
  notifyListeners();
}
```

4. Update `loadTopics()`:

```dart
Future<void> loadTopics(String subject) async {
  _selectedSubject = subject;
  _selectedTopic = null;
  _topics = [];
  _topicsLoading = true;
  notifyListeners();

  final cached = await _cache.get('mcq_topics_$subject', ttl: const Duration(days: 7));
  if (cached != null) {
    _topics = (cached['data'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    _topicsLoading = false;
    notifyListeners();
  }

  try {
    _topics = await _service.getTopics(subject: subject);
    await _cache.set('mcq_topics_$subject', {'data': _topics});
  } catch (e) {
    if (_topics.isEmpty) _error = e.toString();
  }

  _topicsLoading = false;
  notifyListeners();
}
```

- [ ] **Step 2: Update main.dart to pass CacheService to McqProvider**

```dart
ChangeNotifierProvider(create: (ctx) => McqProvider(ctx.read<CacheService>())),
```

- [ ] **Step 3: Commit**

```bash
git add lib/providers/mcq_provider.dart lib/main.dart
git commit -m "feat: add cache-first loading to McqProvider"
```

---

### Task 5: Integrate caching into PuzzleProvider

**Files:**
- Modify: `lib/providers/puzzle_provider.dart`

**Interfaces:**
- Consumes: `CacheService` from Provider
- Produces: Cache-first loading for `loadPuzzles()`

- [ ] **Step 1: Add cache-first loading to PuzzleProvider**

Same pattern:

1. Add `import '../services/cache_service.dart';`
2. Add `CacheService _cache` field and constructor parameter
3. Update `loadPuzzles()`:

```dart
Future<void> loadPuzzles() async {
  final cached = await _cache.get('puzzles');
  if (cached != null) {
    _puzzles = (cached['data'] as List<dynamic>?)
            ?.map((p) => Puzzle.fromJson(p))
            .toList() ??
        [];
    _error = null;
    notifyListeners();
  }

  try {
    _isLoading = true;
    notifyListeners();
    _puzzles = await _service.getPuzzles();
    await _cache.set('puzzles', {
      'data': _puzzles.map((p) => {
        'id': p.id,
        'title': p.title,
        'topic': p.topic,
        'status': p.status,
        'scenarioParagraph': p.scenarioParagraph,
        'timeLimit': p.timeLimit,
      }).toList(),
    });
    _error = null;
  } catch (e) {
    if (_puzzles.isEmpty) _error = e.toString();
  }

  _isLoading = false;
  notifyListeners();
}
```

- [ ] **Step 2: Update main.dart to pass CacheService to PuzzleProvider**

```dart
ChangeNotifierProvider(create: (ctx) => PuzzleProvider(ctx.read<CacheService>())),
```

- [ ] **Step 3: Commit**

```bash
git add lib/providers/puzzle_provider.dart lib/main.dart
git commit -m "feat: add cache-first loading to PuzzleProvider"
```

---

### Task 6: Add 4:00 AM daily cache bust to Dashboard

**Files:**
- Modify: `lib/screens/dashboard/dashboard_screen.dart`

**Interfaces:**
- Consumes: `CacheService` from Provider
- Produces: Triggers cache bust and background refresh on app open

- [ ] **Step 1: Add daily bust check to DashboardScreen**

In `DashboardScreen._initialLoad()`, after loading cached data, check if a daily bust is needed:

```dart
// In _initialLoad() method, add at the beginning:
final cache = context.read<CacheService>();
if (await cache.shouldBustDailyCache()) {
  // Force background refresh of all cached data
  // The cache-first pattern already handles this — cached data shows instantly,
  // then fresh data fetches in background. We just need to mark as busted
  // after all providers finish loading.
  await Future.wait([
    context.read<ProgressProvider>().loadStudyPlan(),
    context.read<McqProvider>().loadSubjects(),
    context.read<PuzzleProvider>().loadPuzzles(),
  ]);
  await cache.markDailyCacheBusted();
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: add 4AM daily cache bust to dashboard"
```

---

### Task 7: Add caching to LeaderboardScreen

**Files:**
- Modify: `lib/screens/leaderboard/leaderboard_screen.dart`
- Modify: `lib/services/leaderboard_service.dart`

**Interfaces:**
- Consumes: `CacheService` from Provider
- Produces: Cache-first loading for leaderboard

- [ ] **Step 1: Update LeaderboardScreen to use cache**

The leaderboard screen calls `LeaderboardService` directly (no provider). Add cache check in `initState`:

```dart
// In LeaderboardScreen, add CacheService import and check:
import 'package:provider/provider.dart';
import '../../services/cache_service.dart';

// In initState, before fetching:
final cache = context.read<CacheService>();
final cached = await cache.get('leaderboard', ttl: const Duration(hours: 6));
if (cached != null) {
  setState(() {
    _entries = (cached['rows'] as List<dynamic>?)
            ?.map((r) => LeaderboardEntry(...))
            .toList() ??
        [];
    _totalTopics = cached['totalTopics'] ?? 0;
    _loading = false;
  });
}

// After fetching fresh data:
await cache.set('leaderboard', {
  'rows': _entries.map((e) => {'name': e.name, 'completed': e.completedCount, 'rate': e.completionRate * 100}).toList(),
  'totalTopics': _totalTopics,
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/leaderboard/leaderboard_screen.dart
git commit -m "feat: add cache-first loading to leaderboard"
```

---

### Task 8: Add caching to NotificationScreen

**Files:**
- Modify: `lib/screens/notifications/notification_screen.dart`

**Interfaces:**
- Consumes: `CacheService` from Provider
- Produces: Cache-first loading for notifications

- [ ] **Step 1: Update NotificationScreen to use cache**

Same pattern as Task 7:

```dart
// In NotificationScreen initState, add:
final cache = context.read<CacheService>();
final cached = await cache.get('notifications', ttl: const Duration(hours: 1));
if (cached != null) {
  setState(() {
    _notifications = (cached['data'] as List<dynamic>?)
            ?.map((n) => NotificationModel.fromJson(n))
            .toList() ??
        [];
    _loading = false;
  });
}

// After fetching fresh data:
await cache.set('notifications', {
  'data': _notifications.map((n) => n.toJson()).toList(),
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/notifications/notification_screen.dart
git commit -m "feat: add cache-first loading to notifications"
```

---

### Task 9: Verify build compiles

- [ ] **Step 1: Run Flutter analyze**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 2: Commit any fixes if needed**

```bash
git add -A
git commit -m "fix: resolve analysis warnings from caching changes"
```
