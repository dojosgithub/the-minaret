import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submitFeedback() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _commentsController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields';
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _error = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ApiService.submitFeedback(
        name: _nameController.text,
        email: _emailController.text,
        feedback: _commentsController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Color(0xFFFDCC87),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = 'Failed to submit feedback';
      
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else if (e.toString().contains('Server error')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('Failed to connect to server')) {
        errorMessage = 'Could not connect to server. Please try again later.';
      }
      
      setState(() {
        _error = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),

      // Top App Bar with Logo & Menu Button
      appBar: const TopBarWithoutMenu(),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Arrow & Title
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Feedback",
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Name TextField
            _buildTextField(controller: _nameController, hint: "Name"),

            const SizedBox(height: 15),

            // Email TextField
            _buildTextField(controller: _emailController, hint: "Email"),

            const SizedBox(height: 20),

            // Subtitle
            const Text(
              "Share your experience in scaling",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),

            const SizedBox(height: 8),

            // Expandable Comments Box
            Expanded(
              child: _buildTextField(
                controller: _commentsController,
                hint: "Add your comments...",
                maxLines: null, // Expandable
                expands: true, // Ensures it fits inside the screen
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 20),

            // Submit Button (Floating Right)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDCC87), // Yellow Color
                  foregroundColor: Colors.black, // Text color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _submitFeedback,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    bool expands = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // Darker than background
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        expands: expands,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none, // Removes default border
        ),
      ),
    );
  }
}
