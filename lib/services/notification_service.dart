import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _api = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> registerToken(String fcmToken) async {
    try {
      await _api.post('/api/notifications/register-token', body: {
        'token': fcmToken,
        'platform': 'android',
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final data = await _api.get('/api/notifications');
      final raw = data['data'];
      if (raw is List) {
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.put('/api/notifications/$notificationId/read');
    } catch (_) {}
  }

  void showLocalNotification(String title, String body) {
    if (!_initialized) return;
    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_tracker',
          'Study Tracker',
          channelDescription: 'Study Tracker notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}