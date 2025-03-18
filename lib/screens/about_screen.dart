import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top Bar with Back & Profile
      appBar: TopBar(
        onMenuPressed: () => Navigator.pop(context),
        onProfilePressed: () {},
        profileImage: 'assets/profile_picture.png',
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(  // Prevents content overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Arrow & Title
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "About the Minaret",
                    style: TextStyle(
                      color: Color(0xFFFDCC87),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // App Description
              const Text(
                "Welcome to our app – a platform designed for engaging discussions, sharing insights, and scaling your experiences with a vibrant community. Whether you're here to participate in meaningful conversations, provide feedback, or manage your privacy settings, our app offers a seamless and user-friendly experience.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),

              const Text(
                "Features:",
                style: TextStyle(
                  color: Color(0xFFFDCC87),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                "• Personalized Privacy & Safety settings allowing control over who can comment, upvote, share, and view your profile.\n\n"
                "• Community Guidelines that ensure a respectful and positive experience for all users.\n\n"
                "• A structured feedback system where you can share your experience and help improve the platform.\n\n"
                "• A seamless language selection experience to navigate in your preferred language.\n\n"
                "• A beautiful, intuitive UI with a unique theme designed for clarity and ease of use.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),

              const Text(
                "Thank you for being a part of our community. We hope you have a great experience!",
                style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
