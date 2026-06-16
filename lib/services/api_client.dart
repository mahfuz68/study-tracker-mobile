import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _jwtToken;
  bool _initialized = false;

  String get baseUrl => ApiConfig.baseUrl;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwt_token');
    _initialized = true;
  }

  Future<void> _saveToken(String? token) async {
    _jwtToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('jwt_token', token);
    } else {
      await prefs.remove('jwt_token');
    }
  }

  Future<void> clearSession() async {
    _jwtToken = null;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_jwtToken != null) {
      h['Authorization'] = 'Bearer $_jwtToken';
    }
    return h;
  }

  Future<bool> hasSession() async {
    await _ensureInitialized();
    return _jwtToken != null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      String message = 'Invalid email or password.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body.containsKey('error')) {
          message = body['error'] as String;
        }
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null) throw ApiException('No token received');

    await _saveToken(token);
    _initialized = true;
    return data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode != 201) {
      String message = 'Registration failed';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body.containsKey('error')) {
          message = body['error'] as String;
        }
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null) throw ApiException('No token received');

    await _saveToken(token);
    _initialized = true;
    return data;
  }

  Future<void> logout() async {
    try {
      await _client.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: _headers,
      );
    } catch (_) {}
    await clearSession();
  }

  Future<Map<String, dynamic>?> getSession() async {
    await _ensureInitialized();
    if (_jwtToken == null) return null;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers,
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    await _ensureInitialized();
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    await _ensureInitialized();
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    await _ensureInitialized();
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    await _ensureInitialized();
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'ok': true};
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return {'data': data};
    }
    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('error')) {
        message = body['error'] as String;
      }
    } catch (_) {}
    if (response.statusCode == 401) {
      clearSession();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}