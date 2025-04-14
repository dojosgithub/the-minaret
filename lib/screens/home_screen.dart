import 'package:flutter/material.dart';
import '../widgets/post.dart';
import '../widgets/screen_wrapper.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';
import '../utils/post_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _postsFuture;
  final Map<String, bool> _upvotedPosts = {};
  final Map<String, bool> _downvotedPosts = {};

  @override
  void initState() {
    super.initState();
    _initializePosts();
    // Listen for type changes
    PostType.typeNotifier.addListener(_handleTypeChange);
  }

  @override
  void dispose() {
    PostType.typeNotifier.removeListener(_handleTypeChange);
    super.dispose();
  }

  void _handleTypeChange() {
    _initializePosts();
  }

  Future<void> _initializePosts() async {
    setState(() {
      _postsFuture = ApiService.getPosts(type: PostType.selectedType).then((posts) async {
        // Check vote status for each post
        for (var post in posts) {
          final status = await ApiService.getPostVoteStatus(post['_id']);
          post['isUpvoted'] = status['isUpvoted'] ?? false;
          post['isDownvoted'] = status['isDownvoted'] ?? false;
        }
        return posts;
      }).catchError((error) {
        debugPrint('Error fetching posts: $error');
        throw error;
      });
    });
  }

  void _refreshPosts() {
    _initializePosts();
  }

  Future<void> _handleUpvote(String postId) async {
    try {
      await ApiService.upvotePost(postId);
      setState(() {
        _upvotedPosts[postId] = !(_upvotedPosts[postId] ?? false);
        if (_upvotedPosts[postId] == true) {
          _downvotedPosts[postId] = false;
        }
      });
    } catch (e) {
      debugPrint('Error upvoting post: $e');
    }
  }

  Future<void> _handleDownvote(String postId) async {
    try {
      await ApiService.downvotePost(postId);
      setState(() {
        _downvotedPosts[postId] = !(_downvotedPosts[postId] ?? false);
        if (_downvotedPosts[postId] == true) {
          _upvotedPosts[postId] = false;
        }
      });
    } catch (e) {
      debugPrint('Error downvoting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshPosts();
        },
        color: const Color(0xFFFDCC87),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                ),
              );
            }

            if (snapshot.hasError) {
              return ConnectionErrorWidget(
                onRetry: _refreshPosts,
              );
            }

            final posts = snapshot.data ?? [];
            
            if (posts.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No posts available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: posts.map((post) => Post(
                  id: post['_id'],
                  name: post['author']['firstName'] != null && post['author']['lastName'] != null
                      ? '${post['author']['firstName']} ${post['author']['lastName']}'
                      : post['author']['username'] ?? 'Unknown User',
                  username: post['author']['username'] ?? 'unknown',
                  profilePic: post['author']['profileImage'] ?? 'assets/default_profile.png',
                  title: post['title'] ?? '',
                  text: post['body'] ?? '',
                  media: List<Map<String, dynamic>>.from(post['media'] ?? []),
                  links: List<Map<String, dynamic>>.from(post['links'] ?? []),
                  upvoteCount: (post['upvotes'] as List?)?.length ?? 0,
                  downvoteCount: (post['downvotes'] as List?)?.length ?? 0,
                  repostCount: 0,
                  commentCount: (post['comments'] as List?)?.length ?? 0,
                  createdAt: post['createdAt'] ?? DateTime.now().toIso8601String(),
                  authorId: post['author']['_id'] ?? '',
                  isUpvoted: _upvotedPosts[post['_id']] ?? false,
                  isDownvoted: _downvotedPosts[post['_id']] ?? false,
                  onUpvote: _handleUpvote,
                  onDownvote: _handleDownvote,
                )).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
