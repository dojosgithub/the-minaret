import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';

class NotificationsMenuScreen extends StatefulWidget {
  const NotificationsMenuScreen({super.key});

  @override
  State<NotificationsMenuScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsMenuScreen> {
  // Switch states
  bool comments = false;
  bool share = false;
  bool upvote = false;
  bool saved = false;
  bool peopleYouMightLike = false;
  bool peopleYouMightKnow = false;

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
        child: ListView(
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
                  "Notifications",
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Interactions Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Interactions",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSwitch("Comments", comments, (value) {
              setState(() => comments = value);
            }),
            _buildSwitch("Share", share, (value) {
              setState(() => share = value);
            }),
            _buildSwitch("Upvote", upvote, (value) {
              setState(() => upvote = value);
            }),
            _buildSwitch("Saved", saved, (value) {
              setState(() => saved = value);
            }),

            // Suggestions Section
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Suggestions",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSwitch("People You Might Like", peopleYouMightLike, (value) {
              setState(() => peopleYouMightLike = value);
            }),
            _buildSwitch("People You Might Know", peopleYouMightKnow, (value) {
              setState(() => peopleYouMightKnow = value);
            }),
          ],
        ),
      ),
    );
  }

  // Helper function for switch list tiles
  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      activeColor: const Color(0xFFFDCC87), // Yellow when switched ON
      inactiveTrackColor: const Color(0xFF3B1A44), // Darker than background when OFF
      value: value,
      onChanged: onChanged,
    );
  }
}
