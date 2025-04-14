import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/screen_wrapper.dart';
import '../widgets/connection_error_widget.dart';
import '../utils/time_utils.dart';
import '../widgets/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getNotificationText(Map<String, dynamic> notification) {
    final senderName = notification['sender']['username'] ?? 'Minaret User';
    
    switch (notification['type']) {
      case 'follow':
        return '$senderName started following you';
      case 'upvote':
        return '$senderName upvoted your post';
      case 'downvote':
        return '$senderName downvoted your post';
      case 'comment':
        return '$senderName commented on your post';
      case 'reply':
        return '$senderName replied to your comment';
      case 'repost':
        return '$senderName reposted your post';
      default:
        return 'New notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ApiService.markAllNotificationsAsRead();
                _loadNotifications();
              } catch (e) {
                debugPrint('Error marking all notifications as read: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to mark all as read')),
                  );
                }
              }
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Color(0xFFFDCC87)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            )
          : _error != null
              ? ConnectionErrorWidget(
                  onRetry: _loadNotifications,
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFFFDCC87),
                  child: _notifications.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return NotificationWidget(
                              name: notification['sender']['username'] ?? 'Minaret User',
                              profilePic: notification['sender']['profileImage'] ?? 'assets/default_profile.png',
                              text: _getNotificationText(notification),
                              dateTime: DateTime.parse(notification['createdAt']),
                              senderId: notification['sender']['_id'],
                            );
                          },
                        ),
                ),
    );
  }
}