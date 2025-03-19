import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import 'menu_screen.dart';

class MediaUploadScreen extends StatelessWidget {
  const MediaUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: TopBar(
        onMenuPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuScreen()),
          );
        },
        onProfilePressed: () {},
        profileImage: 'assets/profile_picture.png',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFDCC87),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/profile_picture.png'),
                    radius: 25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

              Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1B42),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                maxLines: 1,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Title of Media',
                  hintStyle: TextStyle(color: Color(0xFFFDCC87)),
                ),
              ),
            ),
            const SizedBox(height: 20),


            // Outer Box (Darker Background)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1B42),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Title Input
                  TextField(
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Body Text',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Inner Box (Translucent)
                  Container(
                    width: double.infinity,
                    height: 250, // Increased height
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3), // Translucent
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image_outlined, color: Colors.white, size: 50), // Larger icons
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            child: Text('/', style: TextStyle(color: Colors.white, fontSize: 50)),
                          ),
                          Icon(Icons.videocam_outlined, color: Colors.white, size: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.collections, color: Colors.white),
                label: const Text('Photo / Video', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1B45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link, color: Colors.white),
                label: const Text('Link', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1B45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
