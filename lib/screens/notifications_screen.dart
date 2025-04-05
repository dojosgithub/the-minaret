import 'package:flutter/material.dart';
import '../widgets/notification.dart';
import '../widgets/screen_wrapper.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService.getNotifications();
  }

  void _refreshNotifications() {
    setState(() {
      _notificationsFuture = ApiService.getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            );
          }

          if (snapshot.hasError) {
            return ConnectionErrorWidget(
              onRetry: _refreshNotifications,
            );
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshNotifications();
            },
            color: const Color(0xFFFDCC87),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: notifications.map((notification) {
                  final dateTime = DateTime.parse(notification['createdAt']);
                  
                  return NotificationWidget(
                    name: notification['sender']['username'],
                    dateTime: dateTime,
                    profilePic: notification['sender']['profileImage'] ?? 'assets/default_profile.png',
                    text: notification['message'],
                    senderId: notification['sender']['_id'],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}