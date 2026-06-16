import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<User> login(String email, String password) async {
    final data = await _api.login(email, password);
    final userData = data['user'] as Map<String, dynamic>;
    return User.fromJson(userData);
  }

  Future<User?> getCurrentUser() async {
    final session = await _api.getSession();
    if (session == null || session['id'] == null) return null;
    return User.fromJson(session);
  }

  Future<void> logout() async {
    await _api.logout();
  }

  Future<User> register(String name, String email, String password) async {
    final data = await _api.register(name, email, password);
    final userData = data['user'] as Map<String, dynamic>;
    return User.fromJson(userData);
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _api.put('/api/profile/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}