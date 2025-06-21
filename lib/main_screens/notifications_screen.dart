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
  bool _hasMarkedAsRead = false;

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

      // If this is the first time loading notifications in this session,
      // mark all as read (only if _hasMarkedAsRead is false)
      if (!_hasMarkedAsRead && filteredNotifications.isNotEmpty) {
        try {
          await ApiService.markAllNotificationsAsRead();
          // Update the read status in the local data
          for (var notification in filteredNotifications) {
            notification['read'] = true;
          }
          _hasMarkedAsRead = true;
        } catch (e) {
          debugPrint('Error marking all notifications as read: $e');
        }
      } else if (_hasMarkedAsRead) {
        // If notifications were already marked as read in this session,
        // ensure they are still marked as read in the UI
        for (var notification in filteredNotifications) {
          notification['read'] = true;
        }
      }

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

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Divide notifications into new (unread) and older (read)
    // When notifications screen is refreshed, all should be read since they're marked as read when viewed
    final newNotifications = _notifications.where((notification) => 
      notification['read'] != true
    ).toList();
    
    final olderNotifications = _notifications.where((notification) => 
      notification['read'] == true
    ).toList();

    return ListView(
      children: [
        // Only show "New" section if there are unread notifications
        if (newNotifications.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'New',
              style: TextStyle(
                color: Color(0xFFFDCC87),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...newNotifications.map((notification) => _buildNotificationWidget(notification)),
        ],
        
        // Only show "Older" section if there are unread notifications
        if (olderNotifications.isNotEmpty) ...[
          // Only add top padding if there were new notifications above
          Padding(
            padding: EdgeInsets.only(
              left: 16, 
              top: newNotifications.isNotEmpty ? 16 : 0, 
              bottom: 8
            ),
            child: newNotifications.isNotEmpty ? const Text(
              'Older',
              style: TextStyle(
                color: Color(0xFFFDCC87),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ) : const SizedBox.shrink(),
          ),
          ...olderNotifications.map((notification) => _buildNotificationWidget(notification)),
        ],
      ],
    );
  }

  Widget _buildNotificationWidget(Map<String, dynamic> notification) {
    return NotificationWidget(
      name: notification['sender']['username'] ?? 'Minaret User',
      profilePic: notification['sender']['profileImage'] ?? 'assets/default_profile.png',
      text: _getNotificationText(notification),
      dateTime: DateTime.parse(notification['createdAt']),
      senderId: notification['sender']['_id'],
      postId: _getPostId(notification),
      notificationId: notification['_id']?.toString(),
      isRead: notification['read'] == true,
      notificationType: notification['type'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        // Use PreferredSize with zero height to avoid the translucent appbar problem
        appBar: PreferredSize(
          preferredSize: Size.zero,
          child: Container(), // Empty container with zero height
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Row(
                  children: [

                    const Icon(Icons.notifications_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  

                  ],
                ),
              ),
              Expanded(
                child: _isLoading
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
                          child: _buildNotificationList(),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}