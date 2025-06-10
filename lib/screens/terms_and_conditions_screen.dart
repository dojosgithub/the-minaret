import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/top_bar_without_menu.dart';
import 'apple_registration_screen.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isAccepted = false;
  bool _hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const TopBarWithoutMenu(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F245A), Color(0xFF3D1B45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Terms and Conditions",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Please read these terms carefully before using Minaret",
                      style: TextStyle(
                        color: Color(0xFFFDCC87),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A1E47),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFFDCC87), width: 1),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("End User License Agreement (EULA)"),
                        _buildParagraph(
                          "By using Minaret, you agree to be bound by this End User License Agreement. "
                          "This agreement grants you a non-exclusive, non-transferable license to use the app for personal, "
                          "non-commercial purposes."
                        ),
                        
                        _buildSectionTitle("ZERO TOLERANCE FOR OBJECTIONABLE CONTENT"),
                        _buildParagraph(
                          "Minaret has a ZERO TOLERANCE policy for objectionable content. Users who post, share, or engage "
                          "with content that violates our guidelines will face immediate consequences, including but not limited "
                          "to content removal, account suspension, or permanent account termination."
                        ),
                        _buildParagraph(
                          "We take our community standards seriously and actively monitor content to maintain a safe and respectful "
                          "environment for all users. By accepting these terms, you acknowledge your responsibility to help maintain "
                          "these standards and agree to report any objectionable content you encounter."
                        ),
                        
                        _buildSectionTitle("Content Policy"),
                        _buildParagraph(
                          "You agree not to post, upload, or share any content that is:"
                        ),
                        _buildBulletPoint("Illegal, harmful, threatening, abusive, or harassing"),
                        _buildBulletPoint("Defamatory, vulgar, obscene, or contains hate speech"),
                        _buildBulletPoint("Violates the privacy or intellectual property rights of others"),
                        _buildBulletPoint("Contains false information or misrepresents facts"),
                        _buildBulletPoint("Promotes violence, discrimination, or illegal activities"),
                        _buildBulletPoint("Contains malware, viruses, or harmful code"),
                        
                        _buildSectionTitle("User Conduct"),
                        _buildParagraph(
                          "Minaret is committed to providing a safe, respectful environment. We do not tolerate:"
                        ),
                        _buildBulletPoint("Harassment or bullying of any kind"),
                        _buildBulletPoint("Hate speech targeting individuals or groups"),
                        _buildBulletPoint("Impersonation of others or misrepresentation"),
                        _buildBulletPoint("Spam, phishing, or other disruptive behaviors"),
                        
                        _buildSectionTitle("Content Moderation and Reporting"),
                        _buildParagraph(
                          "Minaret employs automated and manual content moderation. Content that violates our policies will be removed, "
                          "and accounts that repeatedly violate our terms may be suspended or terminated."
                        ),
                        _buildParagraph(
                          "All users have the ability and responsibility to report objectionable content through the app's reporting features. "
                          "When you encounter content that violates our guidelines, please use the report function available on posts, comments, "
                          "and user profiles. Your reports will be reviewed promptly by our moderation team."
                        ),
                        
                        _buildSectionTitle("Privacy Policy"),
                        _buildParagraph(
                          "We collect and process personal data as described in our Privacy Policy. "
                          "By using Minaret, you consent to our data practices as outlined therein."
                        ),
                        
                        _buildSectionTitle("Termination"),
                        _buildParagraph(
                          "We reserve the right to terminate or suspend your account at any time for violations "
                          "of these terms or for any other reason at our sole discretion."
                        ),
                        
                        _buildSectionTitle("Changes to Terms"),
                        _buildParagraph(
                          "We may update these terms from time to time. Continued use of Minaret after changes "
                          "constitutes acceptance of the revised terms."
                        ),

                        _buildSectionTitle("Contact"),
                        _buildParagraph(
                          "If you have questions about these terms or wish to report a violation, "
                          "please contact us at support@minaret.com"
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isAccepted,
                          onChanged: _hasScrolledToBottom 
                            ? (value) {
                                setState(() {
                                  _isAccepted = value ?? false;
                                });
                              }
                            : null,
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.withOpacity(0.5);
                              }
                              if (states.contains(MaterialState.selected)) {
                                return const Color(0xFFFDCC87);
                              }
                              return Colors.grey;
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "I have read and agree to the Terms and Conditions, Content Policy, and Privacy Policy. I understand that there is ZERO TOLERANCE for objectionable content.",
                            style: TextStyle(
                              color: _hasScrolledToBottom ? Colors.white : Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_hasScrolledToBottom)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, left: 42.0),
                        child: Text(
                          "Please scroll through the entire document to continue",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isAccepted && _hasScrolledToBottom) ? const Color(0xFFFDCC87) : Colors.grey,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: (_isAccepted && _hasScrolledToBottom)
                          ? () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MainScreen()),
                              );
                            }
                          : null,
                      child: const Text(
                        "Continue",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFDCC87),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              color: Color(0xFFFDCC87),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 