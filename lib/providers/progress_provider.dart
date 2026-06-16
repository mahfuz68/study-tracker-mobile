import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../models/study_day.dart';
import '../services/progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService _service = ProgressService();
  List<StudyDay> _studyPlan = [];
  /// All progress rows for the current user across every day. Populated
  /// by [loadStudyPlan] (which now also returns progresses).
  List<Progress> _allProgress = [];
  /// Progress rows for the currently-displayed day only. Populated by
  /// [loadDayProgress] so the dashboard can render the topic list
  /// without scanning the entire study plan.
  List<Progress> _currentProgress = [];
  int _currentDay = 1;
  bool _isLoading = false;
  String? _error;

  List<StudyDay> get studyPlan => _studyPlan;
  List<Progress> get allProgress => _allProgress;
  List<Progress> get currentProgress => _currentProgress;
  int get currentDay => _currentDay;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StudyDay? get currentStudyDay {
    try {
      return _studyPlan.firstWhere((d) => d.dayNumber == _currentDay);
    } catch (_) {
      return null;
    }
  }

  int get totalDays => _studyPlan.length;

  /// Returns the [StudyDay] whose `date` matches [date], or null if no
  /// day is dated that way. Days without a date are skipped.
  StudyDay? findDayByDate(DateTime date) {
    for (final d in _studyPlan) {
      if (d.date == null) continue;
      final parsed = DateTime.tryParse(d.date!);
      if (parsed == null) continue;
      if (parsed.year == date.year &&
          parsed.month == date.month &&
          parsed.day == date.day) {
        return d;
      }
    }
    return null;
  }

  /// Returns the latest day (highest `dayNumber`) whose date is on or
  /// before [today], or the very last day in the plan if none have a
  /// date. Used to auto-select the most-relevant day on first load.
  StudyDay? latestDayOnOrBefore(DateTime today) {
    StudyDay? best;
    for (final d in _studyPlan) {
      if (d.date == null) {
        best = d; // no date → fall through to last
        continue;
      }
      final parsed = DateTime.tryParse(d.date!);
      if (parsed == null) continue;
      if ((parsed.isBefore(today) || _sameDay(parsed, today)) &&
          (best == null || d.dayNumber > best.dayNumber)) {
        best = d;
      }
    }
    return best ?? (_studyPlan.isNotEmpty ? _studyPlan.last : null);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Cross-day completion: how many of the user's progress rows are
  /// marked complete, divided by the total number of topics in the
  /// entire plan. Returns 0 if the plan is empty.
  double get completionRate {
    if (_studyPlan.isEmpty) return 0;
    int total = 0;
    for (final day in _studyPlan) {
      total += day.topics.length;
    }
    final completed = _allProgress.where((p) => p.isComplete).length;
    return total > 0 ? (completed / total) : 0.0;
  }

  /// Count of completed topics across ALL days (for the dashboard's
  /// "X / Y completed" line).
  int get totalCompleted {
    return _allProgress.where((p) => p.isComplete).length;
  }

  /// Total number of topics across all days.
  int get totalTopics {
    return _studyPlan.fold(0, (sum, d) => sum + d.topics.length);
  }

  /// Per-day completion rate (0.0..1.0). Used by the progress bar
  /// chart. A day with no topics returns 0.0.
  double completionRateForDay(int dayNumber) {
    final day = _studyPlan.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => StudyDay(id: -1, dayNumber: dayNumber),
    );
    if (day.id < 0 || day.topics.isEmpty) return 0.0;
    final topicIds = day.topics.map((t) => t.id).toSet();
    final completed = _allProgress
        .where((p) => topicIds.contains(p.topicId) && p.isComplete)
        .length;
    return completed / day.topics.length;
  }

  Future<void> loadStudyPlan() async {
    _isLoading = true;
    notifyListeners();

    try {
      final summary = await _service.getStudyPlan();
      _studyPlan = summary.days;
      _allProgress = summary.allProgress;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDayProgress(int dayNumber) async {
    _currentDay = dayNumber;
    _isLoading = true;
    notifyListeners();

    try {
      _currentProgress = await _service.getDayProgress(dayNumber);
      // Merge day-level progress into the all-days collection so that
      // completionRate stays accurate after a toggle without a full
      // refetch of the study plan.
      _mergeProgress(_currentProgress);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Insert-or-replace [incoming] rows in [_allProgress] by (topicId, date)
  /// — matching the backend's unique constraint. Called after
  /// [loadDayProgress] and [toggleComplete] / [updateExamMark] so the
  /// cross-day aggregates stay correct.
  void _mergeProgress(List<Progress> incoming) {
    for (final p in incoming) {
      final idx = _allProgress.indexWhere((q) =>
          q.topicId == p.topicId && q.date == p.date);
      if (idx >= 0) {
        _allProgress[idx] = p;
      } else {
        _allProgress.add(p);
      }
    }
  }

  Future<void> toggleComplete(int topicId, String date, bool isComplete) async {
    // One-way lock: a topic that is already complete cannot be unmarked.
    final alreadyComplete = _allProgress
        .any((p) => p.topicId == topicId && p.isComplete);
    if (alreadyComplete && !isComplete) {
      return;
    }
    try {
      _error = null;
      final updated = await _service.updateProgress({
        'topicId': topicId,
        'date': date,
        'isComplete': isComplete,
      });
      _mergeProgress([updated]);
      // Re-fetch this day's progress so the dashboard's per-day view
      // reflects the change (the upsert response carries the merged row).
      _currentProgress = await _service.getDayProgress(_currentDay);
      _mergeProgress(_currentProgress);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateExamMark(
    int topicId,
    String date,
    int mark,
  ) async {
    try {
      final updated = await _service.updateProgress({
        'topicId': topicId,
        'date': date,
        'isComplete': true,
        'hasExam': true,
        'examMark': mark,
      });
      _mergeProgress([updated]);
      _currentProgress = await _service.getDayProgress(_currentDay);
      _mergeProgress(_currentProgress);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setCurrentDay(int day) {
    _currentDay = day;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }
}