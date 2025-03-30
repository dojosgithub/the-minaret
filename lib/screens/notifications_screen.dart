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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: notifications.map((notification) => NotificationWidget(
                name: notification['sender']['username'],
                date: DateTime.parse(notification['createdAt'])
                    .toLocal()
                    .toString()
                    .split(' ')[0],
                profilePic: notification['sender']['profileImage'],
                text: notification['message'],
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}