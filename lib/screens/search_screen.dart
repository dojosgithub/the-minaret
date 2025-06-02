import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import 'profile_screen.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final Function(int) onIndexChanged;

  const SearchScreen({
    super.key,
    required this.onIndexChanged,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _users = [];
  String? _selectedSortBy;
  String? _selectedDatePosted;
  String? _selectedPostedBy;
  bool _hasError = false;
  String? _error;
  List<String> _recentSearches = [];
  int _selectedTab = 0; // 0 for posts, 1 for users
  final Map<String, bool> _upvotedPosts = {};
  final Map<String, bool> _downvotedPosts = {};

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadRecentSearches() async {
    try {
      final searches = await ApiService.getRecentSearches();
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _posts = [];
          _users = [];
        });
      }
    });
  }

  Future<void> _performSearch({bool addToRecent = false}) async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _posts = [];
        _users = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _error = null;
      _posts = [];
      _users = [];
    });

    try {
      final results = await ApiService.searchPosts(
        query: _searchController.text,
        sortBy: _selectedSortBy,
        datePosted: _selectedDatePosted,
        postedBy: _selectedPostedBy,
      );

      if (addToRecent) {
        await ApiService.addRecentSearch(_searchController.text);
        await _loadRecentSearches();
      }

      // Check vote status for each post
      final posts = results['posts'] ?? [];
      for (var post in posts) {
        final status = await ApiService.getPostVoteStatus(post['_id']);
        post['isUpvoted'] = status['isUpvoted'] ?? false;
        post['isDownvoted'] = status['isDownvoted'] ?? false;
      }

      // Check follow status for each user
      final users = results['users'] ?? [];
      for (var user in users) {
        user['isFollowing'] = await ApiService.isFollowing(user['_id']);
      }

      setState(() {
        _posts = posts;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _error = 'Failed to perform search';
      });
    }
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabButton(0, 'Posts'),
          _buildTabButton(1, 'Users'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _selectedTab == index ? const Color(0xFFFDCC87) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: _selectedTab == index ? const Color(0xFFFDCC87) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_selectedTab == 0) {
      if (_posts.isEmpty) {
        return const Center(
          child: Text(
            'No posts found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: _posts.map((post) => Post(
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
            isUpvoted: _upvotedPosts[post['_id']] ?? false,
            isDownvoted: _downvotedPosts[post['_id']] ?? false,
            isRepost: post['isRepost'] ?? false,
            repostCaption: post['repostCaption'],
            originalPost: post['originalPost'],
            onUpvote: _handleUpvote,
            onDownvote: _handleDownvote,
          )).toList(),
        ),
      );
    } else {
      if (_users.isEmpty) {
        return const Center(
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }
      return ListView(
        children: _users.map((user) {
          final isFollowing = user['isFollowing'] ?? false;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user['profileImage'] != null && user['profileImage'].isNotEmpty
                  ? NetworkImage(ApiService.resolveImageUrl(user['profileImage']))
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            title: Text(
              user['firstName'] != null && user['lastName'] != null
                  ? '${user['firstName']} ${user['lastName']}'
                  : user['username'] ?? 'Unknown User',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '@${user['username'] ?? ''}',
              style: const TextStyle(color: const Color(0xFFFDCC87)),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey : const Color(0xFFFDCC87),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                try {
                  if (isFollowing) {
                    await ApiService.unfollowUser(user['_id']);
                  } else {
                    await ApiService.followUser(user['_id']);
                  }
                  setState(() {
                    user['isFollowing'] = !isFollowing;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user')),
                  );
                }
              },
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: user['_id']),
                ),
              );
            },
          );
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4F245A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
            onPressed: () {
              // Dismiss keyboard before navigation to avoid layout issues
              FocusScope.of(context).unfocus();
              // Short delay to ensure keyboard is dismissed before navigation
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) {
                  widget.onIndexChanged(0);
                }
              });
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search posts and users...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  // Remove the search button since search is now automatic
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus(); // Dismiss keyboard
                        },
                      )
                    : const Icon(Icons.search, color: Colors.grey),
                ),
                // Add onSubmitted to handle Enter key press
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _performSearch(addToRecent: true);
                  }
                },
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort, color: Color(0xFFFDCC87)),
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF3D1B45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExpansionTile(
                                context,
                                'Sort by',
                                ['Date', 'Most Relevant', 'Recent'],
                                _selectedSortBy,
                                (value) => setState(() => _selectedSortBy = value),
                              ),
                              _buildExpansionTile(
                                context,
                                'Date Posted',
                                ['Last 24 Hours', 'This Week', 'This Month', '2024'],
                                _selectedDatePosted,
                                (value) => setState(() => _selectedDatePosted = value),
                              ),
                              _buildExpansionTile(
                                context,
                                'Posted By',
                                ['Me', 'Followings', 'Anyone'],
                                _selectedPostedBy,
                                (value) => setState(() => _selectedPostedBy = value),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _performSearch(addToRecent: true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFDCC87),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Show Results', style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFDCC87)))
            : _hasError && _error != null && _error!.contains('Failed to connect to server')
                ? ConnectionErrorWidget(
                    onRetry: () {
                      if (_searchController.text.isNotEmpty) {
                        _performSearch();
                      }
                    },
                  )
                : _posts.isNotEmpty || _users.isNotEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          _buildTabs(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _buildSearchResults(),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 20.0),
                                  child: Text(
                                    "No results found",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            
                            const Text(
                              "Recent Searches",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _recentSearches.length,
                                itemBuilder: (context, index) {
                                  final search = _recentSearches[index];
                                  return ListTile(
                                    leading: const Icon(Icons.history, color: Color(0xFFFDCC87)),
                                    title: Text(
                                      search,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, color: Color(0xFFFDCC87)),
                                      onPressed: () async {
                                        await ApiService.deleteRecentSearch(search);
                                        await _loadRecentSearches();
                                      },
                                    ),
                                    onTap: () {
                                      _searchController.text = search;
                                      _performSearch(addToRecent: true);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildExpansionTile(
    BuildContext context,
    String title,
    List<String> options,
    String? selectedValue,
    ValueChanged<String> onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: ExpansionTile(
      title: Text(title, style: const TextStyle(color: Color(0xFFFDCC87))),
      children: options
          .map(
              (option) => Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: selectedValue == option ? const Color(0xFFFDCC87) : Colors.white,
                    ),
                  ),
                  onTap: () {
                    onSelect(option);
                  },
                ),
            ),
          )
          .toList(),
      ),
    );
  }

  void _handleUpvote(String postId) async {
    try {
      await ApiService.upvotePost(postId);
      setState(() {
        _upvotedPosts[postId] = true;
        _downvotedPosts.remove(postId);
      });
    } catch (e) {
      debugPrint('Error upvoting post: $e');
    }
  }

  void _handleDownvote(String postId) async {
    try {
      await ApiService.downvotePost(postId);
      setState(() {
        _downvotedPosts[postId] = true;
        _upvotedPosts.remove(postId);
      });
    } catch (e) {
      debugPrint('Error downvoting post: $e');
    }
  }
}