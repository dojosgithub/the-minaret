import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../screens/profile_screen.dart';
import '../screens/user_screen.dart';
import '../services/api_service.dart';
import '../screens/post_detail_screen.dart';

class NotificationWidget extends StatelessWidget {
  final String name;
  final String profilePic;
  final String text;
  final DateTime dateTime;
  final String senderId;
  final String? postId;
  final String? notificationId;
  final bool isRead;

  const NotificationWidget({
    super.key,
    required this.name,
    required this.profilePic,
    required this.text,
    required this.dateTime,
    required this.senderId,
    this.postId,
    this.notificationId,
    this.isRead = false,
  });

  Future<void> _navigateToProfile(BuildContext context) async {
    try {
      // Mark notification as read if it has an ID
      if (notificationId != null && !isRead) {
        await ApiService.markNotificationAsRead(notificationId!);
      }
      
      // Get current user's ID
      final currentUser = await ApiService.getUserProfile();
      final currentUserId = currentUser['_id'].toString();

      // Navigate to appropriate screen based on whether it's the current user
      if (senderId.toString() == currentUserId) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: senderId.toString()),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to profile: $e');
    }
  }

  Future<void> _navigateToPost(BuildContext context) async {
    if (postId != null && postId!.isNotEmpty) {
      // Mark notification as read if it has an ID
      if (notificationId != null && !isRead) {
        try {
          await ApiService.markNotificationAsRead(notificationId!);
        } catch (e) {
          debugPrint('Error marking notification as read: $e');
        }
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: postId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: postId != null && postId!.isNotEmpty 
          ? () => _navigateToPost(context)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF3D1B45),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(52),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFE4A7), 
                    ),
                    child: CircleAvatar(
                      backgroundImage: profilePic.startsWith('assets/')
                          ? AssetImage(profilePic)
                          : NetworkImage(ApiService.resolveImageUrl(profilePic)) as ImageProvider,
                      radius: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (postId != null && postId!.isNotEmpty)
                  const Text(
                    "Tap to view post",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFDCC87),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  const SizedBox(),
                Text(
                  getTimeAgo(dateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}