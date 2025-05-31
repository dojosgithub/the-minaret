import 'package:flutter/material.dart';
import 'notifications_menu_screen.dart';
import 'language_screen.dart';
import 'feedback_screen.dart';
import 'community_guidelines_screen.dart';
import 'privacy_and_safety_screen.dart';
import 'about_screen.dart';
import 'content_filter_screen.dart';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(color: Color(0xFFFDCC87)),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDCC87),
              ),
              onPressed: () async {
                try {
                  await ApiService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to logout'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A), // Background color of all pages
      appBar: TopBarWithoutMenu(),
      body: Column(
        children: [
          // Back button & title section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)), // Yellow back button
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10), // Space between icon and title
                const Expanded(
                  child: Text(
                    "Settings",
                    style: TextStyle(
                      color: Color(0xFFFDCC87), // Signature yellow color
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), // Add some spacing

          // Menu items inside a scrollable view
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuItem(context, "Notifications", Icons.notifications_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsMenuScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Content Filter", Icons.filter_list, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContentFilterScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Language", Icons.language_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LanguageScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Community Guidelines", Icons.groups_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CommunityGuidelinesScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Feedback", Icons.verified_user_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Privacy & Safety", Icons.lock_outline, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacySafetyScreen()),
                    );
                  }),
                  _buildMenuItem(context, "About the Minaret", Icons.info_outline, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Logout", Icons.logout, () {
                    _showLogoutDialog(context);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build menu item
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.white), 
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 18,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
