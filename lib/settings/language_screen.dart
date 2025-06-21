import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguageScreen> {
  String selectedLanguage = "English"; // Default selected language

  final List<String> languages = [
    "English",
    "Arabic",
    "Catalan",
    "Chinese (Simplified)",
    "Croatian",
    "Danish",
    "Dutch",
    "Finnish",
    "French",
    "German",
    "Greek",
    "Indonesian",
    "Italian",
    "Japanese",
    "Norwegian",
    "Polish",
    "Portuguese",
    "Portuguese (Brazilian)",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top App Bar with Logo & Menu Button
      appBar: const TopBarWithoutMenu(),

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
                  "Language",
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Language List with Radio Buttons
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  return _buildRadioTile(languages[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for language radio buttons
  Widget _buildRadioTile(String language) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Radio<String>(
              value: language,
              groupValue: selectedLanguage,
              activeColor: const Color(0xFFFDCC87), // Yellow when selected
              fillColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? const Color(0xFFFDCC87) // Yellow when active
                      : Colors.grey), // Grey when inactive
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
