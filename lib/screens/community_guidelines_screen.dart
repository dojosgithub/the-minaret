import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';

class CommunityGuidelinesScreen extends StatefulWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  State<CommunityGuidelinesScreen> createState() => _CommunityGuidelinesScreenState();
}

class _CommunityGuidelinesScreenState extends State<CommunityGuidelinesScreen> {
  final List<Map<String, String>> guidelines = [
    {
      "title": "Respect Others",
      "content":
          "All users should be treated with respect. Harassment, hate speech, and bullying will not be tolerated in any form."
    },
    {
      "title": "No Spam or Advertising",
      "content":
          "Avoid spamming, advertising, or promoting other platforms without permission. Keep discussions relevant and meaningful."
    },
    {
      "title": "Report Violations",
      "content":
          "If you encounter any violations of our guidelines, report them immediately so we can take appropriate action."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top Bar with Menu & Profile
      appBar: const TopBarWithoutMenu(),

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
                  "Community Guidelines",
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Expandable Sections
            Expanded(
              child: ListView.builder(
                itemCount: guidelines.length,
                itemBuilder: (context, index) {
                  return _buildExpandableSection(
                    title: guidelines[index]["title"]!,
                    content: guidelines[index]["content"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for expandable sections
  Widget _buildExpandableSection({required String title, required String content}) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      collapsedBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      children: [
        Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}
