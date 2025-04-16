import 'package:flutter/foundation.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final List<MessageMedia>? media;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.media,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing message JSON: $json');
    return Message(
      id: json['_id']?.toString() ?? '',
      senderId: json['sender']?['_id']?.toString() ?? json['sender']?.toString() ?? '',
      recipientId: json['recipient']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      isRead: json['read'] ?? false,
      media: json['media'] != null 
          ? (json['media'] as List).map((m) => MessageMedia.fromJson(m)).toList()
          : null,
    );
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