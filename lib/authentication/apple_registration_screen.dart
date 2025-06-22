import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';
import 'terms_and_conditions_screen.dart';

class AppleRegistrationScreen extends StatefulWidget {
  const AppleRegistrationScreen({super.key});

  @override
  State<AppleRegistrationScreen> createState() => _AppleRegistrationScreenState();
}

class _AppleRegistrationScreenState extends State<AppleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isTypeExpanded = false;
  String _selectedType = 'Type';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      // Create update data with needsProfileCompletion set to false
      final updateData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'userType': _selectedType != 'Type' ? _selectedType : 'Muslim', // Default to Muslim if not selected
        'needsProfileCompletion': false,
      };

      // Update the user profile
      final response = await ApiService.updateProfile(updateData);

      if (!mounted) return;

      if (response) {
        // Check if user has accepted terms and conditions
        final userProfile = await ApiService.getUserProfile();
        final acceptedTerms = userProfile['acceptedTermsandConditions'] ?? false;
        
        if (!acceptedTerms) {
          // Navigate to Terms and Conditions screen if terms haven't been accepted
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
          );
        } else {
          // Navigate directly to main screen if terms have been accepted
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile update failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: TopBarWithoutMenu(),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F245A), Color(0xFF3D1B45)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please provide the following information to complete your registration.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'First Name',
                        controller: _firstNameController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        'Last Name',
                        controller: _lastNameController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  'Username',
                  controller: _usernameController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildUserTypeField(),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                    ),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDCC87),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _updateProfile,
                    child: const Text(
                      'Complete Registration',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF3A1E47),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(25),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(25),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('User Type (Optional)', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () {
            setState(() {
              _isTypeExpanded = !_isTypeExpanded;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3A1E47),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType,
                        style: TextStyle(
                          color: _selectedType == 'Type'
                              ? Colors.grey
                              : const Color(0xFFFDCC87),
                        ),
                      ),
                      Icon(
                        _isTypeExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: const Color(0xFFFDCC87),
                      ),
                    ],
                  ),
                ),
                if (_isTypeExpanded)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTypeOption('Muslim'),
                        _buildTypeOption('Non-Muslim'),
                        _buildTypeOption('Scholar'),
                        _buildTypeOption('Reporter'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = text;
          _isTypeExpanded = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
} 