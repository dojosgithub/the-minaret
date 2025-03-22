import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopBarWithoutMenu extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWithoutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 110,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SvgPicture.asset(
                'assets/logo.svg',
                height: 65,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
