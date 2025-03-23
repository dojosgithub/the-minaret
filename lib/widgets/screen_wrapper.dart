import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import '../screens/menu_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_screen.dart';
import '../screens/user_screen.dart';
import '../screens/search_screen.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const ScreenWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4F245A),
      child: Scaffold(
        drawer: const MenuScreen(),
        backgroundColor: Colors.transparent,
        appBar: TopBar(
          onMenuPressed: () {
            Scaffold.of(context).openDrawer();
          },
          onProfilePressed: () {
            debugPrint('Profile picture pressed');
          },
          profileImage: 'assets/profile_picture.png',
        ),
        body: child,
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index != currentIndex) {
              // Navigate to the selected screen
              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const PostScreen()),
                  );
                  break;
                case 3:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const UserScreen()),
                  );
                  break;
                case 4:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                  break;
              }
            }
          },
        ),
      ),
    );
  }
} 