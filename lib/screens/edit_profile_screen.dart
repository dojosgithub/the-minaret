import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';
import 'change_password_screen.dart';
import '../services/image_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  File? _imageFile;
  bool isLoading = true;
  String _selectedDay = 'Day';
  String _selectedMonth = 'Month';
  String _selectedYear = 'Year';
  bool _isDateExpanded = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await ApiService.getUserProfile();
      setState(() {
        userData = data;
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        if (data['dateOfBirth'] != null) {
          final date = DateTime.parse(data['dateOfBirth']);
          _selectedDay = date.day.toString().padLeft(2, '0');
          _selectedMonth = _getMonthName(date.month);
          _selectedYear = date.year.toString();
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  String _getMonthName(int month) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500, // Limit image size
        maxHeight: 500,
        imageQuality: 85, // Compress image
      );
      
      if (image != null) {
        if (image.path.startsWith('blob:')) {
          setState(() {
          _imageFile = File(image.path); // This may still not work on web, but allows mobile/desktop
        });
        return;
        }
        // Verify file type
        String extension = image.path.split('.').last.toLowerCase();
        print('Picked file path: ${image.path}');
        print('Detected extension: $extension');
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a JPG or PNG image')),
            );
          }
          return;
        }

        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Dialog(
              backgroundColor: const Color(0xFF3A1E47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 300,
                child: Column(
                  children: [
                    const Text(
                      'Select Birthday',
                      style: TextStyle(
                        color: Color(0xFFFDCC87),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Stack(
                        children: [
                          // Selection lines
                          Positioned.fill(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 1,
                                    color: const Color(0xFFFDCC87),
                                  ),
                                  const SizedBox(height: 38),
                                  Container(
                                    height: 1,
                                    color: const Color(0xFFFDCC87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // Day picker
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 31,
                                    builder: (context, index) {
                                      return Center(
                                        child: Text(
                                          index < 9 ? '0${index + 1}' : '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedDay = index < 9 ? '0${index + 1}' : '${index + 1}';
                                    });
                                  },
                                ),
                              ),
                              // Month picker
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 12,
                                    builder: (context, index) {
                                      final months = [
                                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                      ];
                                      return Center(
                                        child: Text(
                                          months[index],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  onSelectedItemChanged: (index) {
                                    final months = [
                                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                    ];
                                    setState(() {
                                      _selectedMonth = months[index];
                                    });
                                  },
                                ),
                              ),
                              // Year picker
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 100,
                                    builder: (context, index) {
                                      return Center(
                                        child: Text(
                                          '${2024 - index}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedYear = '${2024 - index}';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDCC87),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBirthdayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Birthday', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _showDatePicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A1E47),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay != 'Day' && _selectedMonth != 'Month' && _selectedYear != 'Year'
                      ? '$_selectedDay $_selectedMonth $_selectedYear'
                      : 'Select Birthday',
                  style: TextStyle(
                    color: _selectedDay != 'Day' ? const Color(0xFFFDCC87) : Colors.grey,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFFDCC87),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => isLoading = true);

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'bio': _bioController.text,
        'phoneNumber': _phoneController.text,
      };

      // Add date of birth if selected
      if (_selectedDay != 'Day' && _selectedMonth != 'Month' && _selectedYear != 'Year') {
        final monthMap = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };
        final date = DateTime(
          int.parse(_selectedYear),
          monthMap[_selectedMonth]!,
          int.parse(_selectedDay),
        );
        updateData['dateOfBirth'] = date.toIso8601String();
      }

      // Upload image if selected
      if (_imageFile != null) {
        try {
          final imageUrl = await ImageService.uploadProfileImage(
            _imageFile!,
            userData!['_id'],
          );
          updateData['profileImage'] = imageUrl;
        } catch (e) {
          debugPrint('Error uploading profile image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload profile image')),
            );
          }
        }
      }

      // Update profile
      await ApiService.updateProfile(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF4F245A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: TopBarWithoutMenu(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (userData?['profileImage'] != null
                            ? NetworkImage(ApiService.resolveImageUrl(userData!['profileImage']))
                            : const AssetImage('assets/default_profile.png')) as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Change Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField('First Name', _firstNameController)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField('Last Name', _lastNameController)),
              ],
            ),
            _buildTextField('Username', _usernameController),
            _buildTextField('Bio', _bioController, maxLines: 3),
            _buildTextField('Phone Number', _phoneController),
            const SizedBox(height: 15),
            _buildBirthdayField(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDCC87),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
              child: const Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF3A1D47),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        controller: controller,
      ),
    );
  }
}
