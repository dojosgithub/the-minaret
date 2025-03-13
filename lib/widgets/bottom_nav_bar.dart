import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allow icons to protrude
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF9D3267),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.transparent, // Hide default selected icon
              unselectedItemColor: Colors.white70,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 28,
              selectedFontSize: 0,
              unselectedFontSize: 0,
              items: List.generate(5, (index) => _buildNavItem(index)),
            ),
          ),
        ),
        if (currentIndex >= 0)
          Positioned(
            bottom: 20, // Indent effect
            left: (MediaQuery.of(context).size.width / 5) * currentIndex + (MediaQuery.of(context).size.width / 10) - 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF7A1E4D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getIcon(currentIndex),
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        _getIcon(index),
      ),
      label: '',
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0: return Icons.home;
      case 1: return Icons.notifications;
      case 2: return Icons.add_circle;
      case 3: return Icons.person;
      case 4: return Icons.search;
      default: return Icons.error;
    }
  }
}
