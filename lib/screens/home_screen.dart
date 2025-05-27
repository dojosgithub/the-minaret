import 'package:flutter/material.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';
import '../utils/post_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<String> _followedUsers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  String? _error;
  int _page = 1;
  final int _postsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFollowedUsers();
    _scrollController.addListener(_scrollListener);
    PostType.typeNotifier.addListener(_handleTypeChange);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    PostType.typeNotifier.removeListener(_handleTypeChange);
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  void _handleTypeChange() {
    setState(() {
      _posts = [];
      _page = 1;
      _hasMorePosts = true;
      _isLoading = true;
    });
    _loadFollowedUsers();
  }

  Future<void> _loadFollowedUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final followedUsers = await ApiService.getFollowedUsers();
      
      if (mounted) {
        setState(() {
          _followedUsers = followedUsers.map((user) => user['_id'].toString()).toList();
          _isLoading = false;
        });
        
        if (_followedUsers.isNotEmpty) {
          _loadPosts();
        } else {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading followed users: $e');
    }
  }

  Future<void> _loadPosts() async {
    if (_followedUsers.isEmpty) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final posts = await ApiService.getPosts(
        type: PostType.selectedType,
        page: _page,
        limit: _postsPerPage
      );
      
      // Filter posts to only show those from followed users
      final filteredPosts = posts.where((post) => 
        _followedUsers.contains(post['author']['_id'].toString())
      ).toList();
      
      // Check if we have fewer posts than requested, meaning no more to load
      if (posts.length < _postsPerPage) {
        _hasMorePosts = false;
      }
      
      // Process posts in parallel for better performance
      await Future.wait(
        filteredPosts.map((post) async {
          try {
            final status = await ApiService.getPostVoteStatus(post['_id']);
            post['isUpvoted'] = status['isUpvoted'] ?? false;
            post['isDownvoted'] = status['isDownvoted'] ?? false;
          } catch (e) {
            debugPrint('Error getting vote status for post ${post['_id']}: $e');
            post['isUpvoted'] = false;
            post['isDownvoted'] = false;
          }
        })
      );
      
      if (mounted) {
        setState(() {
          _posts = filteredPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading posts: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts || _followedUsers.isEmpty) return;
    
    try {
      setState(() {
        _isLoadingMore = true;
      });
      
      final nextPage = _page + 1;
      final morePosts = await ApiService.getPosts(
        type: PostType.selectedType,
        page: nextPage,
        limit: _postsPerPage
      );
      
      // Filter posts to only show those from followed users
      final filteredPosts = morePosts.where((post) => 
        _followedUsers.contains(post['author']['_id'].toString())
      ).toList();
      
      // Check if we have fewer posts than requested or if filtered list is empty
      if (morePosts.length < _postsPerPage || filteredPosts.isEmpty) {
        _hasMorePosts = false;
      }
      
      // Filter out any duplicate posts based on post ID
      final existingPostIds = _posts.map((p) => p['_id'].toString()).toSet();
      final uniqueNewPosts = filteredPosts.where((post) => 
        !existingPostIds.contains(post['_id'].toString())
      ).toList();
      
      // If no new unique posts, mark as no more posts
      if (uniqueNewPosts.isEmpty) {
        _hasMorePosts = false;
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }
      
      // Process posts in parallel for better performance
      await Future.wait(
        uniqueNewPosts.map((post) async {
          try {
            final status = await ApiService.getPostVoteStatus(post['_id']);
            post['isUpvoted'] = status['isUpvoted'] ?? false;
            post['isDownvoted'] = status['isDownvoted'] ?? false;
          } catch (e) {
            debugPrint('Error getting vote status for post ${post['_id']}: $e');
            post['isUpvoted'] = false;
            post['isDownvoted'] = false;
          }
        })
      );
      
      if (mounted) {
        setState(() {
          _posts.addAll(uniqueNewPosts);
          _page = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      debugPrint('Error loading more posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts = [];
      _page = 1;
      _hasMorePosts = true;
    });
    await _loadFollowedUsers();
  }

  Future<void> _handleUpvote(String postId) async {
    try {
      await ApiService.upvotePost(postId);
      setState(() {
        for (var post in _posts) {
          if (post['_id'] == postId) {
            post['isUpvoted'] = !(post['isUpvoted'] ?? false);
            if (post['isUpvoted'] == true) {
              post['isDownvoted'] = false;
            }
          }
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
        for (var post in _posts) {
          if (post['_id'] == postId) {
            post['isDownvoted'] = !(post['isDownvoted'] ?? false);
            if (post['isDownvoted'] == true) {
              post['isUpvoted'] = false;
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error downvoting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: PreferredSize(
          preferredSize: Size.zero,
          child: Container(), // Empty container with zero height
        ),
        body: RefreshIndicator(
          onRefresh: _refreshPosts,
          color: const Color(0xFFFDCC87),
          child: _isLoading && _posts.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                  ),
                )
              : _error != null && _posts.isEmpty
                  ? ConnectionErrorWidget(
                      onRetry: _refreshPosts,
                    )
                  : _posts.isEmpty
                      ? const SingleChildScrollView(
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
                        )
                      : ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            ...(_posts.map((post) => Post(
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
                                  repostCount: post['repostCount'] ?? 0,
                                  commentCount: (post['comments'] as List?)?.length ?? 0,
                                  createdAt: post['createdAt'] ?? DateTime.now().toIso8601String(),
                                  authorId: post['author']['_id'] ?? '',
                                  isUpvoted: post['isUpvoted'] ?? false,
                                  isDownvoted: post['isDownvoted'] ?? false,
                                  isRepost: post['isRepost'] ?? false,
                                  repostCaption: post['repostCaption'],
                                  originalPost: post['originalPost'],
                                  onUpvote: _handleUpvote,
                                  onDownvote: _handleDownvote,
                                ))).toList(),
                            if (_isLoadingMore)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                                  ),
                                ),
                              ),
                            // Add bottom padding to prevent content from being hidden under the nav bar
                            const SizedBox(height: 80),
                          ],
                        ),
        ),
      ),
    );
  }
}
