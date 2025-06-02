import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'dart:convert';

class PostScreen extends StatefulWidget {
  final Function(int) onIndexChanged;

  const PostScreen({
    super.key,
    required this.onIndexChanged,
  });

  @override
  State<PostScreen> createState() => _PostPageState();
}

class _PostPageState extends State<PostScreen> {
  String? selectedType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _linkTitleController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();
  bool _hasChanges = false;
  final List<XFile> _selectedMedia = [];
  final List<Map<String, String>> _links = [];
  bool _isLoading = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onChangesMade);
    _bodyController.addListener(_onChangesMade);
    _loadUserData();
    
    // Remove automatic login check that might cause logout loop
    // We'll handle auth errors in the API responses instead
  }

  Future<void> _loadUserData() async {
    try {
      final data = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          userData = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkTitleController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  void _onChangesMade() {
    // Check if there are any actual changes before setting the flag
    final bool hasTypeSelected = selectedType != null;
    final bool hasTitleText = _titleController.text.isNotEmpty;
    final bool hasBodyText = _bodyController.text.isNotEmpty;
    final bool hasMedia = _selectedMedia.isNotEmpty;
    final bool hasLinks = _links.isNotEmpty;
    
    final bool hasActualChanges = hasTypeSelected || hasTitleText || hasBodyText || hasMedia || hasLinks;
    
    if (hasActualChanges && !_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> media = await picker.pickMultiImage();
      if (media.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(media);
          _onChangesMade();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick media: $e')),
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      // Check if there are still changes
      _onChangesMade();
    });
  }

  void _showAddLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D1B45),
        title: const Text('Add Link', style: TextStyle(color: Color(0xFFFDCC87))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _linkTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Link Title',
                hintStyle: TextStyle(color: Color(0xFFFDCC87)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _linkUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'URL',
                hintStyle: TextStyle(color: Color(0xFFFDCC87)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFFDCC87))),
          ),
          TextButton(
            onPressed: () {
              if (_linkUrlController.text.isNotEmpty) {
                setState(() {
                  _links.add({
                    'title': _linkTitleController.text,
                    'url': _linkUrlController.text,
                  });
                  _onChangesMade();
                });
                _linkTitleController.clear();
                _linkUrlController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFFFDCC87))),
          ),
        ],
      ),
    );
  }

  void _removeLink(int index) {
    setState(() {
      _links.removeAt(index);
      // Check if there are still changes
      _onChangesMade();
    });
  }

  Future<void> _createPost() async {
    if (selectedType == null || _titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Check for inappropriate content before proceeding
    setState(() => _isLoading = true);

    try {
      // Combine title and body for content check
      final String fullContent = '${_titleController.text} ${_bodyController.text}';
      final contentCheckResult = await ApiService.checkInappropriateContent(fullContent);

      if (contentCheckResult['isInappropriate']) {
        // Show warning dialog for inappropriate content
        if (!mounted) return;
        
        final shouldProceed = await _showInappropriateContentWarning(
          contentCheckResult['foundTerms'],
        );
        
        if (!shouldProceed) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final success = await ApiService.createPostWithXFiles(
        selectedType!,
        _titleController.text,
        _bodyController.text,
        _selectedMedia,
        _links,
      );

      if (success && mounted) {
        // Reset the _hasChanges flag since post was created successfully
        setState(() {
          _hasChanges = false;
        });
        
        // First show the success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
        
        // Then navigate to home screen
        widget.onIndexChanged(0);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('No token')) {
          errorMessage = 'Please log in again to create a post';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showInappropriateContentWarning(List<String> terms) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Content Warning',
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your post may contain inappropriate content that violates our community guidelines.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Potential issues:',
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...terms.map((term) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    '• Contains potentially inappropriate term: "$term"',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                )).toList(),
                const SizedBox(height: 16),
                const Text(
                  'Please review our community guidelines and ensure your content complies before posting.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Edit Post',
                style: TextStyle(
                  color: Color(0xFFFDCC87),
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Post Anyway',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showOptionsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Reporters', style: TextStyle(color: Color(0xFFFDCC87))),
                onTap: () {
                  setState(() {
                    selectedType = 'Reporters';
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Islamic Knowledge', style: TextStyle(color: Color(0xFFFDCC87))),
                onTap: () {
                  setState(() {
                    selectedType = 'Islamic Knowledge';
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Discussion', style: TextStyle(color: Color(0xFFFDCC87))),
                onTap: () {
                  setState(() {
                    selectedType = 'Discussion';
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    // If there are no changes, allow navigation without confirmation
    if (!_hasChanges) return true;

    // Check if there are actual changes to confirm
    final bool hasTypeSelected = selectedType != null;
    final bool hasTitleText = _titleController.text.isNotEmpty;
    final bool hasBodyText = _bodyController.text.isNotEmpty;
    final bool hasMedia = _selectedMedia.isNotEmpty;
    final bool hasLinks = _links.isNotEmpty;
    
    final bool hasActualChanges = hasTypeSelected || hasTitleText || hasBodyText || hasMedia || hasLinks;
    
    if (!hasActualChanges) return true;
    
    // Show confirmation dialog if changes exist
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D1B45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Discard Post?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to discard this post? All your changes will be lost.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFFDCC87),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Function to safely navigate away with confirmation
  Future<void> _navigateAway(int index) async {
    final canNavigate = await _onWillPop();
    if (canNavigate && mounted) {
      widget.onIndexChanged(index);
    }
  }

  Widget _buildMediaPreview() {
    if (_selectedMedia.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDCC87)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      // For web, use Image.network with XFile
                      ? FutureBuilder<String>(
                          future: _getWebImageUrl(_selectedMedia[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              return Image.network(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                                ),
                              );
                            }
                          },
                        )
                      // For mobile platforms, use File with XFile path
                      : Image.file(
                          File(_selectedMedia[index].path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                top: 5,
                right: 15,
                child: GestureDetector(
                  onTap: () => _removeMedia(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D1B45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFFDCC87),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to get a URL for web images
  Future<String> _getWebImageUrl(XFile file) async {
    try {
      // For web, we need to create a data URL from the file content
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final mimeType = file.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      return 'data:$mimeType;base64,$base64';
    } catch (e) {
      debugPrint('Error creating image URL: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            widget.onIndexChanged(0);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4F245A),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
            onPressed: () => _navigateAway(0), // Go back to home with confirmation
          ),
          title: const Text(
            'Create Post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFDCC87),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: userData?['profileImage'] != null && userData!['profileImage'].isNotEmpty
                              ? NetworkImage(ApiService.resolveImageUrl(userData!['profileImage']))
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showOptionsPopup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1B45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedType ?? 'Type', style: const TextStyle(color: Color(0xFFFDCC87))),
                          const Icon(Icons.add, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1B45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          maxLines: 1,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Title of Post',
                            hintStyle: TextStyle(color: Color(0xB3FDCC87), fontSize: 14),
                          ),
                        ),
                        const Divider(
                          color: Color(0xFFFDCC87),
                          thickness: 1.0,
                        ),
                        TextField(
                          controller: _bodyController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Body Text',
                            hintStyle: TextStyle(color: Color(0xB3FDCC87), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMediaPreview(),

                  if (_links.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _links.asMap().entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D1B45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Color(0xFFFDCC87)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value['title'] ?? entry.value['url'] ?? '',
                                  style: const TextStyle(color: Color(0xFFFDCC87)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => _removeLink(entry.key),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  ElevatedButton(
                    onPressed: _pickMedia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D1B45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.collections, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Photos', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _showAddLinkDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D1B45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.link, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Links', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : const Color(0xFFFDCC87),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
