import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';
import 'change_password_screen.dart';

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
  DateTime? _selectedDate;
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
        _selectedDate = data['dateOfBirth'] != null 
            ? DateTime.parse(data['dateOfBirth']) 
            : null;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Limit image size
        maxHeight: 1024,
        imageQuality: 85, // Compress image
      );
      
      if (image != null) {
        // Verify file type
        String extension = image.path.split('.').last.toLowerCase();
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
        'dateOfBirth': _selectedDate?.toIso8601String(),
      };

      // Upload image if selected
      if (_imageFile != null) {
        final String? imageUrl = await ApiService.uploadProfileImage(_imageFile!);
        if (imageUrl != null) {
          updateData['profileImage'] = imageUrl;
        }
      }

      // Update profile
      await ApiService.updateProfile(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context); // Go back to previous screen
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
                            ? NetworkImage(userData!['profileImage'])
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
            _buildDatePicker(),
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

  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDropdown(['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'], 'Day'),
        _buildDropdown(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'], 'Month'),
        _buildDropdown(List.generate(100, (index) => (2024 - index).toString()), 'Year'),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String hint) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1D47),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF3A1D47),
          iconEnabledColor: const Color(0xFFFDCC87),
          style: const TextStyle(color: Colors.white),
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {},
        ),
      ),
    );
  }
}
