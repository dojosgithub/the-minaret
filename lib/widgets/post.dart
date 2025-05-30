import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/time_utils.dart';
import '../services/api_service.dart';
import '../screens/profile_screen.dart';
import 'comment.dart';
import '../services/message_service.dart';
import 'repost_content.dart';
import '../screens/post_detail_screen.dart';
import 'dart:async';

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
  final String? repostCaption;
  final Map<String, dynamic>? originalPost;
  final Function(String) onUpvote;
  final Function(String) onDownvote;
  final bool isSaved;
  final Function(String)? onPostBlocked; // Callback when a post is from a blocked user

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
    this.repostCaption,
    this.originalPost,
    required this.onUpvote,
    required this.onDownvote,
    this.isSaved = false,
    this.onPostBlocked,
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
  int _repostCount = 0;
  int _commentCount = 0;
  Map<String, int> _visibleRepliesCount = {};
  Map<String, bool> _showReplies = {};
  int _visibleCommentsCount = 5;
  static const int _commentsPerPage = 5;
  static const int _repliesPerPage = 5;
  final TextEditingController _repostController = TextEditingController();
  bool _isExpanded = false;
  bool _isCommentExpanded = false;
  final List<bool> _loadingImages = [];
  bool _isUserBlocked = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _checkVoteStatus();
    _isUpvoted = widget.isUpvoted;
    _isDownvoted = widget.isDownvoted;
    _upvoteCount = widget.upvoteCount;
    _downvoteCount = widget.downvoteCount;
    _repostCount = widget.repostCount;
    _commentCount = widget.commentCount;
    _isBookmarked = widget.isSaved;
    _initializeImageLoading();
    _checkIfUserBlocked();
  }

  @override
  void didUpdateWidget(Post oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update saved state when widget.isSaved changes
    if (oldWidget.isSaved != widget.isSaved) {
      setState(() {
        _isBookmarked = widget.isSaved;
      });
    }
    
    // Update other states that might have changed
    if (oldWidget.isUpvoted != widget.isUpvoted) {
      setState(() {
        _isUpvoted = widget.isUpvoted;
      });
    }
    
    if (oldWidget.isDownvoted != widget.isDownvoted) {
      setState(() {
        _isDownvoted = widget.isDownvoted;
      });
    }
    
    if (oldWidget.upvoteCount != widget.upvoteCount) {
      setState(() {
        _upvoteCount = widget.upvoteCount;
      });
    }
    
    if (oldWidget.downvoteCount != widget.downvoteCount) {
      setState(() {
        _downvoteCount = widget.downvoteCount;
      });
    }
    
    if (oldWidget.repostCount != widget.repostCount) {
      setState(() {
        _repostCount = widget.repostCount;
      });
    }
    
    if (oldWidget.commentCount != widget.commentCount) {
      setState(() {
        _commentCount = widget.commentCount;
      });
    }

    if (oldWidget.media.length != widget.media.length) {
      _initializeImageLoading();
    }

    // Check if author ID changed and recheck block status
    if (oldWidget.authorId != widget.authorId) {
      _checkIfUserBlocked();
    }
  }

  void _initializeImageLoading() {
    // Initialize all images as loading by default
    _loadingImages.clear();
    for (int i = 0; i < widget.media.length; i++) {
      _loadingImages.add(true); // Set to true to load images automatically
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _repostController.dispose();
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
      // If it's already known to be saved (e.g., in the saved tab),
      // don't make an API call to check again
      if (widget.isSaved) {
        setState(() {
          _isBookmarked = true;
        });
        return;
      }
      
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
        if (mounted) {
          setState(() {
            _isBookmarked = false;
          });
        }
      } else {
        await ApiService.savePost(widget.id);
        if (mounted) {
          setState(() {
            _isBookmarked = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
      
      // Check if the error is about a post already being saved
      // In this case, we don't show an error message and update the bookmark state
      if (e.toString().contains('Post already saved')) {
        if (mounted) {
          setState(() {
            _isBookmarked = true;
          });
        }
      } else {
        // Use the "saved" status of the post after the error
        // If the error happened after unsaving, keep the bookmark as saved
        // If the error happened after saving, check the actual save status
        if (_isBookmarked) {
          // Was trying to unsave, but failed, so stay bookmarked
          // Don't show error message in this case since it could be a notification error
        } else {
          // Was trying to save, but failed with error
          // Check if post was actually saved despite the error
          try {
            final isSaved = await ApiService.isPostSaved(widget.id);
            setState(() {
              _isBookmarked = isSaved;
            });
            if (!isSaved && mounted) {
              _showSnackBar('Failed to save post');
            }
          } catch (checkError) {
            // If checking save status also fails, show original error
            if (mounted) {
              _showSnackBar('Failed to save post: ${e.toString()}');
            }
          }
        }
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
      // Ensure the URL has a scheme
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      // Try to launch the URL
      bool launched = false;
      try {
        if (await canLaunchUrlString(url)) {
          await launchUrlString(url, mode: LaunchMode.externalApplication);
          launched = true;
        }
      } catch (e) {
        debugPrint('Error checking if URL can be launched: $e');
        // canLaunchUrlString may throw on some platforms
      }

      // If the URL didn't launch using canLaunchUrlString check, try direct launch
      if (!launched) {
        try {
          await launchUrlString(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          throw 'Could not launch $url: $e';
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // Show error message to user
      if (context.mounted) {
        _showSnackBar('Could not open link: $url');
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

  // Method to check if the current user is the author of the post
  Future<bool> _isCurrentUserAuthor() async {
    try {
      final currentUser = await ApiService.getUserProfile();
      return currentUser['_id'] == widget.authorId;
    } catch (e) {
      debugPrint('Error checking if current user is author: $e');
      return false;
    }
  }

  void _showSharePopup(BuildContext context) async {
    final TextEditingController _searchController = TextEditingController();
    List<Map<String, dynamic>> _searchResults = [];
    bool _isSearching = false;
    Timer? _debounce;
    bool isAuthor = await _isCurrentUserAuthor();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF4F245A),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            void searchUsers(String query) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              
              _debounce = Timer(const Duration(milliseconds: 500), () async {
                if (query.isEmpty) {
                  setState(() {
                    _isSearching = false;
                    _searchResults = [];
                  });
                  return;
                }

                setState(() {
                  _isSearching = true;
                });

                try {
                  final searchResults = await ApiService.searchUsers(query);
                  final currentUserId = await ApiService.currentUserId;
                  // Filter out current user from API results
                  final filteredResults = searchResults.where((user) => user['_id'] != currentUserId).toList();
                  setState(() {
                    _searchResults = filteredResults;
                    _isSearching = false;
                  });
                } catch (e) {
                  debugPrint('Error searching users: $e');
                  setState(() {
                    _isSearching = false;
                  });
                }
              });
            }

            Widget buildSearchResults() {
              if (_isSearching) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                    ),
                  ),
                );
              }
              
              if (_searchResults.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                    child: Text(
                      'Search Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              await ApiService.sendMessage(
                                user['_id'],
                                'Check out this post: ${widget.title}',
                                postId: widget.id,
                              );
                              if (mounted) {
                                _showSnackBar('Post shared successfully');
                              }
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar('Failed to share post: $e');
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
                                      ApiService.resolveImageUrl(user['profileImage'] ?? ''),
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
            }

            return Container(
              padding: const EdgeInsets.all(16),
              // Make sure the bottom sheet is tall enough to accommodate the search
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF3D1B45),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15), 
                  topRight: Radius.circular(15)
                ),
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
                  
                  // User search field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF4F245A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: searchUsers,
                  ),
                  
                  // Search results
                  buildSearchResults(),
                  
                  if (_searchResults.isNotEmpty)
                    const Divider(color: Color(0xFFFDCC87), height: 32),
                  
                  // Recent users section - load only once
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
                            'Send To',
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
                                        postId: widget.id,
                                      );
                                      if (mounted) {
                                        _showSnackBar('Post shared successfully');
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        _showSnackBar('Failed to share post: $e');
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
                                              ApiService.resolveImageUrl(user['profilePicture'] ?? ''),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareOption(
                            icon: Icons.copy,
                            label: 'Copy Link',
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text: 'https://minaret.com/posts/${widget.id}',
                              ));
                              _showSnackBar('Link copied to clipboard');
                              Navigator.pop(context);
                            },
                          ),
                          if (!isAuthor) // Only show report option if not the author
                            _buildShareOption(
                              icon: Icons.flag,
                              label: 'Report',
                              onTap: () {
                                Navigator.pop(context);
                                _showReportDialog(context);
                              },
                            ),
                          GestureDetector(
                            onTap: () async {
                              final url = 'https://wa.me/?text=Check out this post: https://minaret.com/posts/${widget.id}';
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(url);
                              } else {
                                _showSnackBar('Could not launch WhatsApp');
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
                                _showSnackBar('Could not launch Telegram');
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
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
      final List<dynamic> uniqueUsers = [];
      final Set<String> addedUserIds = {};
      
      // First try to get recent conversations
      final conversations = await MessageService.getConversations();
      if (conversations.isNotEmpty) {
        // Get current user's ID
        final currentUserId = await ApiService.currentUserId;
        if (currentUserId == null) return [];

        for (final conv in conversations) {
          // Find the other participant
          final otherParticipant = conv.participants.firstWhere(
            (p) => p['_id'] != currentUserId,
            orElse: () => conv.participants.first,
          );
          
          final userId = otherParticipant['_id'];
          if (userId != null && !addedUserIds.contains(userId)) {
            addedUserIds.add(userId);
            uniqueUsers.add({
              'id': userId,
              'username': otherParticipant['username'],
              'firstName': otherParticipant['firstName'],
              'lastName': otherParticipant['lastName'],
              'profilePicture': otherParticipant['profileImage'],
            });
          }
        }
      }
      
      // Then add followed users that haven't been added yet
      try {
        final followedUsers = await ApiService.getFollowedUsers();
        for (final user in followedUsers) {
          final userId = user['_id'];
          if (userId != null && !addedUserIds.contains(userId)) {
            addedUserIds.add(userId);
            uniqueUsers.add({
              'id': userId,
              'username': user['username'],
              'firstName': user['firstName'],
              'lastName': user['lastName'],
              'profilePicture': user['profileImage'],
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading followed users: $e');
      }
      
      return uniqueUsers;
    } catch (e) {
      debugPrint('Error loading recent users: $e');
      return [];
    }
  }

  Widget _buildMediaGrid() {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    if (widget.media.length == 1) {
      return GestureDetector(
        onTap: () => _showGalleryView(0),
        child: AspectRatio(
          aspectRatio: 16/9,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              ApiService.resolveImageUrl(widget.media[0]['url']),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F245A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDCC87).withOpacity(0.5)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Color(0xFFFDCC87), size: 24),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Color(0xFFFDCC87),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
          onTap: () {
            _showGalleryView(index);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4F245A),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  ApiService.resolveImageUrl(widget.media[index]['url']),
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
                      padding: const EdgeInsets.all(4),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Color(0xFFFDCC87), size: 16),
                          SizedBox(height: 4),
                          Text(
                            'Image not found',
                            style: TextStyle(
                              color: Color(0xFFFDCC87),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (isLastItem)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
    // All images are already loaded since _loadingImages is set to true by default
    
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
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
                      ApiService.resolveImageUrl(widget.media[index]['url']),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F245A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDCC87).withOpacity(0.5)),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, color: Color(0xFFFDCC87), size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Color(0xFFFDCC87),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
                  backgroundImage: widget.profilePic.startsWith('http') || widget.profilePic.startsWith('/')
                      ? NetworkImage(ApiService.resolveImageUrl(widget.profilePic))
                      : AssetImage(widget.profilePic) as ImageProvider,
                  radius: 25,
                  onBackgroundImageError: (_, __) {
                    // This will be called if the profile image fails to load
                    debugPrint('Failed to load profile image: ${widget.profilePic}');
                  },
                  child: widget.profilePic.isEmpty ? const Icon(Icons.person, size: 25, color: Color(0xFFFDCC87)) : null,
                  backgroundColor: const Color(0xFF3D1B45),
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
              if (!widget.isRepost) ...[
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
                  ],
                ),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isUserBlocked) {
      return const SizedBox.shrink(); // Return an empty widget if the user is blocked
    }

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
          if (!widget.isRepost) ...[
            const SizedBox(height: 5),
            _buildLinks(),
            const SizedBox(height: 5),
            _buildMediaGrid(),
          ],
          if (widget.isRepost && widget.repostCaption != null && widget.repostCaption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.repostCaption!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
          if (widget.isRepost && widget.originalPost != null)
            GestureDetector(
              onTap: () {
                debugPrint('Original post data: ${widget.originalPost}');
                final originalPostId = widget.originalPost!['_id']?.toString() ?? '';
                debugPrint('Navigating to post detail with ID: $originalPostId');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: originalPostId,
                    ),
                  ),
                );
              },
              child: RepostContent(
                originalPost: widget.originalPost!,
                authorId: widget.authorId,
              ),
            ),
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
              if (!widget.isRepost) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.repeat, color: Colors.white),
                      onPressed: _showRepostDialog,
                    ),
                    Text(
                      _repostCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.comment,
                      color: _showComments ? const Color(0xFFFDCC87) : Colors.white,
                    ),
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
                    _commentCount.toString(),
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
                  _buildCommentsSection(),
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

  void _showRepostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF4F245A),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D1B45),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add a caption to your repost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _repostController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'What are your thoughts?',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFDCC87)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFDCC87)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFDCC87)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFFDCC87)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDCC87),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _handleRepost();
                      },
                      child: const Text(
                        'Repost',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRepost() async {
    try {
      await ApiService.repostPost(widget.id, _repostController.text);
      if (mounted) {
        // Refresh the post data to get updated repost count
        final updatedPost = await ApiService.getPost(widget.id);
        if (mounted) {
          setState(() {
            _repostCount = updatedPost['repostCount'] ?? 0;
          });
        }
        _showSnackBar('Post reposted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to repost post: $e');
      }
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
        // Update comment count immediately
        _commentCount++;
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
          
          // Convert all fields to proper types
          final typedReply = {
            '_id': newReply['_id']?.toString(),
            'text': newReply['text']?.toString(),
            'createdAt': newReply['createdAt']?.toString(),
            'author': {
              '_id': newReply['author']['_id']?.toString(),
              'username': newReply['author']['username']?.toString(),
              'firstName': newReply['author']['firstName']?.toString(),
              'lastName': newReply['author']['lastName']?.toString(),
              'profileImage': newReply['author']['profileImage']?.toString(),
            }
          };

          // Cast to List<Map<String, dynamic>> and insert the new reply
          final replies = List<Map<String, dynamic>>.from(_comments[commentIndex]['replies']);
          replies.insert(0, typedReply);
          _comments[commentIndex]['replies'] = replies;
        }
        _replyController.clear();
        _replyingToCommentId = null;
      });
    } catch (e) {
      debugPrint('Error adding reply: $e');
      if (mounted) {
        _showSnackBar('Failed to add reply');
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

  Widget _buildCommentsSection() {
    if (_loadingComments) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
        ),
      );
    }

    final visibleComments = _comments.take(_visibleCommentsCount).toList();
    final hasMoreComments = _comments.length > _visibleCommentsCount;

    return Column(
      children: [
        ...visibleComments.map((comment) {
          final replies = List<Map<String, dynamic>>.from(comment['replies'] ?? []);
          final visibleRepliesCount = _visibleRepliesCount[comment['_id']] ?? _repliesPerPage;
          final visibleReplies = replies.take(visibleRepliesCount);
          final hasMoreReplies = replies.length > visibleRepliesCount;
          final isRepliesExpanded = _showReplies[comment['_id']] ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Comment(
                authorName: '${comment['author']['firstName']} ${comment['author']['lastName']}',
                authorUsername: comment['author']['username'],
                authorProfilePic: ApiService.resolveImageUrl(comment['author']['profileImage']),
                text: comment['text'],
                createdAt: comment['createdAt'],
                replies: isRepliesExpanded ? visibleReplies.toList() : [],
                onReply: () {
                  setState(() {
                    _replyingToCommentId = comment['_id'];
                    _showReplies[comment['_id']] = true;
                  });
                },
              ),
              if (replies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isRepliesExpanded)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showReplies[comment['_id']] = true;
                            });
                          },
                          child: Text(
                            'See ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                            style: const TextStyle(
                              color: Color(0xFFFDCC87),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (isRepliesExpanded) ...[
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showReplies[comment['_id']] = false;
                                });
                              },
                              child: const Text(
                                'Collapse replies',
                                style: TextStyle(
                                  color: Color(0xFFFDCC87),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (replies.length > _repliesPerPage && visibleRepliesCount == _repliesPerPage)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleRepliesCount[comment['_id']] = replies.length;
                                  });
                                },
                                child: Text(
                                  'See all ${replies.length} replies',
                                  style: const TextStyle(
                                    color: Color(0xFFFDCC87),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (hasMoreReplies)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _visibleRepliesCount[comment['_id']] = visibleRepliesCount + _repliesPerPage;
                              });
                            },
                            child: const Text(
                              'See more replies',
                              style: TextStyle(
                                color: Color(0xFFFDCC87),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        }).toList(),
        if (hasMoreComments)
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _visibleCommentsCount += _commentsPerPage;
                });
              },
              child: Text(
                'See ${_commentsPerPage} more comments',
                style: const TextStyle(
                  color: Color(0xFFFDCC87),
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Safe method to show a snackbar
  void _showSnackBar(String message) {
    if (!mounted) {
      debugPrint('Cannot show snackbar, widget not mounted: $message');
      return;
    }
    
    // Delay showing the snackbar to ensure it's shown on a valid context
    Future.microtask(() {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  // Method to show the report dialog
  void _showReportDialog(BuildContext context) {
    // Store the BuildContext at the class level to ensure it remains valid
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    // Show the check dialog first without any async operations
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Check if user is the author in a separate function after dialog is shown
        _checkIfUserCanReport(dialogContext);
        
        return Dialog(
          backgroundColor: const Color(0xFF3D1B45),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                ),
                SizedBox(height: 16),
                Text(
                  'Please Wait...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Check if user can report, and then show appropriate dialog
  void _checkIfUserCanReport(BuildContext dialogContext) {
    ApiService.getUserProfile().then((currentUser) {
      final currentUserId = currentUser['_id'];
      
      // Pop the loading dialog first
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // If user is the author, show error message
      if (widget.authorId == currentUserId) {
        if (mounted) {
          _showSnackBar('You cannot report your own post');
        }
        return;
      }
      
      // If user can report, show the report dialog
      if (mounted && dialogContext.mounted) {
        _showFullReportDialogSync(dialogContext);
      }
    }).catchError((error) {
      // Pop the loading dialog on error
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      if (mounted) {
        _showSnackBar('Error checking user status: ${error.toString()}');
      }
    });
  }

  // Show the full report dialog synchronously (not using async/await)
  void _showFullReportDialogSync(BuildContext contextToUse) {
    final List<String> reportReasons = [
      'Inappropriate Content',
      'Misinformation',
      'Hate Speech',
      'Spam',
      'Harassment',
      'Violence',
      'Copyright Violation',
      'Other'
    ];
    
    String? selectedReason;
    final TextEditingController _additionalContextController = TextEditingController();
    bool _isSubmitting = false;
    
    showDialog(
      context: contextToUse,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF3D1B45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Why are you reporting this post?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(builderContext).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: reportReasons.map((reason) {
                              return RadioListTile<String>(
                                title: Text(
                                  reason,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                value: reason,
                                groupValue: selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    selectedReason = value;
                                  });
                                },
                                activeColor: const Color(0xFFFDCC87),
                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return const Color(0xFFFDCC87);
                                    }
                                    return Colors.white;
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Additional Context (Optional)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _additionalContextController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Provide more details about this report...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF4F245A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDCC87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: selectedReason == null || _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    
                                    // Submit the report
                                    ApiService.reportPost(
                                      postId: widget.id,
                                      reason: selectedReason!,
                                      additionalContext: _additionalContextController.text.trim()
                                    ).then((_) {
                                      // Success! Close dialog and show action prompt
                                      Navigator.pop(dialogContext);
                                      
                                      // Show success message
                                      if (mounted) {
                                        _showSnackBar('Thank you for your report. We will review it shortly.');
                                      
                                        // Show action prompt with the context directly from widget tree
                                        if (mounted) {
                                          // Instead of using post-frame callback, directly call with a delay
                                          // This allows the navigator transition to complete
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            if (mounted) {
                                              _showActionPromptDirectly();
                                            }
                                          });
                                        }
                                      }
                                    }).catchError((e) {
                                      if (mounted && dialogContext.mounted) {
                                        // Close dialog on error
                                        Navigator.pop(dialogContext);
                                        _showSnackBar('Error reporting post: ${e.toString()}');
                                      }
                                    });
                                  },
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Report Post',
                                    style: TextStyle(color: Colors.black),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // A direct implementation of the action prompt that doesn't use the "safer" version
  void _showActionPromptDirectly() {
    // Use a new build context from the current widget's context
    // This ensures we're using a valid, current context from the widget tree
    if (!mounted) return;
    
    // Get current following and blocking status
    Future.wait([
      ApiService.isFollowing(widget.authorId),
      ApiService.isBlocked(widget.authorId)
    ]).then((results) {
      if (!mounted) return;
      
      final isFollowing = results[0];
      final isBlocked = results[1];
      
      // Now show the dialog with the fresh, valid context
      showDialog(
        context: context, // Using the widget's current context
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: const Color(0xFF3D1B45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thanks for reporting',
                    style: TextStyle(
                      color: Color(0xFFFDCC87),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What would you like to do about this user?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFDCC87),
                        ),
                        child: CircleAvatar(
                          backgroundImage: widget.profilePic.isNotEmpty && 
                                         (widget.profilePic.startsWith('http') || 
                                          widget.profilePic.startsWith('/'))
                            ? NetworkImage(ApiService.resolveImageUrl(widget.profilePic))
                            : const AssetImage('assets/default_profile.png') as ImageProvider,
                          radius: 20,
                          onBackgroundImageError: (_, __) {
                            // Image failed to load
                            debugPrint('Failed to load profile image in action dialog');
                          },
                          backgroundColor: const Color(0xFF3D1B45),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${widget.username}',
                              style: const TextStyle(
                                color: Color(0xFFFDCC87),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      if (isFollowing)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () {
                            ApiService.unfollowUser(widget.authorId).then((_) {
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _showSnackBar('User unfollowed successfully');
                              }
                            }).catchError((error) {
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _showSnackBar('Failed to unfollow user: $error');
                              }
                            });
                          },
                          child: const Text(
                            'Unfollow',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (isFollowing)
                        const SizedBox(height: 12),
                      
                      if (!isBlocked)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () {
                            ApiService.blockUser(widget.authorId).then((_) {
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _showSnackBar('User blocked successfully');
                                
                                // Notify parent if a user was blocked
                                if (widget.onPostBlocked != null) {
                                  widget.onPostBlocked!(widget.id);
                                }
                              }
                            }).catchError((error) {
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _showSnackBar('Failed to block user: $error');
                              }
                            });
                          },
                          child: const Text(
                            'Block User',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (!isBlocked)
                        const SizedBox(height: 12),
                      
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Color(0xFFFDCC87)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Keep Following',
                          style: TextStyle(color: Color(0xFFFDCC87)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ).catchError((e) {
        debugPrint('Error showing action dialog: $e');
        if (mounted) {
          _showSnackBar('Error showing options. Please try again.');
        }
      });
    }).catchError((e) {
      debugPrint('Error checking user status: $e');
      if (mounted) {
        _showSnackBar('Error checking user status. Please try again.');
      }
    });
  }

  Future<void> _checkIfUserBlocked() async {
    try {
      final isBlocked = await ApiService.isBlocked(widget.authorId);
      if (mounted) {
        setState(() {
          _isUserBlocked = isBlocked;
        });
        
        // Notify parent if post is from blocked user
        if (isBlocked && widget.onPostBlocked != null) {
          widget.onPostBlocked!(widget.id);
        }
      }
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
    }
  }
}