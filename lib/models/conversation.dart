import 'package:flutter/foundation.dart';

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
    debugPrint('Parsing conversation JSON: $json');
    try {
      return Conversation(
        id: json['_id']?.toString() ?? '',
        participants: List<Map<String, dynamic>>.from(json['participants'] ?? []),
        lastMessage: json['lastMessage'] != null 
            ? Map<String, dynamic>.from(json['lastMessage'])
            : null,
        lastMessageAt: json['lastMessageAt'] != null 
            ? DateTime.parse(json['lastMessageAt'].toString())
            : DateTime.now(),
        unreadCount: json['unreadCount'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing conversation: $e');
      debugPrint('Problematic JSON: $json');
      rethrow;
    }
  }

  String getOtherParticipant(String currentUserId) {
    try {
      final otherParticipant = participants.firstWhere(
        (p) => p['_id']?.toString() != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant['_id']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting other participant: $e');
      debugPrint('Current user ID: $currentUserId');
      debugPrint('Participants: $participants');
      return '';
    }
  }
} 