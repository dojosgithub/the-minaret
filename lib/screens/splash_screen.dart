import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.4, 1.0],
          colors: [
            Color(0xFF4F245A),
            Color(0xFF9D3267),
          ],
        ),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/logo.svg',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          semanticsLabel: 'Minaret Logo',
        ),
      ),
    );
  }
} 