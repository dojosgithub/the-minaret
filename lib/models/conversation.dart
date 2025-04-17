import 'package:flutter/foundation.dart';
import 'message.dart';

class Conversation {
  final String id;
  final List<Map<String, dynamic>> participants;
  final Map<String, dynamic>? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'],
      participants: List<Map<String, dynamic>>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  String getOtherParticipant(String currentUserId) {
    final otherParticipant = participants.firstWhere(
      (p) => p['_id'] != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant['_id'];
  }
} 