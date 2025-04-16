import 'package:flutter/foundation.dart';
import 'message.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final DateTime lastMessageTimestamp;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastMessageTimestamp,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing conversation JSON: $json');
    
    try {
      // Ensure participants is a List<String>
      final participantsList = json['participants'] as List? ?? [];
      final participants = participantsList.map((p) {
        if (p is String) return p;
        if (p is Map<String, dynamic>) return p['_id']?.toString() ?? '';
        return '';
      }).where((id) => id.isNotEmpty).toList();

      // Handle lastMessageTimestamp
      DateTime lastMessageTimestamp;
      try {
        lastMessageTimestamp = json['lastMessageTimestamp'] != null 
            ? DateTime.parse(json['lastMessageTimestamp'].toString())
            : DateTime.now();
      } catch (e) {
        debugPrint('Error parsing lastMessageTimestamp: $e');
        lastMessageTimestamp = DateTime.now();
      }

      // Handle lastMessage
      Message? lastMessage;
      try {
        lastMessage = json['lastMessage'] != null ? Message.fromJson(json['lastMessage']) : null;
      } catch (e) {
        debugPrint('Error parsing lastMessage: $e');
        lastMessage = null;
      }

      // Handle unreadCount
      int unreadCount;
      try {
        unreadCount = json['unreadCount'] is int ? json['unreadCount'] : 0;
      } catch (e) {
        debugPrint('Error parsing unreadCount: $e');
        unreadCount = 0;
      }

      return Conversation(
        id: json['_id']?.toString() ?? '',
        participants: participants,
        lastMessage: lastMessage,
        lastMessageTimestamp: lastMessageTimestamp,
        unreadCount: unreadCount,
      );
    } catch (e) {
      debugPrint('Error parsing conversation: $e');
      debugPrint('Problematic JSON: $json');
      rethrow;
    }
  }

  String getOtherParticipant(String currentUserId) {
    debugPrint('Getting other participant for user: $currentUserId');
    debugPrint('Participants: $participants');
    
    final otherParticipant = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    debugPrint('Other participant: $otherParticipant');
    return otherParticipant;
  }
} 