# API Response Caching for Fast App Open

**Date:** 2026-06-18
**Goal:** Show cached data instantly on app open, then refresh in background if stale

## Problem

Every screen fetches fresh data from the API on every visit. This causes:
- Slow app open (dashboard blocks on `GET /api/progress/summary`)
- Unnecessary network calls for stable data (subjects, topics, puzzle list)
- Poor experience on slow connections

## Solution

A `CacheService` wrapping `SharedPreferences` that stores JSON responses with timestamps. Providers use a cache-first strategy: show cached data immediately, then fetch fresh data in the background.

## Architecture

```
App opens → Provider.load() → CacheService.get(key)
  ├─ Cache HIT & fresh (< TTL) → show cached data immediately, no network call
  ├─ Cache HIT & stale (> TTL) → show cached data, fetch fresh in background
  └─ Cache MISS → show loading spinner, fetch from API
```

## CacheService API

```dart
class CacheService {
  static const _prefix = 'cache_';
  static const _timestampPrefix = 'cache_ts_';

  /// Get cached JSON data. Returns null if not found or expired.
  Future<Map<String, dynamic>?> get(String key, {Duration? ttl});

  /// Store JSON data with current timestamp.
  Future<void> set(String key, Map<String, dynamic> data);

  /// Remove a single cache entry.
  Future<void> remove(String key);

  /// Remove all cache entries.
  Future<void> clearAll();

  /// Check if caches are older than today's 4:00 AM. If so, mark all stale.
  Future<bool> shouldBustDailyCache();

  /// Mark daily cache as busted (called after background refresh).
  Future<void> markDailyCacheBusted();
}
```

## What Gets Cached

| Endpoint | Cache Key | TTL | Rationale |
|---|---|---|---|
| `GET /api/progress/summary` | `study_plan` | 24h | Dashboard loads first — must be instant |
| `GET /api/progress?dayNumber=N` | `day_{N}` | 24h | Day switch should feel instant |
| `GET /api/mcq/subjects` | `mcq_subjects` | 7 days | Very stable — only changes with new question sets |
| `GET /api/mcq/topics?subject=X` | `mcq_topics_{subject}` | 7 days | Very stable |
| `GET /api/puzzles` | `puzzles` | 24h | Puzzle list is stable |
| `GET /api/leaderboard` | `leaderboard` | 6h | Changes as users study |
| `GET /api/notifications` | `notifications` | 1h | Changes frequently |

## What Does NOT Get Cached

- All `POST`, `PUT`, `DELETE` requests — mutations always hit the server
- `GET /api/mcq/start` — generates random questions, must be fresh
- `GET /api/mcq/attempts/{id}` — one-shot review data after submit
- `GET /api/puzzles/{id}` — puzzle detail for playing (could change mid-game)
- Auth endpoints (`/api/auth/*`) — session management, not cacheable
- Admin endpoints — infrequent, always fresh

## 4:00 AM Daily Cache Bust

On every app open, `CacheService.shouldBustDailyCache()` checks:
1. Read stored `last_daily_bust` timestamp
2. Compute today's 4:00 AM in local timezone
3. If `last_daily_bust` < today's 4:00 AM → return `true`

When `true`, providers skip the cache freshness check and treat all cached data as stale → background refresh all. After refresh completes, call `markDailyCacheBusted()`.

This ensures fresh data every morning without a background cron job or push notification.

## Provider Integration Pattern

Each provider that caches data follows this pattern:

```dart
Future<void> loadStudyPlan() async {
  // 1. Show cached data instantly (if available)
  final cached = await _cache.get('study_plan');
  if (cached != null) {
    _studyPlan = StudyPlan.fromJson(cached);
    notifyListeners();
  }

  // 2. Fetch fresh data in background
  try {
    final fresh = await _service.getProgressSummary();
    _studyPlan = fresh;
    await _cache.set('study_plan', fresh.toJson());
    notifyListeners();
  } catch (e) {
    // If network fails and we have cached data, keep showing it
    if (_studyPlan == null) _error = e.toString();
    notifyListeners();
  }
}
```

Key behaviors:
- Cached data shows instantly (no loading spinner if cache exists)
- Network failure is silent if cached data is available
- Network failure shows error only if no cached data exists
- Fresh data always overwrites cached data on success

## Files to Create

| File | Purpose |
|---|---|
| `lib/services/cache_service.dart` | CacheService class wrapping SharedPreferences |

## Files to Modify

| File | Change |
|---|---|
| `lib/main.dart` | Initialize CacheService as a Provider, pass to app |
| `lib/providers/progress_provider.dart` | Cache-first loading for study plan and day progress |
| `lib/providers/mcq_provider.dart` | Cache subjects and topics lists |
| `lib/providers/puzzle_provider.dart` | Cache puzzle list |
| `lib/services/leaderboard_service.dart` | Cache leaderboard response |
| `lib/services/notification_service.dart` | Cache notifications list |

## Testing

- Unit test CacheService: get/set/remove/clear/ttl expiry
- Unit test daily bust logic: mock timestamps, verify shouldBustDailyCache
- Widget test: verify provider shows cached data before network response
- Manual test: kill app, reopen, verify instant display; wait for TTL expiry, verify background refresh
