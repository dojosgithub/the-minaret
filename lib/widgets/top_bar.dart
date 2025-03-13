import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed; // Callback for menu icon
  final VoidCallback onProfilePressed; // Callback for profile picture
  final String profileImage; // Path to the profile picture

  const TopBar({
    super.key,
    required this.onMenuPressed,
    required this.onProfilePressed,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), // Curved edges
      child: Container(
        height: 100, // Increased height for wider top bar
        decoration: const BoxDecoration(
          color: Color(0xFF9D3267), // Same color as the nav bar
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0, // Remove default elevation
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.yellow), // Menu icon (three bars)
            onPressed: onMenuPressed,
          ),
          title: Image.asset(
            'assets/logo.png', // Path to the logo image
            height: 60, // Larger logo
          ),
          centerTitle: true,
          actions: [
            // Profile picture on the right
            GestureDetector(
              onTap: onProfilePressed,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundImage: AssetImage(profileImage),
                  radius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100); // Custom height for the top bar
}