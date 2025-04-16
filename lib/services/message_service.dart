import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'api_service.dart';

class MessageService {
  static Future<List<Conversation>> getConversations() async {
    try {
      debugPrint('Fetching conversations...');
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages'),
        headers: await ApiService.getHeaders(),
      );

      debugPrint('Conversations response status: ${response.statusCode}');
      debugPrint('Conversations response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          try {
            return Conversation.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing conversation: $e');
            debugPrint('Problematic conversation data: $json');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getConversations: $e');
      rethrow;
    }
  }

  static Future<List<Message>> getMessages(String conversationId) async {
    try {
      debugPrint('Fetching messages for conversation: $conversationId');
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/$conversationId'),
        headers: await ApiService.getHeaders(),
      );

      debugPrint('Messages response status: ${response.statusCode}');
      debugPrint('Messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Decoded messages data: $data');
        if (data.isEmpty) {
          debugPrint('No messages found for conversation: $conversationId');
        }
        return data.map((json) => Message.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        debugPrint('Conversation not found: $conversationId');
        return [];
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getMessages: $e');
      rethrow;
    }
  }

  static Future<void> markMessageAsRead(String messageId) async {
    try {
      debugPrint('Marking message as read: $messageId');
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/messages/$messageId/read'),
        headers: await ApiService.getHeaders(),
      );

      debugPrint('Mark as read response status: ${response.statusCode}');
      debugPrint('Mark as read response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as read: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in markMessageAsRead: $e');
      rethrow;
    }
  }
} 