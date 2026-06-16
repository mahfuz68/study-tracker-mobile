import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/mcq_attempt.dart';
import '../services/mcq_service.dart';

enum ExamStatus { setup, running, reviewing, completed }

class McqProvider extends ChangeNotifier {
  final McqService _service = McqService();

  ExamStatus _status = ExamStatus.setup;
  List<Question> _questions = [];
  List<int?> _answers = [];
  List<bool> _locked = [];
  Set<int> _markedForReview = {};
  int _currentIndex = 0;
  int _timePerQuestion = 36;
  McqAttempt? _lastAttempt;
  List<McqAttempt> _attempts = [];
  bool _isLoading = false;
  String? _error;

  // ── Dropdown state ────────────────────────────────────────────
  /// Distinct subjects available in the Question table.
  List<String> _subjects = [];
  bool _subjectsLoading = false;
  /// Distinct topics for the currently-selected subject.
  List<String> _topics = [];
  bool _topicsLoading = false;
  String? _selectedSubject;
  String? _selectedTopic;

  ExamStatus get status => _status;
  List<Question> get questions => _questions;
  List<int?> get answers => _answers;
  List<bool> get locked => _locked;
  Set<int> get markedForReview => _markedForReview;
  int get currentIndex => _currentIndex;
  int get timePerQuestion => _timePerQuestion;
  McqAttempt? get lastAttempt => _lastAttempt;
  List<McqAttempt> get attempts => _attempts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get subjects => _subjects;
  bool get subjectsLoading => _subjectsLoading;
  List<String> get topics => _topics;
  bool get topicsLoading => _topicsLoading;
  String? get selectedSubject => _selectedSubject;
  String? get selectedTopic => _selectedTopic;

  int get totalQuestions => _questions.length;
  int get answeredCount =>
      _answers.where((a) => a != null).length;
  int get lockedCount => _locked.where((l) => l).length;

  bool get allLocked => _locked.every((l) => l);

  void setTimePerQuestion(int seconds) {
    _timePerQuestion = seconds;
    notifyListeners();
  }

  Future<void> startExam({
    String? subject,
    String? topic,
    int limit = 10,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _questions = await _service.startExam(
        subject: subject,
        topic: topic,
        limit: limit,
      );
      _answers = List.filled(_questions.length, null);
      _locked = List.filled(_questions.length, false);
      _markedForReview = {};
      _currentIndex = 0;
      _status = ExamStatus.running;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectAnswer(int questionIndex, int optionIndex) {
    if (_locked[questionIndex]) return;
    _answers[questionIndex] = optionIndex;
    notifyListeners();
  }

  void lockAnswer(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= _locked.length) return;
    _locked[questionIndex] = true;
    notifyListeners();
  }

  void toggleMarkForReview(int index) {
    if (_markedForReview.contains(index)) {
      _markedForReview.remove(index);
    } else {
      _markedForReview.add(index);
    }
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  Future<void> submitExam({String? subject, String? topic}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final answersPayload = <Map<String, dynamic>>[];
      for (int i = 0; i < _questions.length; i++) {
        answersPayload.add({
          'questionId': _questions[i].id,
          'chosen': _answers[i],
        });
      }

      _lastAttempt = await _service.submitExam(
        answers: answersPayload,
        subject: subject,
        topic: topic,
      );
      _status = ExamStatus.completed;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void resetExam() {
    _status = ExamStatus.setup;
    _questions = [];
    _answers = [];
    _locked = [];
    _markedForReview = {};
    _currentIndex = 0;
    _lastAttempt = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadAttempts({
    int limit = 20,
    String? subject,
    String? topic,
    bool? passed,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attempts = await _service.getAttempts(
        limit: limit,
        subject: subject,
        topic: topic,
        passed: passed,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<McqAttempt> getAttemptDetail(int id) async {
    return await _service.getAttemptDetail(id);
  }

  void setStatus(ExamStatus s) {
    _status = s;
    notifyListeners();
  }

  // ── Dropdown helpers ─────────────────────────────────────────

  /// Fetch the list of distinct subjects from the backend. Called once
  /// when the MCQ setup screen mounts.
  Future<void> loadSubjects() async {
    _subjectsLoading = true;
    notifyListeners();
    try {
      _subjects = await _service.getSubjects();
    } catch (e) {
      _error = e.toString();
    } finally {
      _subjectsLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetch the topic list for the given [subject]. Called when the
  /// subject dropdown changes; also clears any previously-selected
  /// topic since the topics set may differ.
  Future<void> loadTopics(String subject) async {
    _selectedSubject = subject;
    _selectedTopic = null;
    _topics = [];
    _topicsLoading = true;
    notifyListeners();
    try {
      _topics = await _service.getTopics(subject: subject);
    } catch (e) {
      _error = e.toString();
    } finally {
      _topicsLoading = false;
      notifyListeners();
    }
  }

  void selectSubject(String? subject) {
    _selectedSubject = subject;
    _selectedTopic = null;
    _topics = [];
    notifyListeners();
    if (subject != null && subject.isNotEmpty) {
      loadTopics(subject);
    }
  }

  void selectTopic(String? topic) {
    _selectedTopic = topic;
    notifyListeners();
  }
}
