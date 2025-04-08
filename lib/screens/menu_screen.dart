import 'package:flutter/material.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'user_screen.dart';
import '../utils/post_type.dart';

class MenuScreen extends StatelessWidget {
  final Function(int) onIndexChanged;

  const MenuScreen({
    super.key,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Material(
        color: const Color(0xFF9D3267),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Home
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMenuItem(
                  context,
                  'Home',
                  onTap: () {
                    PostType.setType(PostType.all);
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
                    _buildMenuItem(
                      context, 
                      'All',
                      onTap: () {
                        PostType.setType(PostType.all);
                        Navigator.pop(context);
                        onIndexChanged(0);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Reporters',
                      onTap: () {
                        PostType.setType(PostType.reporters);
                        Navigator.pop(context);
                        onIndexChanged(0);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Discussion',
                      onTap: () {
                        PostType.setType(PostType.discussion);
                        Navigator.pop(context);
                        onIndexChanged(0);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Teaching Quran',
                      onTap: () {
                        PostType.setType(PostType.teachingQuran);
                        Navigator.pop(context);
                        onIndexChanged(0);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Tafsir',
                      onTap: () {
                        PostType.setType(PostType.tafsir);
                        Navigator.pop(context);
                        onIndexChanged(0);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Sunnah',
                      onTap: () {
                        PostType.setType(PostType.sunnah);
                        Navigator.pop(context);
                        onIndexChanged(0);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildMenuItem(
                      context, 
                      'Hadith',
                      onTap: () {
                        PostType.setType(PostType.hadith);
                        Navigator.pop(context);
                        onIndexChanged(0);
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFDCC87),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
