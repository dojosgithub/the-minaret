import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/time_utils.dart';
import '../services/api_service.dart';
import '../screens/profile_screen.dart';
import '../screens/user_screen.dart';
import 'comment.dart';
import 'dart:convert';
import '../screens/new_message_screen.dart';
import '../services/message_service.dart';

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
  final bool isUpvoted;
  final bool isDownvoted;
  final bool isRepost;
  final Map<String, dynamic>? originalPost;
  final Function(String) onUpvote;
  final Function(String) onDownvote;

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
    this.isUpvoted = false,
    this.isDownvoted = false,
    this.isRepost = false,
    this.originalPost,
    required this.onUpvote,
    required this.onDownvote,
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
  bool _isUpvoted = false;
  bool _isDownvoted = false;
  int _upvoteCount = 0;
  int _downvoteCount = 0;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _checkVoteStatus();
    _isUpvoted = widget.isUpvoted;
    _isDownvoted = widget.isDownvoted;
    _upvoteCount = widget.upvoteCount;
    _downvoteCount = widget.downvoteCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _checkVoteStatus() async {
    try {
      final status = await ApiService.getPostVoteStatus(widget.id);
      if (mounted) {
        setState(() {
          _isUpvoted = status['isUpvoted'] ?? false;
          _isDownvoted = status['isDownvoted'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error checking vote status: $e');
    }
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
        // navigate to profile screen
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF4F245A),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3D1B45),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Share Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Recent users section
                  FutureBuilder<List<dynamic>>(
                    future: _loadRecentUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFFDCC87)));
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading recent users', style: TextStyle(color: Colors.white)));
                      }
                      final users = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    try {
                                      await ApiService.sendMessage(
                                        user['id'],
                                        'Check out this post: ${widget.title}',
                                        null,
                                        widget.id,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Post shared successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to share post: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFFDCC87),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Image.network(
                                              user['profilePicture'] ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.person, size: 30, color: Color(0xFFFDCC87));
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          user['username'] ?? '',
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Share options section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareOption(
                        icon: Icons.message,
                        label: 'Message',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewMessageScreen(
                                initialPost: {
                                  '_id': widget.id,
                                  'title': widget.title,
                                  'body': widget.text,
                                  'media': widget.media,
                                  'author': {
                                    'username': widget.username,
                                    'firstName': widget.name.split(' ')[0],
                                    'lastName': widget.name.split(' ').length > 1 ? widget.name.split(' ')[1] : '',
                                    'profileImage': widget.profilePic,
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      _buildShareOption(
                        icon: Icons.copy,
                        label: 'Copy Link',
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                            text: 'https://minaret.com/posts/${widget.id}',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard')),
                          );
                          Navigator.pop(context);
                        },
                      ),
                      _buildShareOption(
                        icon: Icons.share,
                        label: 'More',
                        onTap: () {
                          // Implement native share functionality
                          Navigator.pop(context);
                        },
                      ),
                      GestureDetector(
                        onTap: () async {
                          final url = 'https://wa.me/?text=Check out this post: https://minaret.com/posts/${widget.id}';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch WhatsApp')),
                            );
                          }
                          Navigator.pop(context);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F245A),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFDCC87)),
                              ),
                              child: Image.asset(
                                'assets/whatsapp.png',
                                width: 30,
                                height: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'WhatsApp',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      _buildShareOption(
                        icon: Icons.telegram,
                        label: 'Telegram',
                        onTap: () async {
                          final url = 'https://t.me/share/url?url=https://minaret.com/posts/${widget.id}&text=Check out this post: ${widget.title}';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch Telegram')),
                            );
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4F245A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDCC87)),
            ),
            child: Icon(icon, color: const Color(0xFFFDCC87)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _loadRecentUsers() async {
    try {
      // First try to get recent conversations
      final conversations = await MessageService.getConversations();
      if (conversations.isNotEmpty) {
        return conversations.map((conv) => {
          'id': conv.id,
          'username': conv.participants[0]['username'],
          'firstName': conv.participants[0]['firstName'],
          'lastName': conv.participants[0]['lastName'],
          'profilePicture': conv.participants[0]['profileImage'],
        }).toList();
      }
      
      // If no conversations, get followed users
      final response = await ApiService.getFollowedUsers();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error loading recent users: $e');
      return [];
    }
  }

  void _showReportPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF4F245A),
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
          _buildRepostedContent(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_upward,
                      color: _isUpvoted ? const Color(0xFFFDCC87) : Colors.white,
                    ),
                    onPressed: () {
                      _handleUpvote();
                    },
                  ),
                  Text(
                    _upvoteCount.toString(),
                    style: TextStyle(
                      color: _isUpvoted ? const Color(0xFFFDCC87) : Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_downward,
                      color: _isDownvoted ? const Color(0xFFFDCC87) : Colors.white,
                    ),
                    onPressed: () {
                      _handleDownvote();
                    },
                  ),
                  Text(
                    _downvoteCount.toString(),
                    style: TextStyle(
                      color: _isDownvoted ? const Color(0xFFFDCC87) : Colors.white,
                    ),
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
                    onPressed: _handleRepost,
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

  Future<void> _handleUpvote() async {
    try {
      await widget.onUpvote(widget.id);
      setState(() {
        if (_isUpvoted) {
          _upvoteCount--;
          _isUpvoted = false;
        } else {
          _upvoteCount++;
          _isUpvoted = true;
          if (_isDownvoted) {
            _downvoteCount--;
            _isDownvoted = false;
          }
        }
      });
    } catch (e) {
      debugPrint('Error upvoting: $e');
    }
  }

  Future<void> _handleDownvote() async {
    try {
      await widget.onDownvote(widget.id);
      setState(() {
        if (_isDownvoted) {
          _downvoteCount--;
          _isDownvoted = false;
        } else {
          _downvoteCount++;
          _isDownvoted = true;
          if (_isUpvoted) {
            _upvoteCount--;
            _isUpvoted = false;
          }
        }
      });
    } catch (e) {
      debugPrint('Error downvoting: $e');
    }
  }

  Future<void> _handleRepost() async {
    try {
      await ApiService.repostPost(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post reposted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildRepostedContent() {
    if (!widget.isRepost || widget.originalPost == null) {
      return const SizedBox.shrink();
    }

    final originalAuthor = widget.originalPost!['author'];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFDCC87)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFDCC87),
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage(originalAuthor['profileImage']),
                  radius: 15,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${originalAuthor['firstName']} ${originalAuthor['lastName']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '@${originalAuthor['username']}',
                    style: const TextStyle(
                      color: Color(0xFFFDCC87),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.originalPost!['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.originalPost!['body'],
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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
          // Ensure replies array exists and is properly typed
          if (_comments[commentIndex]['replies'] == null) {
            _comments[commentIndex]['replies'] = [];
          }
          // Cast to List<Map<String, dynamic>> and insert the new reply
          final replies = List<Map<String, dynamic>>.from(_comments[commentIndex]['replies']);
          replies.insert(0, newReply);
          _comments[commentIndex]['replies'] = replies;
        }
        _replyController.clear();
        _replyingToCommentId = null;
      });
    } catch (e) {
      debugPrint('Error adding reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add reply')),
        );
      }
    }
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
}