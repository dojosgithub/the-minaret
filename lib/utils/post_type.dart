import 'package:flutter/foundation.dart';

class PostType {
  static String? selectedType;
  static final ValueNotifier<String?> typeNotifier = ValueNotifier<String?>(null);
  
  // Post types that match the backend model
  static const String all = 'all';
  static const String reporters = 'Reporters';
  static const String teachingQuran = 'Teaching Quran';
  static const String discussion = 'Discussion';
  static const String hadith = 'Hadith';
  static const String tafsir = 'Tafsir';
  static const String sunnah = 'Sunnah';

  static void setType(String? type) {
    selectedType = type;
    typeNotifier.value = type;
  }
} 