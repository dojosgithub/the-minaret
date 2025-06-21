import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'main_screens/home_screen.dart';
import 'main_screens/notifications_screen.dart';
import 'main_screens/post_screen.dart';
import 'main_screens/user_screen.dart';
import 'main_screens/search_screen.dart';
import 'authentication/welcome_screen.dart';
import 'authentication/splash_screen.dart';
import 'services/api_service.dart';
import 'widgets/screen_wrapper.dart';
import 'dart:async';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Apply system UI configurations only for mobile platforms
    if (!kIsWeb) {
      // Set SystemUiMode to edgeToEdge for transparent navigation bar support
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      
      // Ensure status bar is transparent with appropriate contrast
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ));
    }
    
    try {
      // Load environment variables with a shorter timeout for web
      await dotenv.load(fileName: ".env").timeout(
        Duration(seconds: kIsWeb ? 2 : 20),
        onTimeout: () {
          debugPrint("Dotenv load timed out, continuing anyway");
          return;
        }
      );
    } catch (e) {
      debugPrint("Error loading .env file: $e");
      // Continue without env file on web
      if (!kIsWeb) rethrow;
    }
    
    try {
      await ApiService.initialize();
    } catch (e) {
      debugPrint("Error initializing API service: $e");
      // Continue with default API settings
    }
    
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Global error caught: $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minaret',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          final isLoggedIn = snapshot.data ?? false;
          debugPrint('Initial login state: $isLoggedIn');
          return isLoggedIn ? const MainScreen() : const WelcomeScreen();
        },
      ),
    );
  }
  
  Future<bool> _checkLoginState() async {
    try {
      // Just check if token exists without validation
      final token = await ApiService.getToken();
      final hasToken = token != null && token.isNotEmpty;
      debugPrint('Token exists: $hasToken');
      return hasToken;
    } catch (e) {
      debugPrint('Error checking login state: $e');
      return false;
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const NotificationsScreen(),
      PostScreen(onIndexChanged: setIndex),
      const UserScreen(),
      SearchScreen(onIndexChanged: setIndex),
    ];
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ScreenWrapper(
        currentIndex: _currentIndex,
        onIndexChanged: setIndex,
        child: _screens[_currentIndex],
      ),
    );
  }
}
