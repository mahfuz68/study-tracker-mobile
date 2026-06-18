import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/puzzle_service.dart';
import '../services/cache_service.dart';

class PuzzleProvider extends ChangeNotifier {
  final PuzzleService _service = PuzzleService();
  final CacheService _cache;

  PuzzleProvider(this._cache);
  List<Puzzle> _puzzles = [];
  Puzzle? _currentPuzzle;
  PuzzleAttempt? _lastAttempt;
  Map<String, String?> _selectedOptions = {};

  Map<String, String?> get selectedOptions => _selectedOptions;
  bool _isLoading = false;
  String? _error;

  List<Puzzle> get puzzles => _puzzles;
  Puzzle? get currentPuzzle => _currentPuzzle;
  PuzzleAttempt? get lastAttempt => _lastAttempt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPuzzles() async {
    // 1. Show cached data instantly
    final cached = await _cache.get('puzzles');
    if (cached != null) {
      _puzzles = (cached['data'] as List<dynamic>?)
              ?.map((p) => Puzzle.fromJson(p))
              .toList() ??
          [];
      _error = null;
      notifyListeners();
    }

    // 2. Fetch fresh data in background
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

  Future<void> loadPuzzleDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPuzzle = await _service.getPuzzleDetail(id);
      _selectedOptions = {};
      for (final q in _currentPuzzle!.questions) {
        _selectedOptions[q.id] = null;
      }
      _lastAttempt = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectOption(String questionId, String optionId) {
    _selectedOptions[questionId] = optionId;
    notifyListeners();
  }

  Future<void> submitPuzzle(String puzzleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final answers = _selectedOptions.entries
          .map((e) => {
                'questionId': e.key,
                'selectedOptionId': e.value,
              })
          .toList();

      _lastAttempt = await _service.submitAnswers(puzzleId, answers);

      // Fetch full attempt detail so the result screen can show answer review
      if (_lastAttempt != null && _lastAttempt!.id.isNotEmpty) {
        try {
          _lastAttempt = await _service.getAttemptDetail(_lastAttempt!.id);
        } catch (_) {
          // If detail fetch fails, still show the basic result
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _currentPuzzle = null;
    _selectedOptions = {};
    _lastAttempt = null;
    _error = null;
    notifyListeners();
  }
}
