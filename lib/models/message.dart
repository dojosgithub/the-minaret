class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      senderId: json['sender'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': senderId,
      'content': content,
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
      type: json['type'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
    };
  }
} 