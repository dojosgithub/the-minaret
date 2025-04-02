import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

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
      debugPrint('Error getting posts: $e');
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
      debugPrint('Error getting notifications: $e');
      rethrow;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final url = '$baseUrl/test';
      debugPrint('Testing connection to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Connection timed out');
          throw TimeoutException('Connection timed out - Server might be unreachable');
        },
      );
      
      debugPrint('Test connection response: ${response.statusCode}');
      debugPrint('Test connection body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed with detailed error: $e');
      if (e.toString().contains('SocketException')) {
        debugPrint('Socket error - Check firewall and port 5000');
      }
      return false;
    }
  }

  static Future<bool> login(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _authToken = data['token'];
        debugPrint('Token stored: $_authToken'); // Debug debugPrintto verify token
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Error in login: $e');
      throw Exception('Invalid Credentials. Please try again.');
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

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        _authToken = data['token'];
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      throw Exception('Failed to connect to server, Please Restart');
    }
  }

  static Future<bool> createPost(
      String type,
      String title,
      String body,
      List<String> mediaFiles,
      List<Map<String, String>> links) async {
    try {
      debugPrint('Creating post with token: $_authToken');

      if (_authToken == null) {
        throw Exception('No token - Authorization denied');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));
      
      // Add auth token to headers
      request.headers.addAll({
        'Authorization': 'Bearer $_authToken',
      });

      // Add text fields
      request.fields['type'] = type;
      request.fields['title'] = title;
      request.fields['body'] = body;
      request.fields['links'] = json.encode(links);

      // Add media files
      if (mediaFiles.isNotEmpty) {
        for (String filePath in mediaFiles) {
          //final file = File(filePath);
          final filename = filePath.split('/').last;
          final mimeType = filename.endsWith('.jpg') || filename.endsWith('.jpeg') 
              ? 'image/jpeg' 
              : filename.endsWith('.png') 
                  ? 'image/png' 
                  : 'application/octet-stream';
                  
          request.files.add(
            await http.MultipartFile.fromPath(
              'media',
              filePath,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create post');
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  static String? getAuthToken() {
    return _authToken;
  }

  static Future<bool> verifyToken() async {
    if (_authToken == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token verification failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/posts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load user posts');
      }
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/saved-posts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load saved posts');
      }
    } catch (e) {
      debugPrint('Error getting saved posts: $e');
      rethrow;
    }
  }

  static Future<String?> uploadProfileImage(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/upload-profile-image'),
      );

      request.headers['Authorization'] = 'Bearer $_authToken';

      // Get the file extension
      String extension = image.path.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          throw Exception('Unsupported file type');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['imageUrl'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
} 