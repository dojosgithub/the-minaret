import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';
import '../profile/followers_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/message_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoadingUserInfo = true;
  bool isLoadingPosts = true;
  String? userInfoError;
  String? postsError;
  bool isFollowing = false;
  bool isBlocked = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    try {
      final blocked = await ApiService.isBlocked(widget.userId);
      if (mounted) {
        setState(() {
          isBlocked = blocked;
        });
      }
    } catch (e) {
      debugPrint('Error checking block status: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      isLoadingUserInfo = true;
      userInfoError = null;
    });

    try {
      // Verify token first
      final isValid = await ApiService.verifyToken();
      if (!isValid) {
        throw Exception('Please log in again');
      }

      // Load user profile
      final data = await ApiService.getUserById(widget.userId);
      debugPrint('User data received: $data');

      // Check if current user is following this user
      final isFollowingUser = await ApiService.isFollowing(widget.userId);

      if (mounted) {
        setState(() {
          userData = data;
          isFollowing = isFollowingUser;
          isLoadingUserInfo = false;
        });
        // Load posts after user info is loaded
        _loadUserPosts();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          userInfoError = e.toString();
          isLoadingUserInfo = false;
        });
      }
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() {
      isLoadingPosts = true;
      postsError = null;
    });
    try {
      // Load user's posts
      final posts = await ApiService.getUserPostsById(widget.userId);
      

      // Check vote status for each post
      for (var post in posts) {
        final status = await ApiService.getPostVoteStatus(post['_id']);
        post['isUpvoted'] = status['isUpvoted'] ?? false;
        post['isDownvoted'] = status['isDownvoted'] ?? false;
      }

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
          postsError = e.toString();
          isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (isLoadingUserInfo) return;

    setState(() {
      isLoadingUserInfo = true;
    });

    try {
      // Store original following state to determine what changed
      final wasFollowing = isFollowing;
      
      if (wasFollowing) {
        await ApiService.unfollowUser(widget.userId);
        // Decrease followers count
        if (userData != null && userData!['followers'] != null) {
          setState(() {
            // Safely decrement followers count only if we were previously following
            if (userData!['followers'] is List) {
              List followers = List.from(userData!['followers']);
              if (followers.isNotEmpty) {
                followers.removeWhere((follower) => 
                  follower == ApiService.currentUserId || 
                  (follower is Map && follower['_id'] == ApiService.currentUserId));
                userData!['followers'] = followers;
              }
            } else if (userData!['followers'] is int && userData!['followers'] > 0) {
              userData!['followers'] = userData!['followers'] - 1;
            }
          });
        }
      } else {
        await ApiService.followUser(widget.userId);
        // Increase followers count
        if (userData != null) {
          setState(() {
            // Safely increment followers count only if we were not previously following
            if (userData!['followers'] is List) {
              List followers = List.from(userData!['followers']);
              final currentUserId = ApiService.currentUserId;
              if (followers.any((follower) => 
                follower == currentUserId || 
                (follower is Map && follower['_id'] == currentUserId))) {
                followers.add(currentUserId);
                userData!['followers'] = followers;
              }
            } else if (userData!['followers'] is int) {
              userData!['followers'] = userData!['followers'] + 1;
            } else {
              userData!['followers'] = 1;
            }
          });
        }
      }
      
      if (mounted) {
        // Only change the follow state after the operation completes successfully
        setState(() {
          isFollowing = !wasFollowing;
          isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user')),
        );
        setState(() {
          isLoadingUserInfo = false;
        });
      }
    }
  }

  Future<void> _toggleBlockUser() async {
    final scaffoldContext = context;
    
    // Show confirmation dialog
    final bool shouldBlock = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D1B45),
        title: Text(
          isBlocked ? 'Unblock User?' : 'Block User?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isBlocked 
            ? 'You will be able to see ${userData?['username'] ?? 'this user'}\'s posts again.'
            : 'You will no longer see posts from ${userData?['username'] ?? 'this user'}, and they won\'t be able to see your profile or posts.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? const Color(0xFFFDCC87) : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isBlocked ? 'Unblock' : 'Block',
              style: TextStyle(
                color: isBlocked ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldBlock) return;
    
    try {
      setState(() {
        isLoadingUserInfo = true;
      });
      
      if (isBlocked) {
        await ApiService.unblockUser(widget.userId);
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(content: Text('User unblocked successfully')),
        );
      } else {
        await ApiService.blockUser(widget.userId);
        // If following, automatically unfollow when blocking
        if (isFollowing) {
          await ApiService.unfollowUser(widget.userId);
          isFollowing = false;
        }
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(content: Text('User blocked successfully')),
        );
      }
      
      setState(() {
        isBlocked = !isBlocked;
        isLoadingUserInfo = false;
      });
    } catch (e) {
      debugPrint('Error toggling block status: $e');
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Failed to ${isBlocked ? 'unblock' : 'block'} user: $e')),
      );
      setState(() {
        isLoadingUserInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: const TopBarWithoutMenu(),
        body: isLoadingUserInfo
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                ),
              )
            : userInfoError != null
                ? ConnectionErrorWidget(
                    onRetry: _loadUserInfo,
                  )
                : isBlocked
                    ? _buildBlockedUserView()
                    : RefreshIndicator(
                        onRefresh: _loadUserInfo,
                        color: const Color(0xFFFDCC87),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildUserHeader(),
                                    const SizedBox(height: 10),
                                    if (userData?.containsKey('bio') == true && 
                                        userData?['bio'] != null && 
                                        userData!['bio'].toString().isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData!['bio'],
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                            softWrap: true,
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    _buildFollowAndBlockRow(),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                              
                              // Posts section with its own loading state - full width
                              isLoadingPosts
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 30.0),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                                      ),
                                    ),
                                  )
                                : postsError != null
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Failed to load posts',
                                                style: TextStyle(color: Colors.white, fontSize: 16),
                                              ),
                                              const SizedBox(height: 10),
                                              ElevatedButton(
                                                onPressed: _loadUserPosts,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFFDCC87),
                                                ),
                                                child: const Text('Retry', style: TextStyle(color: Colors.black)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _buildPosts(),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildBlockedUserView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'You have blocked ${userData?['username'] ?? 'this user'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You cannot see their profile or posts until you unblock them.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDCC87),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _toggleBlockUser,
              icon: const Icon(Icons.person_add, color: Colors.black),
              label: const Text('Unblock User', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFDCC87), width: 2),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: userData?['profileImage'] != null && userData!['profileImage'].isNotEmpty
                ? NetworkImage(ApiService.resolveImageUrl(userData!['profileImage']))
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${userData?['username'] ?? ''}',
                style: const TextStyle(color: const Color(0xFFFDCC87), fontSize: 14),
              ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey : const Color(0xFFFDCC87),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: _toggleFollow,
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowAndBlockRow() {
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
                userId: widget.userId,
                isFollowers: true,
                title: 'Followers',
              ),
            ),
          );
          if (result == true) {
            _loadUserInfo();
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
                userId: widget.userId,
                isFollowers: false,
                title: 'Following',
              ),
            ),
          );
          if (result == true) {
            _loadUserInfo();
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
    
    // Three-dot menu with block option
    Widget buildOptionsMenu() {
      return PopupMenuButton<String>(
        color: const Color(0xFF3D1B45),
        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'block') {
            _toggleBlockUser();
          } else if (value == 'share') {
            _showShareProfileDialog();
          } else if (value == 'report') {
            _showReportUserDialog();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                const Icon(
                  Icons.share,
                  color: Color(0xFFFDCC87),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Share Profile',
                  style: TextStyle(
                    color: Color(0xFFFDCC87),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Report User',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'block',
            child: Row(
              children: [
                Icon(
                  isBlocked ? Icons.person_add : Icons.block,
                  color: isBlocked ? const Color(0xFFFDCC87) : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isBlocked ? 'Unblock User' : 'Block User',
                  style: TextStyle(
                    color: isBlocked ? const Color(0xFFFDCC87) : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Use Column layout for very small screens
    if (isVerySmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildFollowersItem(),
              buildOptionsMenu(),
            ],
          ),
          const SizedBox(height: 4),
          buildFollowingItem(),
        ],
      );
    }
    
    // Use Row layout for larger screens
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            buildFollowersItem(),
            SizedBox(width: isSmallScreen ? 12 : 15),
            buildFollowingItem(),
          ],
        ),
        buildOptionsMenu(),
      ],
    );
  }

  Widget _buildPosts() {
    if (userPosts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
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
          originalPost: post['originalPost'],
          onUpvote: (postId) async {
            try {
              await ApiService.upvotePost(postId);
            } catch (e) {
              debugPrint('Error upvoting post: $e');
            }
          },
          onDownvote: (postId) async {
            try {
              await ApiService.downvotePost(postId);
            } catch (e) {
              debugPrint('Error downvoting post: $e');
            }
          },
          onPostBlocked: (postId) {
            // If a user blocks the author from a post, refresh the profile
            _checkBlockStatus();
            _loadUserInfo();
          },
        );
      },
    );
  }

  // Add a method to show the share profile dialog
  void _showShareProfileDialog() {
    final TextEditingController _searchController = TextEditingController();
    List<Map<String, dynamic>> _searchResults = [];
    bool _isSearching = false;
    Timer? _debounce;

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
                  // Filter out current user and the profile being viewed from API results
                  final filteredResults = searchResults.where((user) => 
                    user['_id'] != currentUserId && user['_id'] != widget.userId
                  ).toList();
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
                              // Get profile name for the message
                              final profileName = userData?['firstName'] != null && userData?['lastName'] != null
                                  ? '${userData?['firstName']} ${userData?['lastName']}'
                                  : userData?['username'] ?? 'this profile';
                              
                              await ApiService.sendMessage(
                                user['_id'],
                                'Check out ${profileName}\'s profile',
                                profileId: widget.userId,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile shared successfully')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to share profile: $e')),
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
                    'Share Profile',
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
                                      // Get profile name for the message
                                      final profileName = userData?['firstName'] != null && userData?['lastName'] != null
                                          ? '${userData?['firstName']} ${userData?['lastName']}'
                                          : userData?['username'] ?? 'this profile';
                                      
                                      await ApiService.sendMessage(
                                        user['id'],
                                        'Check out ${profileName}\'s profile',
                                        profileId: widget.userId,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Profile shared successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to share profile: $e')),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildShareOption(
                          icon: Icons.copy,
                          label: 'Copy Link',
                          onTap: () {
                            final username = userData?['username'] ?? '';
                            Clipboard.setData(ClipboardData(
                              text: 'https://minaret.com/profile/$username',
                            ));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile link copied to clipboard')),
                            );
                          },
                        ),
                      ],
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
          if (userId != null && !addedUserIds.contains(userId) && userId != widget.userId) {
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
          if (userId != null && !addedUserIds.contains(userId) && userId != widget.userId) {
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

  // Add a method to show the user report dialog
  void _showReportUserDialog() {
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

    showDialog(
      context: context,
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
                        'Report User',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Why are you reporting this user?',
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
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: selectedReason == null ? null : () async {
                              Navigator.pop(dialogContext);
                              await _submitReport(selectedReason!, _additionalContextController.text.trim());
                            },
                            child: const Text(
                              'Report',
                              style: TextStyle(color: Colors.white),
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

  Future<void> _submitReport(String reason, String additionalContext) async {
    setState(() => isSubmitting = true);
    
    try {
      // Submit the report
      await ApiService.reportContent(
        userId: widget.userId,
        contentType: 'user',
        reason: reason,
        additionalContext: additionalContext
      );
      
      if (mounted) {
        // Show follow-up dialog for following status
        if (isFollowing) {
          _showFollowUpDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your report. We will review it shortly.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error reporting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showFollowUpDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF3D1B45),
        title: const Text(
          'Would you like to unfollow this user?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You can choose to keep following or unfollow this user.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your report. We will review it shortly.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Keep Following',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ApiService.unfollowUser(widget.userId);
                if (mounted) {
                  setState(() {
                    isFollowing = false;
                    // Update followers count
                    if (userData != null && userData!['followers'] != null) {
                      if (userData!['followers'] is List) {
                        List followers = List.from(userData!['followers']);
                        followers.removeWhere((follower) => 
                          follower == ApiService.currentUserId || 
                          (follower is Map && follower['_id'] == ApiService.currentUserId));
                        userData!['followers'] = followers;
                      } else if (userData!['followers'] is int && userData!['followers'] > 0) {
                        userData!['followers'] = userData!['followers'] - 1;
                      }
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User reported and unfollowed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error unfollowing user: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error unfollowing user: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Unfollow User',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 