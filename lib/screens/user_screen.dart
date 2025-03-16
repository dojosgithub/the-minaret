import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'John Doe',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '@johndoe',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('150 ', style: TextStyle(color: const Color(0xFFFDCC87), fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text('Followers', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(width: 15),
                            Text('200 ', style: TextStyle(color: const Color(0xFFFDCC87), fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text('Following', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'This is the user bio where the user describes themselves. I am testing the wrapping property beacuse it was long and it had issues and i guess it is okay?.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFDCC87), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/profile_picture.png'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabButton(0, 'Posts'),
                  _buildTabButton(1, 'Saved'),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: selectedTab == 0 ? _buildPosts() : _buildSaved(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? const Color(0xFFFDCC87) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (selectedTab == index)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: 40,
              color: const Color(0xFFFDCC87),
            ),
        ],
      ),
    );
  }

  Widget _buildPosts() {
    return Center(
      child: Text('User Posts', style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget _buildSaved() {
    return Center(
      child: Text('Saved Posts', style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}
