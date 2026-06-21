import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/cache_service.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final cache = context.read<CacheService>();

    final cached = await cache.get('notifications', ttl: const Duration(hours: 1));
    if (cached != null) {
      _notifications = (cached['data'] as List<dynamic>?)
              ?.map((n) => Map<String, dynamic>.from(n))
              .toList() ??
          [];
      if (mounted) setState(() => _isLoading = false);
    }

    try {
      _notifications = await _service.getNotifications();
      await cache.set('notifications', {
        'data': _notifications,
      });
    } catch (e) {
      // keep cached data
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Notifications', style: AppTheme.display(26, weight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 64, color: AppTheme.textTertiary),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: AppTheme.body(15, color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['read'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead
                                ? AppTheme.border
                                : AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: isRead
                                ? AppTheme.textSecondary
                                : AppTheme.primaryGreen,
                          ),
                          title: Text(
                            n['title'] ?? '',
                            style: AppTheme.body(14,
                                weight: isRead ? FontWeight.w500 : FontWeight.w700),
                          ),
                          subtitle: Text(
                            n['body'] ?? '',
                            style: AppTheme.body(13, color: AppTheme.textSecondary),
                          ),
                          trailing: !isRead
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 20),
                                  onPressed: () async {
                                    await _service.markAsRead(n['id']);
                                    _loadNotifications();
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}