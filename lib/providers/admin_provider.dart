import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  List<QuestionAdmin> _questions = [];
  List<UserAdmin> _users = [];
  List<String> _subjects = [];
  List<String> _topics = [];
  bool _isLoading = false;
  String? _error;

  List<QuestionAdmin> get questions => _questions;
  List<UserAdmin> get users => _users;
  List<String> get subjects => _subjects;
  List<String> get topics => _topics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadQuestions({String? subject, String? topic}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _questions = await _service.getQuestions(subject: subject, topic: topic);
      _subjects = await _service.getSubjects();
      _topics = await _service.getTopics();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _service.getUsers();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addQuestion({
    required String subject,
    required String topic,
    required String question,
    required List<String> options,
    required int correct,
  }) async {
    try {
      await _service.addQuestion(
        subject: subject,
        topic: topic,
        question: question,
        optionA: options[0],
        optionB: options[1],
        optionC: options[2],
        optionD: options[3],
        correct: correct,
      );
      await loadQuestions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(int id) async {
    try {
      await _service.deleteQuestion(id);
      await loadQuestions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _service.updateUserRole(userId, role);
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
