import 'package:flutter/material.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F245A), Color(0xFF3D1B45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 30),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  backgroundColor: Color(0xFFFDCC87),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {},
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

  Widget _buildTextField(String hint, {bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items) {
    return DropdownButtonFormField(
      dropdownColor: Color(0xFF3D1B45),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: const TextStyle(color: Colors.white)),
      )).toList(),
      onChanged: (value) {},
    );
  }

  Widget _buildSelectableOption(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
