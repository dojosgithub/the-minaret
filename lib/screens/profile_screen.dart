import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;
  String? error;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      final data = await ApiService.getUserById(widget.userId);
      debugPrint('User data received: $data');

      // Load user's posts
      final posts = await ApiService.getUserPostsById(widget.userId);
      debugPrint('User posts received: ${posts.length}');

      // Check vote status for each post
      for (var post in posts) {
        final status = await ApiService.getPostVoteStatus(post['_id']);
        post['isUpvoted'] = status['isUpvoted'] ?? false;
        post['isDownvoted'] = status['isDownvoted'] ?? false;
      }

      // Check if current user is following this user
      final isFollowingUser = await ApiService.isFollowing(widget.userId);
      
      if (mounted) {
        setState(() {
          userData = data;
          userPosts = posts;
          isFollowing = isFollowingUser;
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

  Future<void> _toggleFollow() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isFollowing) {
        await ApiService.unfollowUser(widget.userId);
      } else {
        await ApiService.followUser(widget.userId);
      }
      
      if (mounted) {
        setState(() {
          isFollowing = !isFollowing;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const TopBarWithoutMenu(),
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
                          _buildPosts(),
                        ],
                      ),
                    ),
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

  Widget _buildFollowCounts() {
    return Row(
      children: [
        Text(
          '${userData?['followers']?.length ?? 0} ',
          style: const TextStyle(
            color: Color(0xFFFDCC87),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Followers',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(width: 15),
        Text(
          '${userData?['following']?.length ?? 0} ',
          style: const TextStyle(
            color: Color(0xFFFDCC87),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Following',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
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
          repostCount: (post['reposts'] as List?)?.length ?? 0,
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
        );
      },
    );
  }
} 