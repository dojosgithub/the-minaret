import 'package:flutter/material.dart';
import '../widgets/post.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            Post(
              name: 'John Doe',
              username: 'johndoe',
              profilePic: 'assets/profile_picture.png',
              text: 'This is my second post. Happy to be a part of the Minaret Community!',
            ),
              Post(
              name: 'John Doe',
              username: 'johndoe',
              profilePic: 'assets/profile_picture.png',
              text: 'This is a sample post. Excited to be here!',
            ),
          ],
        ),
      ),
    );
  }
}
