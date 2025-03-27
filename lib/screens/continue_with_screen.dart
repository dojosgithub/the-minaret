import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'registration_screen.dart'; 
import 'phone_screen.dart';
import 'login_screen.dart';

class ContinueWithScreen extends StatelessWidget {
  const ContinueWithScreen({super.key});

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

            _buildOption(context, 'Continue with Telegram', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PhoneScreen()),
              );
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
}
