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
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 5;
    double indentHeight = 85; 
    double navBarHeight = 70;

    return Stack(
      clipBehavior: Clip.none,
      children: [
      ClipPath(
        clipper: BottomNavClipper(currentIndex, itemWidth, indentHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Curved top edges
          child: Container(
            height: navBarHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF9D3267),
              boxShadow: [
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
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 28,
              items: List.generate(5, (index) => _buildNavItem(index, currentIndex)),
            ),
          ),
        ),
      ),

     
        Positioned(
          bottom: 45, 
          left: (itemWidth * currentIndex) + (itemWidth / 2) - 30,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFF9D3267),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getIcon(currentIndex),
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        
        Positioned(
          bottom: 5, // Push label to the far bottom
          left: itemWidth * currentIndex,
          width: itemWidth, // Ensure it takes the full width of one item
          child: Center( // Centers the text properly under the selected icon
            child: Text(
              _getLabel(currentIndex),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(int index, int selectedIndex) {
    return BottomNavigationBarItem(
      icon: index == selectedIndex ? const SizedBox.shrink() : Icon(_getIcon(index)),
      label: '', // Hide all labels inside BottomNavigationBar
    );
  }

IconData _getIcon(int index) {
  switch (index) {
    case 0:
      return Icons.home_outlined; // Hollow home icon
    case 1:
      return Icons.notifications_none; // Hollow notification icon
    case 2:
      return Icons.add; // Bold add icon
    case 3:
      return Icons.person_outline; // Hollow profile icon
    case 4:
      return Icons.search_outlined; // Hollow search icon
    default:
      return Icons.error_outline; // Hollow error icon
  }
}

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Notifications';
      case 2:
        return 'Post';
      case 3:
        return 'Profile';
      case 4:
        return 'Search';
      default:
        return '';
    }
  }
}

// Custom Clipper for Indent (No Changes)
class BottomNavClipper extends CustomClipper<Path> {
  final int selectedIndex;
  final double itemWidth;
  final double indentHeight;

  BottomNavClipper(this.selectedIndex, this.itemWidth, this.indentHeight);

  @override
  Path getClip(Size size) {
    Path path = Path();
    double indentCenter = (selectedIndex * itemWidth) + (itemWidth / 2);
    double indentWidth = 65; // Keep indent width as is

    path.lineTo(indentCenter - indentWidth, 0);
    path.quadraticBezierTo(indentCenter, indentHeight, indentCenter + indentWidth, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
