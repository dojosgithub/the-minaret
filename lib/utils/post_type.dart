import 'package:flutter/foundation.dart';

class PostType {
  static String? selectedType;
  static final ValueNotifier<String?> typeNotifier = ValueNotifier<String?>(null);
  
  // Post types that match the backend model
  static const String all = 'all';
  static const String reporters = 'Reporters';
  static const String islamicKnowledge = 'Islamic Knowledge';
  static const String discussion = 'Discussion';

  static void setType(String? type) {
    selectedType = type;
    typeNotifier.value = type;
  }
} 