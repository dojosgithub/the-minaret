import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';
import '../screens/followers_screen.dart';

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
              if (currentUserId != null && !followers.any((follower) => 
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
    return Scaffold(
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
                        child: Padding(
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
                              _buildFollowAndBlockRow(),
                              const SizedBox(height: 20),
                              
                              // Posts section with its own loading state
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${userData?['username'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
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
              fontSize: 14,
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
          }
        },
        itemBuilder: (context) => [
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
                    color: isBlocked ? const Color(0xFFFDCC87) : Colors.white,
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
} 