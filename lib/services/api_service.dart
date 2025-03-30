import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ApiService {
  // Uncomment the correct URL based on your setup:
  
  // For Android Emulator:
  //static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:5000/api';
  
  // For physical device:
  static const String baseUrl = 'http://192.168.100.89:5000/api';

  static String? _authToken;  // Store the JWT token

  // Get all posts
  static Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error getting posts: $e');
      rethrow;
    }
  }

  // Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final url = '$baseUrl/test';
      print('Testing connection to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Connection timed out');
          throw TimeoutException('Connection timed out - Server might be unreachable');
        },
      );
      
      print('Test connection response: ${response.statusCode}');
      print('Test connection body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed with detailed error: $e');
      if (e.toString().contains('SocketException')) {
        print('Socket error - Check firewall and port 5000');
      }
      return false;
    }
  }

  static Future<bool> login(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _authToken = data['token']; // Save the token
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    }
  }

  // Add method to get authenticated headers
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
} 