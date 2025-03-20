import 'package:flutter/material.dart';

class TopBarWithoutMenu extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWithoutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure full width
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.2, 0.8], // Pushes the dark color further down
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)), // Curved edges
      ),
      child: SafeArea( // Ensures it adapts to different screen notches
        child: SizedBox(
          height: 110, // Fixed height
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10), // Slightly above bottom
              child: Image.asset(
                'assets/logo.png', // Path to your logo
                height: 65, // Slightly larger logo
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120); // Custom height for the top bar
}
