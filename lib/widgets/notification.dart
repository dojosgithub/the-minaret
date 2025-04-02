import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

class NotificationWidget extends StatelessWidget {
  final String name;
  final String profilePic;
  final String text;
  final DateTime dateTime;

  const NotificationWidget({
    super.key,
    required this.name,
    required this.profilePic,
    required this.text,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1B45), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(52),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE4A7), 
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage(profilePic),
                  radius: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                getTimeAgo(dateTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}