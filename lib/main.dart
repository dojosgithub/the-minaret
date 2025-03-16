import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/post_screen.dart';
import 'screens/user_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/top_bar.dart';

void main() {
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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Track the selected index

  // List of screens corresponding to each navigation bar item
  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationsScreen(),
    const PostScreen(),
    const UserScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4F245A),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: TopBar(
        onMenuPressed: () {
          // Add menu functionality here
          print('Menu button pressed');
        },  
        onProfilePressed: () {
          // Add profile functionality here
          print('Profile picture pressed');
        },
        profileImage: 'assets/profile_picture.png', // Path to your profile picture
      ),
      body: _screens[_currentIndex], // Display the selected screen
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex, // Pass the current index
        onTap: (index) {
          // Update the state to change the selected index
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      )
    );
  }
}