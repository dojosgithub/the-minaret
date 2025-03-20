import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/top_bar_without_menu.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Prevents default white background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: TopBarWithoutMenu(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // Ensures full coverage
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F245A), Color(0xFF3D1B45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView( // Prevents overflow if content exceeds screen size
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildTextField('First Name')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Last Name')),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField('Username'),
              const SizedBox(height: 15),
              _buildTextField('Phone Number'),
              const SizedBox(height: 15),
              _buildTextField('Password', obscureText: true),
              const SizedBox(height: 15),
              _buildTextField('Confirm Password', obscureText: true),
              const SizedBox(height: 20),
              const Text('Birthday', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  Expanded(child: _buildDropdown(['Day'])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDropdown(['Month'])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDropdown(['Year'])),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildSelectableOption('Muslim'),
                  _buildSelectableOption('Non-Muslim'),
                  _buildSelectableOption('Scholar'),
                  _buildSelectableOption('Reporter'),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDCC87),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                child: const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF3A1E47), // Darker than background
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey),
        ),
      ),
      child: Text(
        items.first,
        style: const TextStyle(color: Color(0xFFFDCC87)), // Signature yellow
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSelectableOption(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
