import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

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
      height: 110,
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
                  toolbarHeight: 52,
                  leading: IconButton(
                    icon: const Icon(Icons.settings, color: Color(0xFFFDCC87)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFDCC87)),
                      onPressed: () {
                        onIndexChanged(2);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final logoWidth = (constraints.maxWidth * 0.6).clamp(144.0, 264.0);
                          final logoHeight = (constraints.maxHeight * 0.54).clamp(43.0, 72.0);
                          return Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.asset(
                                'assets/logo.png',
                                width: logoWidth,
                                height: logoHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(110);
}