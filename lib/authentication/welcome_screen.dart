import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'continue_with_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.06), // Moves content up based on screen size
            
            // Large Logo
            SvgPicture.asset("assets/logo.svg", height: screenHeight * 0.2), // Bigger logo
            SizedBox(height: screenHeight * 0.02),

            // App Name
            SvgPicture.asset("assets/name.svg", height: screenHeight * 0.08), // Bigger name
            SizedBox(height: screenHeight * 0.015),

            // Slogan (Smaller)
            SvgPicture.asset("assets/slogan.svg", height: screenHeight * 0.04), // Smaller slogan
            SizedBox(height: screenHeight * 0.05),

            // Choose Language Text
            const Text(
              "Please Choose your Language",
              style: TextStyle(color: Colors.white, fontSize: 18), // Slightly larger text
            ),
            SizedBox(height: screenHeight * 0.02),

            // Language Selection Box (Stacked layout)
            Container(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.02, 
                horizontal: screenWidth * 0.04
              ), // Adjusts based on screen size
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFDCC87)), // Signature yellow outline
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("سلام عليكم", style: TextStyle(color: Colors.white, fontSize: 18)),
                  SizedBox(height: screenHeight * 0.015),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.15, 
                        vertical: screenHeight * 0.015
                      ), // Scales with screen size
                    ),
                    child: const Text("Salam", style: TextStyle(fontSize: 18)),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  const Text("Paz", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
