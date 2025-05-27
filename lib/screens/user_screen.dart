import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';
import '../screens/followers_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  int selectedTab = 0;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPosts = [];
  List<Map<String, dynamic>> savedPosts = [];
  bool isLoadingProfile = true;
  bool isLoadingPosts = false;
  bool isLoadingSaved = false;
  bool isLoadingMorePosts = false;
  bool isLoadingMoreSaved = false;
  bool hasMorePosts = true;
  bool hasMoreSaved = true;
  String? error;
  int postsPage = 1;
  int savedPage = 1;
  final int postsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (selectedTab == 0 && !isLoadingMorePosts && hasMorePosts) {
        _loadMorePosts();
      } else if (selectedTab == 1 && !isLoadingMoreSaved && hasMoreSaved) {
        _loadMoreSavedPosts();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will refresh data when coming back from Followers screen
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoadingProfile = true;
      error = null;
    });

    try {
      // Verify token first
      final isValid = await ApiService.verifyToken();
      if (!isValid) {
        throw Exception('Please log in again');
      }

      // Load user profile
      final data = await ApiService.getUserProfile();
      debugPrint('User data received: $data');

      if (mounted) {
        setState(() {
          userData = data;
          isLoadingProfile = false;
        });
        
        // Load initial posts only if the Posts tab is selected
        if (selectedTab == 0) {
          _loadUserPosts();
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadUserPosts() async {
    if (isLoadingPosts) return;
    
    setState(() {
      isLoadingPosts = true;
    });

    try {
      // Load posts with pagination
      final posts = await ApiService.getUserPosts(page: postsPage, limit: postsPerPage);
      debugPrint('User posts received: ${posts.length}');
      
      // Check if we have fewer posts than requested, meaning no more to load
      if (posts.length < postsPerPage) {
        hasMorePosts = false;
      }

      // Process posts in parallel for better performance
      await Future.wait(
        posts.map((post) async {
          try {
            final status = await ApiService.getPostVoteStatus(post['_id']);
            final isSaved = await ApiService.isPostSaved(post['_id']);
            post['isUpvoted'] = status['isUpvoted'] ?? false;
            post['isDownvoted'] = status['isDownvoted'] ?? false;
            post['isSaved'] = isSaved;

            // If this is a repost, fetch the original post data
            if (post['isRepost'] == true && post['originalPost'] is String) {
              try {
                final originalPost = await ApiService.getPost(post['originalPost']);
                post['originalPost'] = originalPost;
              } catch (e) {
                debugPrint('Error fetching original post: $e');
                post['originalPost'] = null;
              }
            }
          } catch (e) {
            debugPrint('Error processing post: $e');
          }
        })
      );
      
      if (mounted) {
        setState(() {
          userPosts = posts;
          isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user posts: $e');
      if (mounted) {
        setState(() {
          isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (isLoadingMorePosts || !hasMorePosts) return;
    
    setState(() {
      isLoadingMorePosts = true;
    });

    try {
      final nextPage = postsPage + 1;
      final morePosts = await ApiService.getUserPosts(page: nextPage, limit: postsPerPage);
      
      // Check if we have fewer posts than requested, meaning no more to load
      if (morePosts.length < postsPerPage) {
        hasMorePosts = false;
      }

      // Process posts in parallel for better performance
      await Future.wait(
        morePosts.map((post) async {
          try {
            final status = await ApiService.getPostVoteStatus(post['_id']);
            final isSaved = await ApiService.isPostSaved(post['_id']);
            post['isUpvoted'] = status['isUpvoted'] ?? false;
            post['isDownvoted'] = status['isDownvoted'] ?? false;
            post['isSaved'] = isSaved;

            // If this is a repost, fetch the original post data
            if (post['isRepost'] == true && post['originalPost'] is String) {
              try {
                final originalPost = await ApiService.getPost(post['originalPost']);
                post['originalPost'] = originalPost;
              } catch (e) {
                debugPrint('Error fetching original post: $e');
                post['originalPost'] = null;
              }
            }
          } catch (e) {
            debugPrint('Error processing post: $e');
          }
        })
      );
      
      if (mounted) {
        setState(() {
          userPosts.addAll(morePosts);
          postsPage = nextPage;
          isLoadingMorePosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        setState(() {
          isLoadingMorePosts = false;
        });
      }
    }
  }

  Future<void> _loadSavedPosts() async {
    if (isLoadingSaved) return;
    
    setState(() {
      isLoadingSaved = true;
    });

    try {
      // Load saved posts with pagination
      final saved = await ApiService.getSavedPosts(page: savedPage, limit: postsPerPage);
      debugPrint('Saved posts received: ${saved.length}');
      
      // Check if we have fewer posts than requested, meaning no more to load
      if (saved.length < postsPerPage) {
        hasMoreSaved = false;
      }

      // Process posts in parallel for better performance
      await Future.wait(
        saved.map((post) async {
          try {
            final status = await ApiService.getPostVoteStatus(post['_id']);
            post['isUpvoted'] = status['isUpvoted'] ?? false;
            post['isDownvoted'] = status['isDownvoted'] ?? false;
            post['isSaved'] = true;

            // If this is a repost, fetch the original post data
            if (post['isRepost'] == true && post['originalPost'] is String) {
              try {
                final originalPost = await ApiService.getPost(post['originalPost']);
                post['originalPost'] = originalPost;
              } catch (e) {
                debugPrint('Error fetching original post: $e');
                post['originalPost'] = null;
              }
            }
          } catch (e) {
            debugPrint('Error processing saved post: $e');
          }
        })
      );
      
      if (mounted) {
        setState(() {
          savedPosts = saved;
          isLoadingSaved = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved posts: $e');
      if (mounted) {
        setState(() {
          isLoadingSaved = false;
        });
      }
    }
  }

  Future<void> _loadMoreSavedPosts() async {
    if (isLoadingMoreSaved || !hasMoreSaved) return;
    
    setState(() {
      isLoadingMoreSaved = true;
    });

    try {
      final nextPage = savedPage + 1;
      final moreSaved = await ApiService.getSavedPosts(page: nextPage, limit: postsPerPage);
      
      // Check if we have fewer posts than requested, meaning no more to load
      if (moreSaved.length < postsPerPage) {
        hasMoreSaved = false;
      }

      // Process posts in parallel for better performance
      await Future.wait(
        moreSaved.map((post) async {
          try {
            final status = await ApiService.getPostVoteStatus(post['_id']);
            post['isUpvoted'] = status['isUpvoted'] ?? false;
            post['isDownvoted'] = status['isDownvoted'] ?? false;
            post['isSaved'] = true;

            // If this is a repost, fetch the original post data
            if (post['isRepost'] == true && post['originalPost'] is String) {
              try {
                final originalPost = await ApiService.getPost(post['originalPost']);
                post['originalPost'] = originalPost;
              } catch (e) {
                debugPrint('Error fetching original post: $e');
                post['originalPost'] = null;
              }
            }
          } catch (e) {
            debugPrint('Error processing saved post: $e');
          }
        })
      );
      
      if (mounted) {
        setState(() {
          savedPosts.addAll(moreSaved);
          savedPage = nextPage;
          isLoadingMoreSaved = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more saved posts: $e');
      if (mounted) {
        setState(() {
          isLoadingMoreSaved = false;
        });
      }
    }
  }

  Future<void> _handleTabChange(int index) async {
    if (selectedTab == index) return;
    
    setState(() {
      selectedTab = index;
    });
    
    if (index == 0 && userPosts.isEmpty) {
      _loadUserPosts();
    } else if (index == 1 && savedPosts.isEmpty) {
      _loadSavedPosts();
    }
  }

  Future<void> _refreshData() async {
    // Reset pagination
    setState(() {
      postsPage = 1;
      savedPage = 1;
      hasMorePosts = true;
      hasMoreSaved = true;
    });
    
    // Load profile first
    await _loadUserProfile();
    
    // Then load posts based on selected tab
    if (selectedTab == 0) {
      userPosts = [];
      await _loadUserPosts();
    } else {
      savedPosts = [];
      await _loadSavedPosts();
    }
  }

  Future<void> _handleUpvote(String postId) async {
    try {
      await ApiService.upvotePost(postId);
      setState(() {
        // Update vote status in both lists
        for (var p in userPosts) {
          if (p['_id'] == postId) {
            p['isUpvoted'] = !(p['isUpvoted'] ?? false);
            if (p['isUpvoted'] == true) {
              p['isDownvoted'] = false;
            }
          }
        }
        for (var p in savedPosts) {
          if (p['_id'] == postId) {
            p['isUpvoted'] = !(p['isUpvoted'] ?? false);
            if (p['isUpvoted'] == true) {
              p['isDownvoted'] = false;
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
        // Update vote status in both lists
        for (var p in userPosts) {
          if (p['_id'] == postId) {
            p['isDownvoted'] = !(p['isDownvoted'] ?? false);
            if (p['isDownvoted'] == true) {
              p['isUpvoted'] = false;
            }
          }
        }
        for (var p in savedPosts) {
          if (p['_id'] == postId) {
            p['isDownvoted'] = !(p['isDownvoted'] ?? false);
            if (p['isDownvoted'] == true) {
              p['isUpvoted'] = false;
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
      body: isLoadingProfile && userData == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            )
          : error != null && userData == null
              ? ConnectionErrorWidget(
                  onRetry: _loadUserProfile,
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFFFDCC87),
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserHeader(),
                            const SizedBox(height: 10),
                            Text(
                              userData?['bio'] ?? 'No bio available',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              softWrap: true,
                            ),
                            const SizedBox(height: 20),
                            _buildFollowCounts(),
                            const SizedBox(height: 20),
                            _buildTabs(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      _buildPosts(),
                      // Show loading indicator at bottom when loading more posts
                      if ((selectedTab == 0 && isLoadingMorePosts) || 
                          (selectedTab == 1 && isLoadingMoreSaved))
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

  Widget _buildUserHeader() {
    // Get the screen width to make responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDCC87), width: 2),
                ),
                child: CircleAvatar(
                  radius: isSmallScreen ? 35 : 40,
                  backgroundImage: userData?['profileImage'] != null && userData!['profileImage'].isNotEmpty
                      ? NetworkImage(ApiService.resolveImageUrl(userData!['profileImage']))
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${userData?['username'] ?? ''}',
                    style: TextStyle(
                      color: Colors.grey, 
                      fontSize: isSmallScreen ? 14 : 16
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDCC87),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 15, 
                  vertical: 8
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTabButton(0, 'Posts'),
        _buildTabButton(1, 'Saved'),
      ],
    );
  }

  Widget _buildTabButton(int index, String title) {
    return GestureDetector(
      onTap: () => _handleTabChange(index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? const Color(0xFFFDCC87) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (selectedTab == index)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: 40,
              color: const Color(0xFFFDCC87),
            ),
        ],
      ),
    );
  }

  Widget _buildPosts() {
    final posts = selectedTab == 0 ? userPosts : savedPosts;
    final isLoading = (selectedTab == 0 && isLoadingPosts) || (selectedTab == 1 && isLoadingSaved);
    
    if (isLoading && posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
          ),
        ),
      );
    }
    
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            selectedTab == 0 ? 'No posts yet' : 'No saved posts',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        return Post(
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
          originalPost: post['isRepost'] == true ? post['originalPost'] : null,
          onUpvote: _handleUpvote,
          onDownvote: _handleDownvote,
          isSaved: post['isSaved'] ?? false,
        );
      },
    );
  }

  Widget _buildFollowCounts() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;
    final fontSize = isSmallScreen ? 12.0 : 14.0;
    final countFontSize = isSmallScreen ? 14.0 : 16.0;
    
    // Build individual follow count items
    Widget buildFollowersItem() {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowersScreen(
                userId: userData!['_id'],
                isFollowers: true,
                title: 'Followers',
              ),
            ),
          );
          if (result == true) {
            _loadUserProfile();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${userData?['followers']?.length ?? 0} ',
              style: TextStyle(
                color: const Color(0xFFFDCC87),
                fontSize: countFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Followers',
              style: TextStyle(color: Colors.grey, fontSize: fontSize),
            ),
          ],
        ),
      );
    }

    Widget buildFollowingItem() {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowersScreen(
                userId: userData!['_id'],
                isFollowers: false,
                title: 'Following',
              ),
            ),
          );
          if (result == true) {
            _loadUserProfile();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${userData?['following']?.length ?? 0} ',
              style: TextStyle(
                color: const Color(0xFFFDCC87),
                fontSize: countFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Following',
              style: TextStyle(color: Colors.grey, fontSize: fontSize),
            ),
          ],
        ),
      );
    }
    
    // Use Column layout for very small screens
    if (isVerySmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFollowersItem(),
          const SizedBox(height: 4),
          buildFollowingItem(),
        ],
      );
    }
    
    // Use Row layout for larger screens
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: buildFollowersItem()),
        SizedBox(width: isSmallScreen ? 12 : 15),
        Flexible(child: buildFollowingItem()),
      ],
    );
  }
}
