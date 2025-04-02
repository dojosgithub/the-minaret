import 'package:flutter/material.dart';
import '../widgets/notification.dart';
import '../widgets/screen_wrapper.dart';
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

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 1,
      child: FutureBuilder<List<Map<String, dynamic>>>(
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
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
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

          return SingleChildScrollView(
            child: Column(
              children: notifications.map((notification) {
                // Parse the date string to DateTime
                final dateTime = DateTime.parse(notification['createdAt']);
                
                return NotificationWidget(
                  name: notification['sender']['username'],
                  dateTime: dateTime,
                  profilePic: notification['sender']['profileImage'] ?? 'assets/default_profile.png',
                  text: notification['message'],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}