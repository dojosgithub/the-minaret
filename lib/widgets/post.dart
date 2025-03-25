import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Post extends StatefulWidget {
  final String name;
  final String username;
  final String profilePic;
  final String text;
  final int upvoteCount; 
  final int downvoteCount; 
  final int repostCount; 

  const Post({
    super.key,
    required this.name,
    required this.username,
    required this.profilePic,
    required this.text,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.repostCount,
  });

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> {
  bool _isBookmarked = false;

  void _showSharePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF3D1B45),
                borderRadius: BorderRadius.circular(15),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Send To",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: List.generate(6, (index) {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFDCC87),
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 20,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "User Name",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      );
                    }),
                  ),
                  const Divider(
                    color: Color(0xFFFDCC87),
                    thickness: 1,
                    height: 20,
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildShareOption(context, Icons.link, "Copy Link", () {
                        Clipboard.setData(const ClipboardData(text: "Post Link"));
                        Navigator.pop(context);
                        _showCopiedMessage(context);
                      }),
                      _buildShareOption(context, Icons.heart_broken, "Not Interested", () {}),
                      _buildShareOption(context, Icons.flag, "Report", () {
                        _showReportPopup(context);
                      }),
                      _buildShareOption(context, Icons.repeat, "Repost", () {}),
                      _buildShareOptionWithImage(context, "assets/whatsapp.png", "WhatsApp", () {}),
                      _buildShareOptionWithImage(context, "assets/telegram.png", "Telegram", () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReportPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF3D1B45),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Report Post",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _buildReportReason("Spam"),
                    _buildReportReason("Harassment"),
                    _buildReportReason("Misinformation"),
                    _buildReportReason("Hate Speech"),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDCC87),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Submit Report",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportReason(String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked, color: Colors.white),
          const SizedBox(width: 10),
          Text(reason, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          width: 50, // Match user circle size
          height: 50, // Match user circle size
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFDCC87), // Yellow circle
          ),
          child: IconButton(icon: Icon(icon, color: Colors.black), onPressed: onTap),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildShareOptionWithImage(BuildContext context, String assetPath, String label, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          width: 50, // Match user circle size
          height: 50, // Match user circle size
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFDCC87), // Yellow circle
          ),
          child: IconButton(
            icon: Image.asset(assetPath, fit: BoxFit.cover),
            onPressed: onTap,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  void _showCopiedMessage(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3D1B45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("Link Copied", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1B45),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(52),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  backgroundImage: AssetImage(widget.profilePic),
                  radius: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                widget.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                '@${widget.username}',
                                style: const TextStyle(
                                  color: Color(0xFFFDCC87),
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: const Color(0xFFFDCC87),
                          ),
                          onPressed: () {
                            setState(() {
                              _isBookmarked = !_isBookmarked;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Color(0xFFFDCC87)),
                    onPressed: () {},
                  ),
                  Text(
                    widget.upvoteCount.toString(),
                    style: const TextStyle(color: Color(0xFFFDCC87), // Yellow color for upvote count
                  ),
                  )
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Colors.grey),
                    onPressed: () {},
                  ),
                  Text(
                    widget.downvoteCount.toString(),
                    style: const TextStyle(color: Colors.white), // White color for downvote count
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.white),
                    onPressed: () {},
                  ),
                  // Text(
                  //   "0", // Placeholder for comment count (if needed)
                  //   style: const TextStyle(color: Colors.white),
                  // ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.repeat, color: Colors.white),
                    onPressed: () {},
                  ),
                  Text(
                    widget.repostCount.toString(),
                    style: const TextStyle(color: Colors.white), // White color for repost count
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _showSharePopup(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}