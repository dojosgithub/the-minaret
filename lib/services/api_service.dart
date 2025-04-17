import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Uncomment the correct URL based on your setup:
  
  // For Android Emulator:
  //static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:5000/api';
  
  // For physical device:
  static const String baseUrl = 'http://192.168.100.89:5000/api';

  static String? _authToken;  // Store the JWT token

  // Initialize auth token from SharedPreferences
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token');
    } catch (e) {
      debugPrint('Error initializing auth token: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all posts
  static Future<List<Map<String, dynamic>>> getPosts({String? type}) async {
    try {
      final url = type != null && type != 'all' 
          ? '$baseUrl/posts/type/$type'
          : '$baseUrl/posts';
          
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
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
        headers: await getHeaders(),
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

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        if (token == null) {
          throw Exception('Invalid login response format: missing token');
        }
        
        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        _authToken = token;
        
        // Fetch user data using the token
        final userResponse = await http.get(
          Uri.parse('$baseUrl/users/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          await prefs.setString('user', jsonEncode(userData));
          return true;
        } else {
          throw Exception('Failed to fetch user data');
        }
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      _authToken = null;
    } catch (e) {
      debugPrint('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await getHeaders(),
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
      request.headers.addAll(await getHeaders());

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
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        // Update user data in case it changed
        final userData = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(userData));
        return true;
      } else {
        debugPrint('Token verification failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Token verification failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: await getHeaders(),
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
        headers: await getHeaders(),
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
        headers: await getHeaders(),
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

      request.headers.addAll(await getHeaders());

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
        headers: await getHeaders(),
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

  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: await getHeaders(),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  static Future<bool> savePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/save'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to save post');
      }
    } catch (e) {
      debugPrint('Error saving post: $e');
      rethrow;
    }
  }

  static Future<bool> unsavePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId/save'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to unsave post');
      }
    } catch (e) {
      debugPrint('Error unsaving post: $e');
      rethrow;
    }
  }

  static Future<bool> isPostSaved(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/save'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isSaved'];
      } else {
        throw Exception('Failed to check if post is saved');
      }
    } catch (e) {
      debugPrint('Error checking if post is saved: $e');
      rethrow;
    }
  }

  static Future<Map<String, List<Map<String, dynamic>>>> searchPosts({
    required String query,
    String? sortBy,
    String? datePosted,
    String? postedBy,
    int? page,
  }) async {
    try {
      final Map<String, String> queryParams = {'query': query};
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (datePosted != null) queryParams['datePosted'] = datePosted;
      if (postedBy != null) queryParams['postedBy'] = postedBy;
      if (page != null) queryParams['page'] = page.toString();

      final response = await http.get(
        Uri.parse('$baseUrl/posts/search').replace(queryParameters: queryParams),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'posts': List<Map<String, dynamic>>.from(data['posts'] ?? []),
          'users': List<Map<String, dynamic>>.from(data['users'] ?? []),
        };
      } else {
        throw Exception('Failed to search posts and users');
      }
    } catch (e) {
      debugPrint('Error searching posts and users: $e');
      rethrow;
    }
  }

  static Future<List<String>> getRecentSearches() async {
    try {
      debugPrint('Sending request to get recent searches...');
      final response = await http.get(
        Uri.parse('$baseUrl/users/recent-searches'),
        headers: await getHeaders(),
      );

      debugPrint('Recent searches response status: ${response.statusCode}');
      debugPrint('Recent searches response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          debugPrint('Decoded recent searches: $data');
          return List<String>.from(data);
        } catch (e) {
          debugPrint('Error decoding recent searches: $e');
          if (response.body.trim() == '[]') {
            return [];
          }
          rethrow;
        }
      } else {
        debugPrint('Error response: ${response.body}');
        try {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Failed to load recent searches');
        } catch (e) {
          throw Exception('Failed to load recent searches: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error in getRecentSearches: $e');
      rethrow;
    }
  }

  static Future<void> addRecentSearch(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/recent-searches'),
        headers: await getHeaders(),
        body: json.encode({'query': query}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add recent search');
      }
    } catch (e) {
      debugPrint('Error adding recent search: $e');
      rethrow;
    }
  }

  static Future<void> clearRecentSearches() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/recent-searches'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to clear recent searches');
      }
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
      rethrow;
    }
  }

  static Future<void> deleteRecentSearch(String query) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/recent-searches/${Uri.encodeComponent(query)}'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete recent search');
      }
    } catch (e) {
      debugPrint('Error deleting recent search: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserPostsById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/user/$userId'),
        headers: await getHeaders(),
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

  static Future<bool> isFollowing(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/is-following/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFollowing'] ?? false;
      } else {
        throw Exception('Failed to check follow status');
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      rethrow;
    }
  }

  static Future<void> followUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/follow/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to follow user');
      }
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  static Future<void> unfollowUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/unfollow/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user');
      }
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  static Future<bool> upvotePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/upvote'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upvote post');
      }
    } catch (e) {
      debugPrint('Error upvoting post: $e');
      rethrow;
    }
  }

  static Future<bool> downvotePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/downvote'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to downvote post');
      }
    } catch (e) {
      debugPrint('Error downvoting post: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      debugPrint('Error getting comments: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addComment(String postId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: await getHeaders(),
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addReply(
      String postId, String commentId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments/$commentId/replies'),
        headers: await getHeaders(),
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add reply');
      }
    } catch (e) {
      debugPrint('Error adding reply: $e');
      rethrow;
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getPostVoteStatus(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/vote-status'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get post vote status');
      }
    } catch (e) {
      debugPrint('Error getting post vote status: $e');
      rethrow;
    }
  }

  static Future<String?> get currentUserId async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final token = prefs.getString('token');
      
      if (userJson == null || token == null) {
        debugPrint('No user data or token found in SharedPreferences');
        await logout(); // Clear any invalid data
        return null;
      }
      
      try {
        final userData = json.decode(userJson);
        if (userData is! Map<String, dynamic>) {
          debugPrint('Invalid user data format: not a map');
          await logout();
          return null;
        }
        
        final userId = userData['_id'];
        if (userId == null) {
          debugPrint('No _id field found in user data');
          await logout();
          return null;
        }
        
        // Verify token is still valid
        final isValid = await verifyToken();
        if (!isValid) {
          debugPrint('Token is invalid');
          await logout();
          return null;
        }
        
        return userId.toString();
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        await logout();
        return null;
      }
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      await logout();
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?query=$query'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$conversationId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      debugPrint('Error getting messages: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
    String recipientId,
    String content, [
    List<Map<String, dynamic>>? media,
    String? postId,
  ]) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: await getHeaders(),
        body: json.encode({
          'recipient': recipientId,
          'content': content,
          'media': media,
          'postId': postId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  static Future<void> markMessageAsRead(String messageId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/messages/$messageId/read'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as read');
      }
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> repostPost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/repost'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to repost');
      }
    } catch (e) {
      debugPrint('Error reposting: $e');
      rethrow;
    }
  }

  static Future<http.Response> getFollowedUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/following'),
        headers: await getHeaders(),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to get followed users: $e');
    }
  }
} 