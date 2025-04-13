import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

class Comment extends StatelessWidget {
  final String authorName;
  final String authorUsername;
  final String authorProfilePic;
  final String text;
  final String createdAt;
  final List<Map<String, dynamic>> replies;
  final VoidCallback onReply;

  const Comment({
    super.key,
    required this.authorName,
    required this.authorUsername,
    required this.authorProfilePic,
    required this.text,
    required this.createdAt,
    required this.replies,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1B45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(authorProfilePic),
                radius: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@$authorUsername',
                    style: const TextStyle(
                      color: Color(0xFFFDCC87),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTimeAgo(DateTime.parse(createdAt)),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: onReply,
                child: const Text(
                  'Reply',
                  style: TextStyle(color: Color(0xFFFDCC87)),
                ),
              ),
            ],
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...replies.map((reply) => Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _ReplyWidget(
                authorName: '${reply['author']['firstName']} ${reply['author']['lastName']}',
                authorUsername: reply['author']['username'],
                authorProfilePic: reply['author']['profileImage'],
                text: reply['text'],
                createdAt: reply['createdAt'],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }
}

class _ReplyWidget extends StatelessWidget {
  final String authorName;
  final String authorUsername;
  final String authorProfilePic;
  final String text;
  final String createdAt;

  const _ReplyWidget({
    required this.authorName,
    required this.authorUsername,
    required this.authorProfilePic,
    required this.text,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1B45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(authorProfilePic),
                radius: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@$authorUsername',
                    style: const TextStyle(
                      color: Color(0xFFFDCC87),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            getTimeAgo(DateTime.parse(createdAt)),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 