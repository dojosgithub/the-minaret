import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top Bar with Back & Profile
      appBar: const TopBarWithoutMenu(),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.015),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFFFDCC87),
                      size: screenWidth * 0.06,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    "About The Minaret",
                    style: TextStyle(
                      color: const Color(0xFFFDCC87),
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),

              // App Description
              Text(
                "Welcome to The Minaret – a platform designed for engaging discussions, sharing insights, and scaling your experiences with a vibrant community. Whether you're here to participate in meaningful conversations, provide feedback, or manage your privacy settings, our app offers a seamless and user-friendly experience.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),

              Text(
                "Features:",
                style: TextStyle(
                  color: const Color(0xFFFDCC87),
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),

              Text(
                "• Personalized Privacy & Safety settings allowing control over who can comment, upvote, share, and view your profile.\n\n"
                "• Community Guidelines that ensure a respectful and positive experience for all users.\n\n"
                "• A structured feedback system where you can share your experience and help improve the platform.\n\n"
                "• A beautiful, intuitive UI with a unique theme designed for clarity and ease of use.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),

              Text(
                "Thank you for being a part of our community. We hope you have a great experience!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
