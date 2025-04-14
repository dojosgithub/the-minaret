import 'message.dart';

class Conversation {
  final String id;
  final List<Map<String, dynamic>> participants;
  final Message? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  Map<String, dynamic> getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (participant) => participant['_id'] != currentUserId,
      orElse: () => participants.first,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'],
      participants: List<Map<String, dynamic>>.from(json['participants']),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
} 