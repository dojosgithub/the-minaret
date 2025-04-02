import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import '../screens/menu_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_screen.dart';
import '../screens/user_screen.dart';
import '../screens/search_screen.dart';
import '../widgets/top_bar_settings.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class ScreenWrapper extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const ScreenWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<ScreenWrapper> createState() => _ScreenWrapperState();
}

class _ScreenWrapperState extends State<ScreenWrapper> {
  String? profileImage;
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          profileImage = userData['profileImage'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4F245A),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MenuScreen(),
        drawerEdgeDragWidth: 0, // Disable swipe gesture to open drawer
        backgroundColor: Colors.transparent,
        appBar: widget.currentIndex == 4 // Check if it's the SearchScreen
            ? const TopBarSettings()
            : TopBar(
                onMenuPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                onProfilePressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserScreen()),
                  );
                },
                profileImage: profileImage,
              ),
        body: widget.child,
        bottomNavigationBar: BottomNavBar(
          currentIndex: widget.currentIndex,
          onTap: (index) {
            if (index != widget.currentIndex) {
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