import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import '../services/api_service.dart';
import 'apple_registration_screen.dart';
import 'registration_screen.dart'; 
import 'phone_screen.dart';
import 'login_screen.dart';

class ContinueWithScreen extends StatelessWidget {
  const ContinueWithScreen({super.key});

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
            image: DecorationImage(
            image: AssetImage("assets/splash_screen_pattern.png"),
            fit: BoxFit.cover,
            opacity: 1.0, // Max opacity
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.5, 0.9], 
            colors: [Color(0xFF4F245A), Color(0xFF9D3267)], // Updated gradient
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 2), // Push logo down slightly
            SvgPicture.asset(
              'assets/logo.svg',
              height: screenHeight * 0.2,
            ),
            const Spacer(flex: 1), // Maintain same space between logo & buttons

            // Continue options
            _buildOption(context, 'Continue with Email', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegistrationScreen()),
              );
            }, screenWidth),

            SizedBox(height: screenHeight * 0.02),

            _buildOption(context, 'Continue with WhatsApp', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PhoneScreen()),
              );
            }, screenWidth),

            SizedBox(height: screenHeight * 0.02),

            _buildOption(context, 'Continue with Apple', () {
              _signInWithApple(context);
            }, screenWidth),

            const Spacer(flex: 1), // Push login text downward

            // Login text
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  children: [
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(
                        color: Color(0xFFFDCC87),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 1), // Keep spacing at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, VoidCallback onTap, double screenWidth) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.8, // Scales button width dynamically
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFFDCC87), width: 2),
          borderRadius: BorderRadius.circular(30), // More rounded edges
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
            ),
          );
        },
      );
      
      // Generate a nonce and its SHA-256 hash for Apple Sign In
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      
      // Request credential for the sign-in
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      
      // Use the credential to authenticate with your backend
      final authResult = await ApiService.loginWithApple(
        idToken: appleCredential.identityToken!,
        firstName: appleCredential.givenName,
        lastName: appleCredential.familyName,
        email: appleCredential.email,
      );
      
      // Navigate to login screen on success
      if (!context.mounted) return;
      Navigator.pop(context); // Remove loading indicator
      
      if (authResult) {
        // Navigate to Apple Registration screen to collect additional info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppleRegistrationScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to authenticate with server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator and show error
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in with Apple failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
