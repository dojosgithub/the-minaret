import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import '../screens/menu_screen.dart';
import '../widgets/top_bar_settings.dart';
import '../services/api_service.dart';
import '../screens/messages_screen.dart';

class ScreenWrapper extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onIndexChanged;

  const ScreenWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onIndexChanged,
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
    // Set SystemUiMode to edgeToEdge to enable transparent system navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Make status bar fully transparent
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        // Make system navigation bar transparent
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        // Set system navigation bar icons to appropriate color based on theme
        systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      ),
      child: Container(
        color: const Color(0xFF4F245A),
        child: PopScope(
          canPop: widget.currentIndex == 0, // Only allow pop from home screen (which should actually be false anyway)
          child: Material(
            color: Colors.transparent,
            child: Scaffold(
              key: _scaffoldKey,
              drawer: MenuScreen(
                onIndexChanged: widget.onIndexChanged,
              ),
              drawerEdgeDragWidth: 0, // Disable swipe gesture to open drawer
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true, // Important - extend body behind appbar
              extendBody: true, // Extend body behind bottom nav
              appBar: widget.currentIndex == 4 // Check if it's the SearchScreen
                  ? TopBarSettings(
                      onIndexChanged: widget.onIndexChanged,
                    )
                  : TopBar(
                      onMenuPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      onMessagesPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MessagesScreen()),
                        );
                      },
                    ),
              body: widget.child,
              bottomNavigationBar: BottomNavBar(
                currentIndex: widget.currentIndex,
                onTap: (index) {
                  if (index != widget.currentIndex) {
                    widget.onIndexChanged(index);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}