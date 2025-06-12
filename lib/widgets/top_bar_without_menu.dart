import 'package:flutter/material.dart';

class TopBarWithoutMenu extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWithoutMenu({super.key});

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
                  automaticallyImplyLeading: false,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Use MediaQuery for more reliable sizing
                          final mediaQuery = MediaQuery.of(context);
                          final screenWidth = mediaQuery.size.width;
                          final screenHeight = mediaQuery.size.height;
                          
                          // Calculate logo size based on screen dimensions
                          final logoWidth = (screenWidth * 0.5).clamp(120.0, 250.0);
                          final logoHeight = (logoWidth * 0.3).clamp(36.0, 75.0);

                          return Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: logoWidth,
                              height: logoHeight,
                              fit: BoxFit.contain,
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
