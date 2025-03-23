import 'package:flutter/material.dart';
import '../widgets/post.dart';
import '../widgets/screen_wrapper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 0, // This is the home screen index
      child: SingleChildScrollView(
        child: Column(
          children: const [
            Post(
              name: 'John Doe',
              username: 'johndoe',
              profilePic: 'assets/profile_picture.png',
              text: 'This is my second post. Happy to be a part of the Minaret Community!',
              upvoteCount: 56, 
              downvoteCount: 5, 
              repostCount: 85,
            ),
              Post(
              name: 'John Doe',
              username: 'johndoe',
              profilePic: 'assets/profile_picture.png',
              text: 'This is a sample post. Excited to be here!',
              upvoteCount: 200, 
              downvoteCount: 3, 
              repostCount: 12,
            ),
          ],
        ),
      ),
    );
  }
}
