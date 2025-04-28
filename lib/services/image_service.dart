import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'api_service.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ImageService {

  static Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Determine file extension
      String extension = path.extension(imageFile.path).toLowerCase();
      if (extension.startsWith('.')) extension = extension.substring(1);
      MediaType contentType;
      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else {
        throw Exception('Unsupported file type');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/users/upload-profile-image'),
      );

      // Add file to request with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: contentType,
        ),
      );

      // Add authorization token if needed
      request.headers['Authorization'] = 'Bearer ${await ApiService.getToken()}';

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parse the response to get the image URL
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['imageUrl'];
      } else {
        throw Exception('Failed to upload image: $responseBody');
      }
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }
} 