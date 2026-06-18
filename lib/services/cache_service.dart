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
