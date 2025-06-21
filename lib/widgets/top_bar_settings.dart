import 'package:flutter/material.dart';
import '../settings/settings_screen.dart';

class TopBarSettings extends StatelessWidget implements PreferredSizeWidget {
  final Function(int) onIndexChanged;

  const TopBarSettings({
    super.key,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/top_bar_pattern.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Color(0xFFFDCC87),
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  title: Center(
                    child: Image.asset(
                      'assets/logo.png',
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFFFDCC87),
                        size: 32,
                      ),
                      onPressed: () {
                        onIndexChanged(2);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}