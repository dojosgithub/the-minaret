import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../screens/messages_screen.dart';
import '../services/api_service.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  Map<String, String> privacySettings = {
    "comments": "Friends",
    "upvote": "Friends",
    "share": "Friends",
    "profileView": "Friends",
  };

  final List<String> visibilityOptions = ["Everyone", "Friends", "No one"];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final preferences = await ApiService.getViewPreferences();
      setState(() {
        privacySettings = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.updateViewPreferences(privacySettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top Bar with Back & Profile
      appBar: TopBar(
        onMenuPressed: () {
          Scaffold.of(context).openDrawer();
        },
        onMessagesPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MessagesScreen()),
          );
        },
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFDCC87)))
          : Padding(
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
                  Expanded(
                    child: ListView(
                      children: privacySettings.keys.map((setting) {
                        return _buildPrivacyOption(setting);
                      }).toList(),
                    ),
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
            Text(
              privacySettings[setting]!,
              style: const TextStyle(color: Color(0xFFFDCC87), fontSize: 14),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // Icon mapping function
  Widget _getIconForSetting(String setting) {
    switch (setting) {
      case "comments":
        return const Icon(Icons.comment_outlined, color: Colors.white);
      case "upvote":
        return const Icon(Icons.arrow_upward, color: Colors.white);
      case "share":
        return const Icon(Icons.reply_outlined, color: Colors.white);
      case "profileView":
        return const Icon(Icons.remove_red_eye_outlined, color: Colors.white);
      default:
        return const Icon(Icons.security, color: Colors.white);
    }
  }

  // Popup Dialog for Selecting Privacy
  Future<void> _showVisibilityDialog(String setting) async {
    String selectedOption = privacySettings[setting]!;
    
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F245A),
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
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          privacySettings[setting] = value;
                        });
                        Navigator.pop(context);
                        
                        // Update preferences immediately
                        try {
                          await ApiService.updateViewPreferences(privacySettings);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preferences updated successfully'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update preferences: $e'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
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
