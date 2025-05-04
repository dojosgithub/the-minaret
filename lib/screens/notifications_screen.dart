import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/connection_error_widget.dart';
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
      // Get current user ID
      final currentUserId = await ApiService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Get all notifications
      final notifications = await ApiService.getNotifications();
      
      // Filter notifications where current user is the recipient
      final filteredNotifications = notifications.where((notification) {
        final recipientId = notification['recipient']?.toString();
        return recipientId != null && recipientId == currentUserId;
      }).toList();

      setState(() {
        _notifications = filteredNotifications;
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
      case 'saved':
        return '$senderName saved your post';
      default:
        return 'New notification';
    }
  }

  String? _getPostId(Map<String, dynamic> notification) {
    // Check if notification has a related post
    final postTypes = ['upvote', 'downvote', 'comment', 'reply', 'repost', 'saved'];
    
    if (postTypes.contains(notification['type'])) {
      // If notification contains a post object with an _id field
      if (notification['post'] != null) {
        // Handle if post is an object with _id field
        if (notification['post'] is Map && notification['post']['_id'] != null) {
          return notification['post']['_id'].toString();
        }
        // Handle if post is just the ID as a string or other type
        return notification['post'].toString();
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Notifications', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: () async {
                try {
                  await ApiService.markAllNotificationsAsRead();
                  _loadNotifications(); // Reload to update UI
                } catch (e) {
                  debugPrint('Error marking all notifications as read: $e');
                }
              },
              tooltip: 'Mark all as read',
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
                              postId: _getPostId(notification),
                              notificationId: notification['_id']?.toString(),
                              isRead: notification['read'] == true,
                            );
                          },
                        ),
                ),
    );
  }
}