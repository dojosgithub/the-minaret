import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Post extends StatefulWidget {
  final String name;
  final String username;
  final String profilePic;
  final String title;
  final String text;
  final List<Map<String, dynamic>> media;
  final List<Map<String, dynamic>> links;
  final int upvoteCount;
  final int downvoteCount;
  final int repostCount;

  const Post({
    super.key,
    required this.name,
    required this.username,
    required this.profilePic,
    required this.title,
    required this.text,
    this.media = const [],
    this.links = const [],
    required this.upvoteCount,
    required this.downvoteCount,
    required this.repostCount,
  });

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> {
  bool _isBookmarked = false;

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // You might want to show a snackbar or dialog here to inform the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }

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

  Widget _buildMediaGrid() {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.media.length == 1 ? 200 : 300, // Limit height for single images
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.media.length == 1 ? 1 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: widget.media.length == 1 ? 16/9 : 1, // Wider aspect ratio for single image
        ),
        itemCount: widget.media.length,
        itemBuilder: (context, index) {
          final mediaItem = widget.media[index];
          if (mediaItem['type'] == 'image') {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                mediaItem['url'],
                fit: BoxFit.cover,
              ),
            );
          } else if (mediaItem['type'] == 'video') {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_fill, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLinks() {
    if (widget.links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.links.map((link) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _launchURL(link['url']),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F245A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDCC87), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFFFDCC87)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link['title'] ?? link['url'],
                      style: const TextStyle(
                        color: Color(0xFFFDCC87),
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
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
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
          const SizedBox(height: 5),
          _buildLinks(),
          const SizedBox(height: 5),
          _buildMediaGrid(),
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