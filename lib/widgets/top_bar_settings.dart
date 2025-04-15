import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/settings_screen.dart';

class TopBarSettings extends StatelessWidget implements PreferredSizeWidget {
  final Function(int) onIndexChanged;

  const TopBarSettings({
    super.key,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.4, 1.0],
              colors: [
                Color(0xFF4F245A),
                Color(0xFF9D3267),
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
              Positioned.fill(
                child: Image.asset(
                  'assets/top_bar_pattern.png', 
                  fit: BoxFit.cover, 
                ),
              ),
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFFFDCC87)), // Settings icon
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                actions: [
                  // Post icon on the right
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFDCC87)), // Post icon
                    onPressed: () {
                      onIndexChanged(2); // Navigate to post screen
                    },
                  ),
                ],
              ),
              // Logo positioned at the bottom center of the bar
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    height: 65,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}