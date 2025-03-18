import 'package:flutter/material.dart';
import 'notifications_menu_screen.dart';
import 'language_screen.dart';
import '../widgets/top_bar.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A), // Background color of all pages
      appBar: TopBar(
        onMenuPressed: () {},
        onProfilePressed: () {},
        profileImage: 'assets/profile_picture.png',
      ),
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
                  _buildMenuItem(context, "Language", Icons.language_outlined, () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LanguageScreen()),
                    );
                  }),
                  _buildMenuItem(context, "Community Guidelines", Icons.groups_outlined, () {}),
                  _buildMenuItem(context, "Feedback", Icons.verified_user_outlined, () {}),
                  _buildMenuItem(context, "Privacy & Safety", Icons.lock_outline, () {}),
                  _buildMenuItem(context, "About the Minaret", Icons.info_outline, () {}),
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
        leading: Icon(icon, color: Colors.white), // Icons moved to the left
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white, // White text for readability
            fontSize: 18,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
