import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/puzzle_service.dart';

class PuzzleProvider extends ChangeNotifier {
  final PuzzleService _service = PuzzleService();
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _puzzles = await _service.getPuzzles();
      _error = null;
    } catch (e) {
      _error = e.toString();
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
