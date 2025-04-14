import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/conversation.dart';
import 'api_service.dart';

class MessageService {
  static Future<List<Conversation>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/$conversationId'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> sendMessage(String conversationId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/messages'),
        headers: await ApiService.getHeaders(),
        body: json.encode({
          'conversationId': conversationId,
          'content': content,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> markMessageAsRead(String messageId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/messages/$messageId/read'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as read');
      }
    } catch (e) {
      rethrow;
    }
  }
} 