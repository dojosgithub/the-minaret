import 'package:flutter/material.dart';
import 'registration_screen.dart'; // Import the registration screen

class ContinueWithScreen extends StatelessWidget {
  const ContinueWithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F245A), Color(0xFF3D1B45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 100),
            const SizedBox(height: 30),
            _buildOption(context, 'Continue with Email', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegistrationScreen()),
              );
            }),
            const SizedBox(height: 15),
            _buildOption(context, 'Continue with WhatsApp', () {
              // Add WhatsApp functionality here
            }),
            const SizedBox(height: 15),
            _buildOption(context, 'Continue with Telegram', () {
              // Add Telegram functionality here
            }),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                // Add login navigation functionality here
              },
              child: const Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.white),
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
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFFDCC87), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
