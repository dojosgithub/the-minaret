import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed; // Callback for menu icon
  final VoidCallback onMessagesPressed; // Callback for messages icon

  const TopBar({
    super.key,
    required this.onMenuPressed,
    required this.onMessagesPressed,
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
                    icon: const Icon(
                      Icons.menu,
                      color: Color(0xFFFDCC87),
                      size: 32,
                    ),
                    onPressed: onMenuPressed,
                  ),
                  actions: [
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFFFDCC87),
                            size: 32,
                          ),
                          Positioned(
                            right: 8,
                            top: 12,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFDCC87),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: onMessagesPressed,
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        width: MediaQuery.of(context).size.width * 0.45,
                        height: 36,
                        fit: BoxFit.contain,
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
