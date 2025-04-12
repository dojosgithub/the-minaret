import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/time_utils.dart';
import '../services/api_service.dart';
import '../screens/profile_screen.dart';
import '../screens/user_screen.dart';
import 'comment.dart';

class Post extends StatefulWidget {
  final String id;
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
  final int commentCount;
  final String createdAt;
  final String authorId;

  const Post({
    super.key,
    required this.id,
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
    required this.commentCount,
    required this.createdAt,
    required this.authorId,
  });

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> {
  bool _isBookmarked = false;
  bool _isLoading = false;
  bool _showComments = false;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    try {
      final isSaved = await ApiService.isPostSaved(widget.id);
      if (mounted) {
        setState(() {
          _isBookmarked = isSaved;
        });
      }
    } catch (e) {
      debugPrint('Error checking if post is saved: $e');
    }
  }

  Future<void> _toggleSave() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isBookmarked) {
        await ApiService.unsavePost(widget.id);
      } else {
        await ApiService.savePost(widget.id);
      }
      
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isBookmarked ? 'unsave' : 'save'} post')),
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

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // You might want to show a snackbar or dialog here to inform the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    try {
      // Get current user's ID
      final currentUser = await ApiService.getUserProfile();
      final currentUserId = currentUser['_id'];

      // Navigate to appropriate screen based on whether it's the current user
      if (widget.authorId == currentUserId) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: widget.authorId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to profile: $e');
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

  Future<void> _loadComments() async {
    if (_loadingComments) return;
    
    setState(() {
      _loadingComments = true;
    });

    try {
      final comments = await ApiService.getPostComments(widget.id);
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    } catch (e) {
      debugPrint('Error loading comments: $e');
      setState(() {
        _loadingComments = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      final newComment = await ApiService.addComment(
        widget.id,
        _commentController.text,
      );
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> _addReply(String commentId) async {
    if (_replyController.text.trim().isEmpty) return;
    
    try {
      final newReply = await ApiService.addReply(
        widget.id,
        commentId,
        _replyController.text,
      );
      setState(() {
        final commentIndex = _comments.indexWhere((c) => c['_id'] == commentId);
        if (commentIndex != -1) {
          _comments[commentIndex]['replies'].insert(0, newReply);
        }
        _replyController.clear();
        _replyingToCommentId = null;
      });
    } catch (e) {
      debugPrint('Error adding reply: $e');
    }
  }

  Widget _buildMediaGrid() {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    if (widget.media.length == 1) {
      return GestureDetector(
        onTap: () => _showGalleryView(0),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              widget.media[0]['url'],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
        ),
      );
    }

    // For multiple images, show 2 or 4 with +N overlay
    final int displayCount = widget.media.length == 3 ? 2 : (widget.media.length <= 2 ? 2 : 4);
    final int remainingCount = widget.media.length - displayCount;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: displayCount == 2 ? 2 : 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final bool isLastItem = index == displayCount - 1 && remainingCount > 0;
        
        return GestureDetector(
          onTap: () => _showGalleryView(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  widget.media[index]['url'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              if (isLastItem)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showGalleryView(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: widget.media.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      widget.media[index]['url'],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
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

  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(context),
          child: Container(
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
                        onTap: () => _navigateToProfile(context),
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
                        onTap: () => _navigateToProfile(context),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTimeAgo(DateTime.parse(widget.createdAt)),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                                    ),
                                  )
                                : Icon(
                                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: const Color(0xFFFDCC87),
                                  ),
                            onPressed: _toggleSave,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 1),
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
          _buildUserInfo(),
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
                    style: const TextStyle(color: Color(0xFFFDCC87)),
                  ),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showComments = !_showComments;
                        if (_showComments) {
                          _loadComments();
                        }
                      });
                    },
                  ),
                  Text(
                    widget.commentCount.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _showSharePopup(context),
              ),
            ],
          ),
          if (_showComments) ...[
            const Divider(color: Color(0xFFFDCC87)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFFDCC87)),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                  if (_loadingComments)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                      ),
                    )
                  else
                    ..._comments.map((comment) => Comment(
                      authorName: '${comment['author']['firstName']} ${comment['author']['lastName']}',
                      authorUsername: comment['author']['username'],
                      authorProfilePic: comment['author']['profileImage'],
                      text: comment['text'],
                      createdAt: comment['createdAt'],
                      replies: List<Map<String, dynamic>>.from(comment['replies'] ?? []),
                      onReply: () {
                        setState(() {
                          _replyingToCommentId = comment['_id'];
                        });
                      },
                    )).toList(),
                  if (_replyingToCommentId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a reply...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFFFDCC87)),
                          onPressed: () => _addReply(_replyingToCommentId!),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}