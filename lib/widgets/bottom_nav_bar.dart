import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    double indentHeight = 65;
    double navBarHeight = 70;

    return Stack(
      clipBehavior: Clip.none,
      children: [
      ClipPath(
        clipper: BottomNavClipper(currentIndex, itemWidth, indentHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              iconSize: 24,
              items: List.generate(5, (index) => _buildNavItem(index, currentIndex)),
            ),
          ),
        ),
      ),

     
        Positioned(
          bottom: 50,
          left: (itemWidth * currentIndex) + (itemWidth / 2) - 25,
          child: Container(
            width: 50,
            height: 50,
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                _getIconPath(currentIndex),
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        
        Positioned(
          bottom: 5,
          left: itemWidth * currentIndex,
          width: itemWidth,
          child: Center(
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
      icon: index == selectedIndex 
          ? const SizedBox.shrink() 
          : Container(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    color: Colors.transparent,
                  ),
                  SvgPicture.asset(
                    _getIconPath(index),
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
      label: '',
    );
  }

  String _getIconPath(int index) {
    switch (index) {
      case 0:
        return 'assets/home.svg';
      case 1:
        return 'assets/bell.svg';
      case 2:
        return 'assets/add.svg';
      case 3:
        return 'assets/user.svg';
      case 4:
        return 'assets/search.svg';
      default:
        return 'assets/home.svg';
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
    double indentWidth = 45;

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
