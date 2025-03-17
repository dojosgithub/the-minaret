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
        height: 120, // Increased height for a wider top bar
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4F245A), // Background color of all pages (Top)
              Color(0xFF9D3267), // Current Top Bar color (Bottom)
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AppBar(
              backgroundColor: Colors.transparent, // Transparent background
              elevation: 0, // Remove default elevation
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFFFDCC87)), // Menu icon (three bars)
                onPressed: onMenuPressed,
              ),
              actions: [
                // Profile picture on the right
                GestureDetector(
                  onTap: onProfilePressed,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(profileImage),
                      radius: 18, // Slightly bigger profile image
                    ),
                  ),
                ),
              ],
            ),
            // Logo positioned at the bottom center of the bar
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10), // Push logo closer to bottom
                child: Image.asset(
                  'assets/logo.png', // Path to the logo image
                  height: 65, // Slightly larger logo
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120); // Custom height for the top bar
}
