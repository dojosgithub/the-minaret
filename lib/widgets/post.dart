import 'package:flutter/material.dart';

class Post extends StatelessWidget {
  final String name;
  final String username;
  final String profilePic;
  final String text;

  const Post({
    super.key,
    required this.name,
    required this.username,
    required this.profilePic,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1B45), // Darker background color
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFDCC87),
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage(profilePic),
                  radius: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '@$username',
                              style: const TextStyle(
                                color: Color(0xFFFDCC87),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: Color(0xFFFDCC87),
                          ),
                          onPressed: () {
                            // Bookmark functionality can be implemented later
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, color: Color(0xFFFDCC87)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.repeat, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}