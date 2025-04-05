import 'package:flutter/material.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'user_screen.dart';

class MenuScreen extends StatelessWidget {
  final Function(int) onIndexChanged;

  const MenuScreen({
    super.key,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Material(
        color: const Color(0xFF4F245A),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Home
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMenuItem(
                  context,
                  'Home',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    onIndexChanged(0); // Navigate to home screen
                  },
                ),
              ),

              const Divider(color: Colors.grey, height: 1),

              // Section 2: Knowledge Categories
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMenuItem(context, 'All'),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Islamic Knowledge',
                      onTap: () {
                        Navigator.pop(context); // Close drawer before navigation
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Teachings of the Quran',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Tafsir',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Sunnah',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Hadith',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.grey, height: 1),

              // Section 3: User Related
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMenuItem(
                      context, 
                      'Settings',
                      onTap: () {
                        Navigator.pop(context); // Close drawer before navigation
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Profile',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        onIndexChanged(3); // Navigate to user screen
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'About',
                      onTap: () {
                        Navigator.pop(context); // Close drawer before navigation
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
