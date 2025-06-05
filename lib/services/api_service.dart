import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://the-minaret-f6e46d4294b5.herokuapp.com/api';

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
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      
      // Don't make API call to validate-token here as that endpoint might not exist
      // Just check if we have a token for now
      return true;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  static Future<void> checkLoginAndRedirect(BuildContext context) async {
    try {
      // Only check if token exists
      final token = await getToken();
      if (token == null || token.isEmpty) {
        if (context.mounted) {
          // Navigate to welcome screen if no token
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error in checkLoginAndRedirect: $e');
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
  static Future<List<Map<String, dynamic>>> getPosts({String? type, int? page, int? limit}) async {
    try {
      // Build base URL
      String url = type != null && type != 'all' 
          ? '$baseUrl/posts/type/$type'
          : '$baseUrl/posts';
      
      // Add pagination parameters if provided
      final Map<String, String> queryParams = {};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      // Append query parameters if any
      if (queryParams.isNotEmpty) {
        url = Uri.parse(url).replace(queryParameters: queryParams).toString();
      }
          
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);
        
        // Ensure repostCount is present in each post
        for (var post in data) {
          if (post['repostCount'] == null) {
            post['repostCount'] = 0;
          }
        }
        
        return data;
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
      // Transform the data to match backend expectations
      final transformedData = {
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'username': userData['username'],
        'email': userData['email'],
        'password': userData['password'],
        'type': userData['userType'], // Transform userType to type
        'birthday': userData['dateOfBirth'], // Transform dateOfBirth to birthday
      };

      // Only add phoneNumber if it's not null and not empty
      if (userData['phoneNumber'] != null && userData['phoneNumber'].toString().trim().isNotEmpty) {
        transformedData['phoneNumber'] = userData['phoneNumber'];
      }
      // Don't include phoneNumber at all if it's null or empty

      debugPrint('Registering user with data: $transformedData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transformedData),
      );

      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response body: ${response.body}');

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        // Store token and user data
        final token = data['token'];
        if (token == null) {
          throw Exception('No token received from server');
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        _authToken = token;
        
        // Fetch and store user data
        final userResponse = await http.get(
          Uri.parse('$baseUrl/users/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          await prefs.setString('user', json.encode(userData));
          return {'success': true};
        } else {
          throw Exception('Failed to fetch user data after registration');
        }
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
          // Get the filename from the path
          final filename = filePath.split('/').last;
          
          // Determine MIME type based on file extension
          final mimeType = filename.endsWith('.jpg') || filename.endsWith('.jpeg') 
              ? 'image/jpeg' 
              : filename.endsWith('.png') 
                  ? 'image/png' 
                  : 'application/octet-stream';
          
          // Handle file upload based on platform
          try {
            // Try to use File which works on native platforms (Android/iOS)
            final file = File(filePath);
            if (await file.exists()) {
              // Use bytes approach which works cross-platform
              final bytes = await file.readAsBytes();
              request.files.add(
                http.MultipartFile.fromBytes(
                  'media',
                  bytes,
                  filename: filename,
                  contentType: MediaType.parse(mimeType),
                ),
              );
            }
          } catch (e) {
            // If File is not supported (web platform), just log the error
            // and skip this file
            debugPrint('Error adding file to request: $e');
            debugPrint('File uploads may not be supported on this platform');
          }
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
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    
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
        // Don't log out automatically here
        return false;
      }
    } catch (e) {
      debugPrint('Token verification failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No token, please log in again');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        throw Exception('Your session has expired, please log in again');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to get user profile: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserPosts({int? page, int? limit}) async {
    try {
      // Build URL with pagination
      String url = '$baseUrl/users/posts';
      final Map<String, String> queryParams = {};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      // Append query parameters if any
      if (queryParams.isNotEmpty) {
        url = Uri.parse(url).replace(queryParameters: queryParams).toString();
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);
        
        // Ensure repostCount is present in each post
        for (var post in data) {
          if (post['repostCount'] == null) {
            post['repostCount'] = 0;
          }
        }
        
        return data;
      } else {
        throw Exception('Failed to load user posts');
      }
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedPosts({int? page, int? limit}) async {
    try {
      // Build URL with pagination
      String url = '$baseUrl/users/saved-posts';
      final Map<String, String> queryParams = {};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      // Append query parameters if any
      if (queryParams.isNotEmpty) {
        url = Uri.parse(url).replace(queryParameters: queryParams).toString();
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);
        
        // Ensure repostCount is present in each post
        for (var post in data) {
          if (post['repostCount'] == null) {
            post['repostCount'] = 0;
          }
        }
        
        return data;
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

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      // Log what data is being sent
      debugPrint('Updating profile with data: $data');
      
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile: ${response.body}');
      }
      
      // Update local cache of user data
      final userData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(userData));
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
      } else if (response.statusCode == 400) {
        // Check if the error is due to the post already being saved
        try {
          final error = json.decode(response.body);
          if (error['message']?.toString().contains('already saved') == true) {
            // Post is already saved, which is fine - return true
            return true;
          }
          throw Exception(error['message'] ?? 'Failed to save post');
        } catch (e) {
          // If JSON parsing fails, it means the response is not valid JSON
          // This could be a notification error but post was saved
          // Check if post is actually saved now
          final isSaved = await isPostSaved(postId);
          if (isSaved) {
            return true;
          }
          throw Exception('Failed to save post: ${response.body}');
        }
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Failed to save post');
        } catch (e) {
          // Response is not valid JSON
          // Similar to above, check if post is saved despite the error
          final isSaved = await isPostSaved(postId);
          if (isSaved) {
            return true;
          }
          throw Exception('Failed to save post: ${response.body}');
        }
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
      } else if (response.statusCode == 404) {
        // Post not found can happen if post was deleted, but user attempts to unsave
        // Just return true as if successfully unsaved
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
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(responseData['posts'] ?? []);
        final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(responseData['users'] ?? []);
        
        // Ensure repostCount is present in each post
        for (var post in posts) {
          if (post['repostCount'] == null) {
            post['repostCount'] = 0;
          }
        }
        
        return {
          'posts': posts,
          'users': users,
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
        final List<dynamic> rawData = json.decode(response.body);
        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);
        
        // Ensure repostCount is present in each post
        for (var post in data) {
          if (post['repostCount'] == null) {
            post['repostCount'] = 0;
          }
        }
        
        return data;
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
      return false;
    }
  }

  static Future<bool> isBlocked(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/is-blocked/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isBlocked'] ?? false;
      } else {
        throw Exception('Failed to check block status');
      }
    } catch (e) {
      debugPrint('Error checking block status: $e');
      return false;
    }
  }

  static Future<void> blockUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/block/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to block user');
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  static Future<void> unblockUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/unblock/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to unblock user');
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
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
        return null;
      }
      
      try {
        final userData = json.decode(userJson);
        if (userData is! Map<String, dynamic>) {
          debugPrint('Invalid user data format: not a map');
          return null;
        }
        
        final userId = userData['_id'];
        if (userId == null) {
          debugPrint('No _id field found in user data');
          return null;
        }
        
        return userId.toString();
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
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

  static Future<void> sendMessage(String recipientId, String content, {String? postId, String? profileId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: await getHeaders(),
        body: json.encode({
          'recipient': recipientId,
          'content': content,
          if (postId != null) 'postId': postId,
          if (profileId != null) 'profileId': profileId,
        }),
      );

      if (response.statusCode != 201) {
        debugPrint('Message send response: ${response.body}');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
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

  static Future<void> deleteAccount(String userId, String password) async {
    try {
      // Make sure the request has proper content-type
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/delete-account/$userId'),
        headers: headers,
        body: json.encode({
          'password': password,
        }),
      );

      // Add better error handling
      if (response.statusCode != 200) {
        try {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Failed to delete account');
        } catch (jsonError) {
          // If response is not valid JSON
          throw Exception('Failed to delete account: ${response.body.substring(0, 100)}...');
        }
      }
      
      // Clear all local user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored preferences
      _authToken = null;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  static Future<void> repostPost(String postId, String caption) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/repost'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: json.encode({
          'caption': caption,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to repost: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to repost: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getFollowedUsers() async {
    try {
      final currentUserId = await ApiService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$currentUserId/following'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data.map((item) => 
          Map<String, dynamic>.from(item)
        ));
      } else {
        throw Exception('Failed to load followed users');
      }
    } catch (e) {
      debugPrint('Error getting followed users: $e');
      rethrow;
    }
  }

  static Future<bool> submitFeedback({
    required String name,
    required String email,
    required String feedback,
  }) async {
    try {
      debugPrint('Submitting feedback...');
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: await getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'feedback': feedback,
        }),
      );

      debugPrint('Feedback response status: ${response.statusCode}');
      debugPrint('Feedback response body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Failed to submit feedback');
        } catch (e) {
          // If response is not JSON, throw the raw response
          throw Exception('Server error: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Failed to connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getPost(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Ensure repostCount is present in the response
        if (data['repostCount'] == null) {
          data['repostCount'] = 0;
        }
        return data;
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e) {
      debugPrint('Error getting post: $e');
      rethrow;
    }
  }

  static Future<bool> reportPost({
    required String postId,
    required String reason,
    String? additionalContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: await getHeaders(),
        body: json.encode({
          'postId': postId,
          'reason': reason,
          'additionalContext': additionalContext ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 400) {
        // Check if error is because post was already reported
        final error = json.decode(response.body);
        if (error['message']?.contains('already reported') == true) {
          throw Exception('You have already reported this post');
        }
        throw Exception(error['message'] ?? 'Failed to report post');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to report post');
      }
    } catch (e) {
      debugPrint('Error reporting post: $e');
      rethrow;
    }
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'assets/default_profile.png';
    }
    
    // If it's already a fully qualified URL, return it as is
    if (url.startsWith('http')) return url;
    
    // If it's a relative path, join it with the base URL
    final path = url.startsWith('/') ? url.substring(1) : url;
    try {
      return baseUrl.replaceFirst('/api', '') + '/' + path;
    } catch (e) {
      debugPrint('Error resolving image URL: $e');
      return 'assets/default_profile.png';
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFollowers(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/followers'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load followers');
      }
    } catch (e) {
      debugPrint('Error getting followers: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFollowing(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/following'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load following');
      }
    } catch (e) {
      debugPrint('Error getting following: $e');
      rethrow;
    }
  }

  static Future<Map<String, String>> getViewPreferences() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/preferences/view'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Map<String, String>.from(data);
      } else {
        throw Exception('Failed to load view preferences');
      }
    } catch (e) {
      debugPrint('Error getting view preferences: $e');
      rethrow;
    }
  }

  static Future<void> updateViewPreferences(Map<String, String> preferences) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/preferences/view'),
        headers: await getHeaders(),
        body: json.encode({'preferences': preferences}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update view preferences');
      }
    } catch (e) {
      debugPrint('Error updating view preferences: $e');
      rethrow;
    }
  }

  // New method that takes XFile objects for better cross-platform support
  static Future<bool> createPostWithXFiles(
      String type,
      String title,
      String body,
      List<XFile> mediaFiles,
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
        for (XFile file in mediaFiles) {
          // Get the filename from the path
          final filename = file.name;
          
          // Determine MIME type based on file extension
          final extension = filename.split('.').last.toLowerCase();
          final mimeType = extension == 'jpg' || extension == 'jpeg'
              ? 'image/jpeg'
              : extension == 'png'
                  ? 'image/png'
                  : 'application/octet-stream';
          
          // Read file as bytes (works on all platforms including web)
          final bytes = await file.readAsBytes();
          
          // Create MultipartFile from bytes
          request.files.add(
            http.MultipartFile.fromBytes(
              'media',
              bytes,
              filename: filename,
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

  // Add a method to check for inappropriate content
  static Future<Map<String, dynamic>> checkInappropriateContent(String text) async {
    try {
      // List of common inappropriate terms
      // This is a simple implementation - in production, you'd want a more sophisticated solution
      // such as a server-side AI model or third-party content moderation API
      final List<String> inappropriateTerms = [
        'hate', 'kill', 'violence', 'racist', 'terrorism', 'bomb', 
        'explicit', 'obscene', 'porn', 'sex', 'nude', 'racist', 'nazi',
        'slur', 'assault', 'attack', 'threat', 'harmful', 'illegal',
        // Add more terms as needed
      ];
      
      // Check for exact matches (would be better with more advanced text analysis)
      final String lowerText = text.toLowerCase();
      final List<String> foundTerms = [];
      
      for (final term in inappropriateTerms) {
        if (lowerText.contains(term)) {
          foundTerms.add(term);
        }
      }
      
      final bool isInappropriate = foundTerms.isNotEmpty;
      
      return {
        'isInappropriate': isInappropriate,
        'foundTerms': foundTerms,
        'suggestedAction': isInappropriate ? 'review' : 'approve'
      };
    } catch (e) {
      debugPrint('Error checking inappropriate content: $e');
      // Default to requiring review if there's an error, to be safe
      return {
        'isInappropriate': true,
        'foundTerms': [],
        'suggestedAction': 'review',
        'error': e.toString()
      };
    }
  }
} 