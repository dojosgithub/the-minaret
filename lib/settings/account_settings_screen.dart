import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';
import '../authentication/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: TopBarWithoutMenu(),
      body: Column(
        children: [
          // Back button & title section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Account Settings",
                    style: TextStyle(
                      color: Color(0xFFFDCC87),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Account options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Delete Account option
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1B45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 28,
                      ),
                      title: const Text(
                        "Delete Account",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: const Text(
                        "Permanently delete your account and all data",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Warning text
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Warning: Account deletion is permanent and cannot be undone. All your posts, comments, and personal information will be permanently removed.",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showUsernameConfirmationDialog(context);
              },
              child: const Text(
                'Proceed',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUsernameConfirmationDialog(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    bool isLoading = false;
    String? currentUsername;
    
    // Get current username for verification
    ApiService.getUserProfile().then((profile) {
      currentUsername = profile['username'];
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF3D1B45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Confirm Account Deletion',
                style: TextStyle(color: Color(0xFFFDCC87)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This action cannot be undone. Please type your username to confirm account deletion:',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your username',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFDCC87)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFDCC87)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (usernameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your username'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (usernameController.text != currentUsername) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Username does not match'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final user = await ApiService.getUserProfile();
                            final userId = user['_id'];
                            
                            await ApiService.deleteAccount(
                              userId,
                              usernameController.text,
                            );
                            
                            // Clear all user data and navigate to welcome screen
                            await ApiService.logout();
                            
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            debugPrint('Account deletion error: $e');
                            
                            // Reset loading state
                            setState(() {
                              isLoading = false;
                            });
                            
                            if (context.mounted) {
                              // Make sure we're not popping the dialog if it's already been popped
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              
                              // Show a user-friendly error message
                              String errorMessage = 'Failed to delete account';
                              if (e.toString().contains('<!DOCTYPE html>')) {
                                errorMessage = 'Server error. Please try again later.';
                              } else {
                                errorMessage = 'Failed to delete account: ${e.toString()}';
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 