import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Helper class for handling image operations on web platform
class WebImageHelper {
  /// Creates a MultipartFile from an XFile for web platform
  /// This avoids using dart:io which is not available on web
  static Future<http.MultipartFile?> createMultipartFileFromXFile(
    XFile xFile, {
    String? fieldName = 'file',
  }) async {
    try {
      // Read file as bytes
      final bytes = await xFile.readAsBytes();
      final filename = xFile.name;
      
      // Determine MIME type based on file extension
      final extension = filename.split('.').last.toLowerCase();
      final mimeType = extension == 'jpg' || extension == 'jpeg'
          ? 'image/jpeg'
          : extension == 'png'
              ? 'image/png'
              : 'application/octet-stream';
      
      // Create MultipartFile from bytes
      return http.MultipartFile.fromBytes(
        fieldName ?? 'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );
    } catch (e) {
      debugPrint('Error creating MultipartFile: $e');
      return null;
    }
  }

  /// Checks if the current platform is web
  static bool get isWeb {
    return kIsWeb;
  }

  /// Extract bytes from XFile (works on web)
  static Future<Uint8List?> getXFileBytes(XFile xFile) async {
    try {
      return await xFile.readAsBytes();
    } catch (e) {
      debugPrint('Error reading file bytes: $e');
      return null;
    }
  }
} 