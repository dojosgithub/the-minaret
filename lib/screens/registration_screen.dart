import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/top_bar_without_menu.dart';
import 'dart:ui';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _isTypeExpanded = false;
  String _selectedType = 'Type';
  String _selectedDay = 'Day';
  String _selectedMonth = 'Month';
  String _selectedYear = 'Year';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A), // Match the top gradient color
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100), // Match the new top bar height
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
              _buildBirthdayField(),
              const SizedBox(height: 20),
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
                  _selectedDay == 'Day' 
                      ? 'Select Birthday'
                      : '$_selectedDay $_selectedMonth $_selectedYear',
                  style: TextStyle(
                    color: _selectedDay == 'Day' 
                        ? Colors.grey 
                        : const Color(0xFFFDCC87),
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
}
