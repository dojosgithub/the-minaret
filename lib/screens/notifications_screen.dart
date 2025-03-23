import 'package:flutter/material.dart';
import '../widgets/notification.dart';
import '../widgets/screen_wrapper.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 1,
      child: SingleChildScrollView(
        child: Column(
          children: const [
            NotificationWidget(
              name: 'John Doe',
              date: '14/3/2025',
              profilePic: 'assets/profile_picture.png',
              text: 'Joined the Community, Say Hi!',
            ),
            NotificationWidget(
              name: 'John Doe',
              date: '14/3/2025',
              profilePic: 'assets/profile_picture.png',
              text: 'Added You as a Friend!',
            ),
          ],
        ),
      ),
    );
  }
}