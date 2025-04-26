import 'package:flutter/foundation.dart';
import '../widgets/post.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final List<MessageMedia>? media;
  final String? postId;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.media,
    this.postId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing message JSON: $json');
    try {
      // Handle sender ID - it could be a string or a populated object
      String senderId;
      if (json['sender'] is Map<String, dynamic>) {
        senderId = json['sender']['_id']?.toString() ?? '';
      } else {
        senderId = json['sender']?.toString() ?? '';
      }

      // Handle post - it could be a string ID or a populated object
      String? postId;
      if (json['post'] != null) {
        if (json['post'] is Map<String, dynamic>) {
          postId = json['post']['_id']?.toString();
        } else {
          postId = json['post']?.toString();
        }
      }

      return Message(
        id: json['_id']?.toString() ?? '',
        senderId: senderId,
        recipientId: json['recipient']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        isRead: json['read'] ?? false,
        media: json['media'] != null 
            ? (json['media'] as List).map((m) => MessageMedia.fromJson(m)).toList()
            : null,
        postId: postId,
      );
    } catch (e) {
      debugPrint('Error parsing message: $e');
      debugPrint('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': senderId,
      'recipient': recipientId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'read': isRead,
      'media': media?.map((m) => m.toJson()).toList(),
      'post': postId,
    };
  }
}

class MessageMedia {
  final String type;
  final String url;

  MessageMedia({
    required this.type,
    required this.url,
  });

  factory MessageMedia.fromJson(Map<String, dynamic> json) {
    return MessageMedia(
      type: json['type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
    };
  }
} 