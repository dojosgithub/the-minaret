import 'package:flutter/foundation.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final bool read;
  final String? postId;
  final String? profileId;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    required this.read,
    this.postId,
    this.profileId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      // Handle sender which can be either an object or a string ID
      String senderId;
      if (json['sender'] is Map) {
        senderId = json['sender']['_id'] ?? '';
      } else {
        senderId = json['sender']?.toString() ?? '';
      }
      
      // Handle recipient which can be either an object or a string ID
      String recipientId;
      if (json['recipient'] is Map) {
        recipientId = json['recipient']['_id'] ?? '';
      } else {
        recipientId = json['recipient']?.toString() ?? '';
      }
      
      // Handle post which can be either an object or a string ID
      String? postId;
      if (json['post'] != null) {
        if (json['post'] is Map) {
          postId = json['post']['_id'];
        } else {
          postId = json['post'].toString();
        }
      }
      
      // Handle profile which can be either an object or a string ID
      String? profileId;
      if (json['profile'] != null) {
        if (json['profile'] is Map) {
          profileId = json['profile']['_id'];
        } else {
          profileId = json['profile'].toString();
        }
      }
      
      return Message(
        id: json['_id'] ?? '',
        senderId: senderId,
        recipientId: recipientId,
        content: json['content'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        read: json['read'] ?? false,
        postId: postId,
        profileId: profileId,
      );
    } catch (e) {
      debugPrint('Error parsing Message: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': {'_id': senderId},
      'recipient': {'_id': recipientId},
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
      if (postId != null) 'post': postId,
      if (profileId != null) 'profile': profileId,
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