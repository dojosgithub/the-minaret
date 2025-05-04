import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'dart:io';

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
  final List<File> _selectedMedia = [];
  final List<Map<String, String>> _links = [];
  bool _isLoading = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onChangesMade);
    _bodyController.addListener(_onChangesMade);
    _loadUserData();
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
    // Directly set _hasChanges to true without any conditions
    if (!_hasChanges) {
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
          _selectedMedia.addAll(media.map((m) => File(m.path)));
          _onChangesMade();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick media')),
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
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

    setState(() => _isLoading = true);

    try {
      final success = await ApiService.createPost(
        selectedType!,
        _titleController.text,
        _bodyController.text,
        _selectedMedia.map((file) => file.path).toList(),
        _links,
      );

      if (success && mounted) {
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

  void _showOptionsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedMainOption;
        String? selectedSubOption;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF3D1B45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedMainOption == null) ...[
                    ListTile(
                      title: const Text('Reporters', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Reporters';
                        });
                        Navigator.pop(context);
                        this.setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                    ListTile(
                      title: const Text('Islamic Knowledge', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() => selectedMainOption = 'Islamic Knowledge');
                      },
                    ),
                    ListTile(
                      title: const Text('Discussion', style: TextStyle(color: Color(0xFFFDCC87))),
                      onTap: () {
                        setState(() {
                          selectedType = 'Discussion';
                        });
                        Navigator.pop(context);
                        this.setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                  ] else if (selectedMainOption == 'Islamic Knowledge') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSubOption(
                          context,
                          'Teaching Quran',
                          'assets/quran.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                            this.setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                        const SizedBox(width: 10), // Add space between suboptions
                        _buildSubOption(
                          context,
                          'Hadith',
                          'assets/hadith.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                            this.setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                        const SizedBox(width: 10), // Add space between suboptions
                        _buildSubOption(
                          context,
                          'Tafsir',
                          'assets/tafsir.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                            this.setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                        const SizedBox(width: 10), // Add space between suboptions
                        _buildSubOption(
                          context,
                          'Sunnah',
                          'assets/sunnah.svg',
                          selectedSubOption,
                          (value) {
                            setState(() {
                              selectedSubOption = value;
                              selectedType = value;
                            });
                            Navigator.pop(context); // Close popup on selection
                            this.setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubOption(BuildContext context, String label, String assetPath, String? selected, Function(String) onTap) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFDCC87) : const Color(0xFF3D1B45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              assetPath,
              height: 40,
              width: 40,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.black : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(color: isSelected ? Colors.black : const Color(0xFFFDCC87)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    debugPrint('_onWillPop called with _hasChanges: $_hasChanges');
    if (!_hasChanges) return true;

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
          'Are you sure you want to go back and discard the post?',
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          debugPrint('Attempting to pop with _hasChanges: $_hasChanges');
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: PreferredSize(
          preferredSize: Size.zero,
          child: Container(), // Empty container with zero height
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
                            hintStyle: TextStyle(color: Color(0xFFFDCC87)),
                          ),
                        ),
                        const Divider(color: Color(0xFFFDCC87)),
                        TextField(
                          controller: _bodyController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Body Text',
                            hintStyle: TextStyle(color: Color(0xFFFDCC87)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedMedia.isNotEmpty)
                    Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedMedia.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: FileImage(_selectedMedia[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 15,
                                top: 5,
                                child: GestureDetector(
                                  onTap: () => _removeMedia(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

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
                        Text('Photos / Videos', style: TextStyle(color: Colors.white)),
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
                        Text('Link', style: TextStyle(color: Colors.white)),
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
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoading ? null : _createPost,
          backgroundColor: _isLoading ? Colors.grey : const Color(0xFFFDCC87),
          child: const Icon(Icons.post_add, color: Colors.black),
        ),
      ),
    );
  }
}
