import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top App Bar with Logo & Menu Button
      appBar: TopBar(
        onMenuPressed: () => Navigator.pop(context),
        onProfilePressed: () {},
        profileImage: 'assets/profile_picture.png',
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  "Feedback",
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Name TextField
            _buildTextField(controller: _nameController, hint: "Name"),

            const SizedBox(height: 15),

            // Email TextField
            _buildTextField(controller: _emailController, hint: "Email"),

            const SizedBox(height: 20),

            // Subtitle
            const Text(
              "Share your experience in scaling",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),

            const SizedBox(height: 8),

            // Expandable Comments Box
            Expanded(
              child: _buildTextField(
                controller: _commentsController,
                hint: "Add your comments...",
                maxLines: null, // Expandable
                expands: true, // Ensures it fits inside the screen
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button (Floating Right)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDCC87), // Yellow Color
                  foregroundColor: Colors.black, // Text color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Handle submit action
                },
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    bool expands = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2), // Darker than background
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        expands: expands,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none, // Removes default border
        ),
      ),
    );
  }
}
