import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import 'continue_with_screen.dart';
import 'phone_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    phoneNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.5, 0.9],
            colors: [Color(0xFF4F245A), Color(0xFF9D3267)],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9,
                minHeight: screenHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        height: screenHeight * 0.2,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Phone Number Field
                    const Text(
                      'Phone Number',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: phoneNumberController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PhoneScreen(isForgotPassword: true),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFFFDCC87),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Login Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDCC87),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () async {
                        if (phoneNumberController.text.isEmpty || passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter both phone number and password'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Show loading indicator
                          if (!mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                                ),
                              );
                            },
                          );

                          // Test connection first
                          print('Testing connection...'); // Debug log
                          bool isConnected = await ApiService.testConnection();
                          
                          if (!isConnected) {
                            if (!mounted) return;
                            Navigator.pop(context); // Hide loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot connect to server. Please check if the server is running.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          print('Connection successful, attempting login...'); // Debug log
                          final result = await ApiService.login(
                            phoneNumberController.text,
                            passwordController.text,
                          );
                          
                          if (!mounted) return;
                          Navigator.pop(context); // Hide loading
                          
                          if (result) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainScreen()),
                            );
                          }
                        } catch (e) {
                          print('Login error: $e'); // Debug log
                          if (!mounted) return;
                          // Make sure to close the loading dialog
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sign Up Text
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContinueWithScreen(),
                          ),
                        );
                      },
                      child: const Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: TextStyle(
                                  color: Color(0xFFFDCC87),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final isConnected = await ApiService.testConnection();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isConnected 
                                  ? 'Successfully connected to server!' 
                                  : 'Could not connect to server'),
                                backgroundColor: isConnected ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 