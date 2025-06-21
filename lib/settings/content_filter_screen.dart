import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/content_filter.dart';
import '../widgets/top_bar_without_menu.dart';

class ContentFilterScreen extends StatefulWidget {
  const ContentFilterScreen({super.key});

  @override
  State<ContentFilterScreen> createState() => _ContentFilterScreenState();
}

class _ContentFilterScreenState extends State<ContentFilterScreen> {
  ContentFilterLevel _selectedFilterLevel = ContentFilterLevel.moderate;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContentFilterPreference();
  }

  Future<void> _loadContentFilterPreference() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get user profile to retrieve content filter preference
      final userData = await ApiService.getUserProfile();
      
      // Convert string to enum value
      final filterLevelString = userData['contentFilterLevel'] ?? 'moderate';
      
      setState(() {
        _selectedFilterLevel = _stringToFilterLevel(filterLevelString);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load preferences: $e';
        _isLoading = false;
      });
    }
  }

  ContentFilterLevel _stringToFilterLevel(String level) {
    switch (level.toLowerCase()) {
      case 'strict':
        return ContentFilterLevel.strict;
      case 'moderate':
        return ContentFilterLevel.moderate;
      case 'minimal':
        return ContentFilterLevel.minimal;
      case 'none':
        return ContentFilterLevel.none;
      default:
        return ContentFilterLevel.moderate;
    }
  }

  String _filterLevelToString(ContentFilterLevel level) {
    switch (level) {
      case ContentFilterLevel.strict:
        return 'strict';
      case ContentFilterLevel.moderate:
        return 'moderate';
      case ContentFilterLevel.minimal:
        return 'minimal';
      case ContentFilterLevel.none:
        return 'none';
    }
  }

  Future<void> _savePreferences() async {
    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      // Convert enum to string
      final filterLevelString = _filterLevelToString(_selectedFilterLevel);
      
      // Update user profile with new content filter preference
      await ApiService.updateProfile({
        'contentFilterLevel': filterLevelString,
      });

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content filter preferences saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save preferences: $e';
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_error!}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const TopBarWithoutMenu(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            )
          : Column(
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Content Filter",
                          style: TextStyle(
                            color: Color(0xFFFDCC87),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Info text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Control the type of content you see in your feed. This helps filter out potentially sensitive or offensive material.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Filter options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterOption(
                          title: 'Strict',
                          description: 'Filter out all potentially sensitive content',
                          icon: Icons.shield,
                          value: ContentFilterLevel.strict,
                        ),
                        _buildFilterOption(
                          title: 'Moderate (Recommended)',
                          description: 'Filter out most sensitive content',
                          icon: Icons.security,
                          value: ContentFilterLevel.moderate,
                        ),
                        _buildFilterOption(
                          title: 'Minimal',
                          description: 'Filter only the most severe content',
                          icon: Icons.visibility,
                          value: ContentFilterLevel.minimal,
                        ),
                        _buildFilterOption(
                          title: 'None',
                          description: 'Show all content (not recommended)',
                          icon: Icons.visibility_off,
                          value: ContentFilterLevel.none,
                        ),
                        
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Save button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDCC87),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Preferences',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterOption({
    required String title,
    required String description,
    required IconData icon,
    required ContentFilterLevel value,
  }) {
    final bool isSelected = _selectedFilterLevel == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1B45),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xFFFDCC87) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterLevel = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFFDCC87) : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFDCC87) : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFDCC87),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 