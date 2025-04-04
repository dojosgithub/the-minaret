import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/post_screen.dart';
import 'screens/user_screen.dart';
import 'screens/search_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  runApp(const MyApp());
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
      home: const WelcomeScreen(), // Set WelcomeScreen as the initial screen
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final int _currentIndex = 0; //final added

  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationsScreen(),
    const PostScreen(),
    const UserScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return _screens[_currentIndex];
  }
}
