import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  final Map<String, String> privacySettings = {
    "Comments": "Everyone",
    "Upvote": "Everyone",
    "Share": "Everyone",
    "Profile View": "Everyone",
  };

  final List<String> visibilityOptions = ["Everyone", "Friends", "No one"];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button & Title
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Privacy & Safety",
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Small Subtitle
            const Text(
              "Who can see",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            // Privacy Options List
            Column(
              children: privacySettings.keys.map((setting) {
                return _buildPrivacyOption(setting);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build a privacy option row
  Widget _buildPrivacyOption(String setting) {
    return InkWell(
      onTap: () => _showVisibilityDialog(setting),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _getIconForSetting(setting),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                setting,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // Icon mapping function
  Widget _getIconForSetting(String setting) {
    switch (setting) {
      case "Comments":
        return const Icon(Icons.comment_outlined, color: Colors.white);
      case "Upvote":
        return const Icon(Icons.arrow_upward, color: Colors.white);
      case "Share":
        return const Icon(Icons.reply_outlined, color: Colors.white);
      case "Profile View":
        return const Icon(Icons.remove_red_eye_outlined, color: Colors.white);
      default:
        return const Icon(Icons.security, color: Colors.white);
    }
  }

  // Popup Dialog for Selecting Privacy
  void _showVisibilityDialog(String setting) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5), // Dim background
      builder: (BuildContext context) {
        String selectedOption = privacySettings[setting]!;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur effect
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F245A), // Same as background color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: visibilityOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option,
                      style: const TextStyle(color: Color(0xFFFDCC87), fontSize: 16),
                    ),
                    activeColor: const Color(0xFFFDCC87),
                    value: option,
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        privacySettings[setting] = value!;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
