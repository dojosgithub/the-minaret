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
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will refresh data when coming back from Followers screen
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
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

      // Load posts
      final posts = await ApiService.getUserPosts();
      debugPrint('User posts received: ${posts.length}');

      // Load saved posts
      final saved = await ApiService.getSavedPosts();
      debugPrint('Saved posts received: ${saved.length}');

      // Check vote and save status for all posts
      for (var post in posts) {
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
      }

      // Check vote and save status for saved posts
      for (var post in saved) {
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
      }
      
      if (mounted) {
        setState(() {
          userData = data;
          userPosts = posts;
          savedPosts = saved;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
              ),
            )
          : error != null
              ? ConnectionErrorWidget(
                  onRetry: _loadUserData,
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
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
                          _buildFollowCounts(),
                          const SizedBox(height: 20),
                          _buildTabs(),
                          const SizedBox(height: 10),
                          _buildPosts(),
                        ],
                        ),
                      ),
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
      onTap: () => setState(() => selectedTab = index),
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
    
    if (posts.isEmpty) {
      return Center(
        child: Text(
          selectedTab == 0 ? 'No posts yet' : 'No saved posts',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
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
            _loadUserData();
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
            _loadUserData();
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
