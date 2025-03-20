import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'continue_with_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4F245A), Color(0xFF3D1B45)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large Logo
            SvgPicture.asset("assets/logo.svg", height: 100),
            const SizedBox(height: 10),

            // App Name
            SvgPicture.asset("assets/name.svg", height: 50),
            const SizedBox(height: 5),

            // Slogan
            SvgPicture.asset("assets/slogan.svg", height: 30),
            const SizedBox(height: 20),

            // Choose Language Text
            const Text(
              "Choose your language",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 10),

            // Language Selection Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFDCC87)), // Signature yellow outline
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("سلام عليكم", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContinueWithScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text("Salam"),
                  ),
                  const SizedBox(width: 10),
                  const Text("Paz", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
