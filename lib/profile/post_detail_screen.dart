import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../widgets/post.dart';
import '../services/api_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      debugPrint('Loading post with ID: ${widget.postId}');
      if (widget.postId.isEmpty) {
        throw Exception('Invalid post ID');
      }
      
      final post = await ApiService.getPost(widget.postId);
      debugPrint('Post loaded successfully: ${post['_id']}');
      
      // Check vote status
      final status = await ApiService.getPostVoteStatus(widget.postId);
      post['isUpvoted'] = status['isUpvoted'] ?? false;
      post['isDownvoted'] = status['isDownvoted'] ?? false;
      
      setState(() {
        _post = post;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading post: $e');
      setState(() {
        _error = 'Failed to load post. Please try again.';
        _isLoading = false;
        _post = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const TopBarWithoutMenu(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : _post == null
                  ? const Center(
                      child: Text(
                        'Post not found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Post(
                        id: _post!['_id'],
                        name: _post!['author']['firstName'] != null && _post!['author']['lastName'] != null
                            ? '${_post!['author']['firstName']} ${_post!['author']['lastName']}'
                            : _post!['author']['username'] ?? 'Unknown User',
                        username: _post!['author']['username'] ?? 'unknown',
                        profilePic: _post!['author']['profileImage'] ?? 'assets/default_profile.png',
                        title: _post!['title'] ?? '',
                        text: _post!['body'] ?? '',
                        media: List<Map<String, dynamic>>.from(_post!['media'] ?? []),
                        links: List<Map<String, dynamic>>.from(_post!['links'] ?? []),
                        upvoteCount: (_post!['upvotes'] as List?)?.length ?? 0,
                        downvoteCount: (_post!['downvotes'] as List?)?.length ?? 0,
                        repostCount: (_post!['reposts'] as List?)?.length ?? 0,
                        commentCount: (_post!['comments'] as List?)?.length ?? 0,
                        createdAt: _post!['createdAt'] ?? DateTime.now().toIso8601String(),
                        authorId: _post!['author']['_id'] ?? '',
                        isUpvoted: _post!['isUpvoted'] ?? false,
                        isDownvoted: _post!['isDownvoted'] ?? false,
                        isRepost: _post!['isRepost'] ?? false,
                        repostCaption: _post!['repostCaption'],
                        originalPost: _post!['originalPost'],
                        onUpvote: (postId) async {
                          try {
                            await ApiService.upvotePost(postId);
                            _loadPost(); // Refresh post data
                          } catch (e) {
                            debugPrint('Error upvoting post: $e');
                          }
                        },
                        onDownvote: (postId) async {
                          try {
                            await ApiService.downvotePost(postId);
                            _loadPost(); // Refresh post data
                          } catch (e) {
                            debugPrint('Error downvoting post: $e');
                          }
                        },
                      ),
                    ),
    );
  }
} 