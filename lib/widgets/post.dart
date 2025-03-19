import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Post extends StatelessWidget {
  final String name;
  final String username;
  final String profilePic;
  final String text;

  const Post({
    super.key,
    required this.name,
    required this.username,
    required this.profilePic,
    required this.text,
  });

  void _showSharePopup(BuildContext context) {
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
                const Text("Send To", style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        const Text("User Name", style: TextStyle(color: Colors.white, fontSize: 12))
                      ],
                    );
                  }),
                ),
                const Divider(color: Color(0xFFFDCC87), thickness: 1, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(context, Icons.link, "Copy Link", () {
                      Clipboard.setData(const ClipboardData(text: "Post Link"));
                      Navigator.pop(context);
                      _showCopiedMessage(context);
                    }),
                    _buildShareOption(context, Icons.heart_broken, "Not Interested", () {}),
                    _buildShareOption(context, Icons.flag, "Flag", () {}),
                    _buildShareOption(context, Icons.repeat, "Repost", () {}),
                    _buildShareOptionWithImage(context, "assets/whatsapp.png", "WhatsApp", () {}),
                    _buildShareOptionWithImage(context, "assets/telegram.png", "Telegram", () {}),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildShareOptionWithImage(BuildContext context, String assetPath, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          icon: Image.asset(assetPath, width: 30, height: 30),
          onPressed: onTap,
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
                  backgroundImage: AssetImage(profilePic),
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
                                name,
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
                                '@$username',
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
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: Color(0xFFFDCC87),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      text,
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
              IconButton(icon: const Icon(Icons.arrow_upward, color: Color(0xFFFDCC87)), onPressed: () {}),
              IconButton(icon: const Icon(Icons.arrow_downward, color: Colors.grey), onPressed: () {}),
              IconButton(icon: const Icon(Icons.comment, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.repeat, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => _showSharePopup(context)),
            ],
          ),
        ],
      ),
    );
  }
}
