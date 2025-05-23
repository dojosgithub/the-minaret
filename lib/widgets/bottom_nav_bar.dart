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
    double indentHeight = 75;
    double navBarHeight = 75;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main nav bar with proper clipping
        Padding(
          padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base container with clipping
              ClipPath(
                clipper: BottomNavClipper(currentIndex, itemWidth, indentHeight),
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
              ),
              
              // Custom navbar items row
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: navBarHeight - 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(5, (index) {
                      // Don't show the icon for the selected tab
                      if (index == currentIndex) {
                        return SizedBox(width: itemWidth);
                      }
                      
                      return GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: itemWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                _getIconPath(index),
                                height: 20,
                                width: 20,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getLabel(index),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              
              // Selected tab indicator & icon
              Positioned(
                bottom: 45,
                left: (itemWidth * currentIndex) + (itemWidth / 2) - 20,
                child: Container(
                  width: 40,
                  height: 40,
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
                    padding: const EdgeInsets.all(10),
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
              
              // Selected tab label
              Positioned(
                bottom: 10,
                left: itemWidth * currentIndex,
                width: itemWidth,
                child: Center(
                  child: Text(
                    _getLabel(currentIndex),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // iOS safe area extension (only shows on iOS devices with home bar)
        if (bottomPadding > 0)
          Container(
            height: bottomPadding - 10,
            color: const Color(0xFF9D3267),
          ),
      ],
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

// Custom Clipper for Indent
class BottomNavClipper extends CustomClipper<Path> {
  final int selectedIndex;
  final double itemWidth;
  final double indentHeight;

  BottomNavClipper(this.selectedIndex, this.itemWidth, this.indentHeight);

  @override
  Path getClip(Size size) {
    Path path = Path();
    double indentCenter = (selectedIndex * itemWidth) + (itemWidth / 2);
    double indentWidth = 40; // Slightly wider indent for better appearance (was 38)

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
