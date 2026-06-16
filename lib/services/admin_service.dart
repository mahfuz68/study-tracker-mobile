import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/admin_models.dart';
import 'api_client.dart';

class AdminService {
  final ApiClient _api = ApiClient();

  Future<List<QuestionAdmin>> getQuestions({String? subject, String? topic}) async {
    try {
      final Map<String, String> params = {};
      if (subject != null && subject.isNotEmpty) params['subject'] = subject;
      if (topic != null && topic.isNotEmpty) params['topic'] = topic;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/questions')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${_api.jwtToken}',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((q) => QuestionAdmin.fromJson(q)).toList();
      }
    } catch (e) {
      print('Error loading questions: $e');
    }
    return [];
  }

  Future<List<String>> getSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/mcq/subjects'),
        headers: {'Authorization': 'Bearer ${_api.jwtToken}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((s) => s.toString()).toList();
      }
    } catch (e) {
      print('Error loading subjects: $e');
    }
    return [];
  }

  Future<List<String>> getTopics() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/mcq/topics'),
        headers: {'Authorization': 'Bearer ${_api.jwtToken}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((t) => t.toString()).toList();
      }
    } catch (e) {
      print('Error loading topics: $e');
    }
    return [];
  }

  Future<void> addQuestion({
    required String subject,
    required String topic,
    required String question,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required int correct,
  }) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_api.jwtToken}',
        },
        body: json.encode({
          'subject': subject,
          'topic': topic,
          'question': question,
          'optionA': optionA,
          'optionB': optionB,
          'optionC': optionC,
          'optionD': optionD,
          'correct': correct,
        }),
      );
    } catch (e) {
      print('Error adding question: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(int id) async {
    try {
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/questions/$id'),
        headers: {'Authorization': 'Bearer ${_api.jwtToken}'},
      );
    } catch (e) {
      print('Error deleting question: $e');
      rethrow;
    }
  }

  Future<List<UserAdmin>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users'),
        headers: {'Authorization': 'Bearer ${_api.jwtToken}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((u) => UserAdmin.fromJson(u)).toList();
      }
    } catch (e) {
      print('Error loading users: $e');
    }
    return [];
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_api.jwtToken}',
        },
        body: json.encode({'role': role}),
      );
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }
}
