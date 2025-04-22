import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../screens/messages_screen.dart';
import '../services/api_service.dart';

class NotificationsMenuScreen extends StatefulWidget {
  const NotificationsMenuScreen({super.key});

  @override
  State<NotificationsMenuScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsMenuScreen> {
  // Switch states
  bool comments = true;
  bool share = true;
  bool upvote = true;
  bool saved = true;
  bool peopleYouMightLike = true;
  bool peopleYouMightKnow = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final userData = await ApiService.getUserProfile();
      final preferences = userData['notificationPreferences'] ?? {};
      
      setState(() {
        comments = preferences['comments'] ?? true;
        share = preferences['share'] ?? true;
        upvote = preferences['upvote'] ?? true;
        saved = preferences['saved'] ?? true;
        peopleYouMightLike = preferences['peopleYouMightLike'] ?? true;
        peopleYouMightKnow = preferences['peopleYouMightKnow'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationPreference(String key, bool value) async {
    try {
      // Update the state first for immediate UI feedback
      setState(() {
        switch (key) {
          case 'comments':
            comments = value;
            break;
          case 'share':
            share = value;
            break;
          case 'upvote':
            upvote = value;
            break;
          case 'saved':
            saved = value;
            break;
          case 'peopleYouMightLike':
            peopleYouMightLike = value;
            break;
          case 'peopleYouMightKnow':
            peopleYouMightKnow = value;
            break;
        }
      });

      // Send the update to the server
      await ApiService.updateProfile({
        'notificationPreferences': {
          'comments': comments,
          'share': share,
          'upvote': upvote,
          'saved': saved,
          'peopleYouMightLike': peopleYouMightLike,
          'peopleYouMightKnow': peopleYouMightKnow,
        }
      });

      // Refresh the preferences to ensure they're in sync
      await _loadNotificationPreferences();
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
      // Revert the change if the update failed
      setState(() {
        switch (key) {
          case 'comments':
            comments = !value;
            break;
          case 'share':
            share = !value;
            break;
          case 'upvote':
            upvote = !value;
            break;
          case 'saved':
            saved = !value;
            break;
          case 'peopleYouMightLike':
            peopleYouMightLike = !value;
            break;
          case 'peopleYouMightKnow':
            peopleYouMightKnow = !value;
            break;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update notification preference')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top App Bar with Logo & Menu Button
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            )
          : Padding(
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
                    _updateNotificationPreference('comments', value);
                  }),
                  _buildSwitch("Share", share, (value) {
                    setState(() => share = value);
                    _updateNotificationPreference('share', value);
                  }),
                  _buildSwitch("Upvote", upvote, (value) {
                    setState(() => upvote = value);
                    _updateNotificationPreference('upvote', value);
                  }),
                  _buildSwitch("Saved", saved, (value) {
                    setState(() => saved = value);
                    _updateNotificationPreference('saved', value);
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
                    _updateNotificationPreference('peopleYouMightLike', value);
                  }),
                  _buildSwitch("People You Might Know", peopleYouMightKnow, (value) {
                    setState(() => peopleYouMightKnow = value);
                    _updateNotificationPreference('peopleYouMightKnow', value);
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
