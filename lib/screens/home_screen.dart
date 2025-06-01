import 'package:flutter/material.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';
import '../utils/post_type.dart';
import '../utils/content_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  List<String> _followedUsers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  String? _error;
  int _page = 1;
  final int _postsPerPage = 10;
  final ScrollController _scrollController = ScrollController();
  ContentFilterLevel _contentFilterLevel = ContentFilterLevel.moderate; // Default filter level

  @override
  void initState() {
    super.initState();
    _loadContentFilterPreference();
    _loadFollowedUsers();
    _scrollController.addListener(_scrollListener);
    PostType.typeNotifier.addListener(_handleTypeChange);
    
    // Remove automatic login check that might cause logout loop
    // We'll handle auth errors in the API responses instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh content filter preference when navigating back to this screen
    if (mounted) {
      _loadContentFilterPreference();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    PostType.typeNotifier.removeListener(_handleTypeChange);
    super.dispose();
  }

  Future<void> _loadContentFilterPreference() async {
    try {
      // In a real implementation, this would come from a user preferences service
      // or user profile data
      final userData = await ApiService.getUserProfile();
      final filterLevelString = userData['contentFilterLevel'] ?? 'moderate';
      
      if (mounted) {
        setState(() {
          _contentFilterLevel = _stringToFilterLevel(filterLevelString);
        });
      }
    } catch (e) {
      debugPrint('Error loading content filter preference: $e');
      // Default to moderate if there's an error
      if (mounted) {
        setState(() {
          _contentFilterLevel = ContentFilterLevel.moderate;
        });
      }
    }
  }

  ContentFilterLevel _stringToFilterLevel(String level) {
    switch (level.toLowerCase()) {
      case 'strict':
        return ContentFilterLevel.strict;
      case 'moderate':
        return ContentFilterLevel.moderate;
      case 'minimal':
        return ContentFilterLevel.minimal;
      case 'none':
        return ContentFilterLevel.none;
      default:
        return ContentFilterLevel.moderate;
    }
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
      _filteredPosts = [];
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
            _filteredPosts = [];
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
        
        // Only redirect if it's an authentication error
        if (e.toString().contains('No token') || 
            e.toString().contains('Token is not valid') || 
            e.toString().contains('Please log in again')) {
          // Use a short delay to prevent immediate navigation during build
          Future.delayed(Duration.zero, () {
            ApiService.checkLoginAndRedirect(context);
          });
        }
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
          // Apply content filtering
          _applyContentFiltering();
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

  void _applyContentFiltering() {
    // This is a simplified implementation of content filtering
    // In a real app, you'd use more sophisticated methods or server-side filtering
    
    _filteredPosts = _posts.where((post) {
      // Check post title and body for inappropriate content
      final String title = post['title'] ?? '';
      final String body = post['body'] ?? '';
      final String combinedText = '$title $body'.toLowerCase();
      
      // Get filtered words based on filter level
      final List<String> filteredWords = _getFilteredWords();
      
      // For strict filtering, check for any filtered words
      if (_contentFilterLevel == ContentFilterLevel.strict) {
        return !filteredWords.any((word) => combinedText.contains(word));
      }
      
      // For moderate filtering, check for more severe terms
      else if (_contentFilterLevel == ContentFilterLevel.moderate) {
        final moderateFilterWords = filteredWords.where((word) => 
          _getSeverityLevel(word) >= 2
        ).toList();
        return !moderateFilterWords.any((word) => combinedText.contains(word));
      }
      
      // For minimal filtering, only filter the most severe content
      else if (_contentFilterLevel == ContentFilterLevel.minimal) {
        final minimalFilterWords = filteredWords.where((word) => 
          _getSeverityLevel(word) >= 3
        ).toList();
        return !minimalFilterWords.any((word) => combinedText.contains(word));
      }
      
      // If none (no filtering), return all posts
      return true;
    }).toList();
  }

  List<String> _getFilteredWords() {
    // This would ideally come from a server or be updated regularly
    return [
      'hate', 'kill', 'violence', 'racist', 'terrorism', 'bomb', 
      'explicit', 'obscene', 'porn', 'sex', 'nude', 'nazi',
      'slur', 'assault', 'attack', 'threat', 'harmful', 'illegal',
    ];
  }
  
  // Simple severity rating for filtered words (1-3, with 3 being most severe)
  int _getSeverityLevel(String word) {
    const Map<String, int> severityMap = {
      'terrorism': 3, 'bomb': 3, 'kill': 3, 'porn': 3, 'nazi': 3,
      'violence': 2, 'racist': 2, 'explicit': 2, 'obscene': 2, 'sex': 2,
      'hate': 1, 'nude': 1, 'slur': 2, 'assault': 2, 'attack': 2,
      'threat': 2, 'harmful': 1, 'illegal': 2,
    };
    
    return severityMap[word] ?? 1;
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
          // Apply content filtering to all posts
          _applyContentFiltering();
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
    await _loadContentFilterPreference();
    setState(() {
      _posts = [];
      _filteredPosts = [];
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
        // Make sure to update filtered posts as well
        _applyContentFiltering();
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
        // Make sure to update filtered posts as well
        _applyContentFiltering();
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
                            ...(_filteredPosts.map((post) => Post(
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
