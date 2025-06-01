import 'package:flutter/material.dart';
import '../widgets/top_bar_without_menu.dart';
import '../services/api_service.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true for followers, false for following
  final String title;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
    required this.title,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? error;
  Map<String, bool> followingStatus = {};
  String? currentUserId;
  static bool _hasChangedFollowStatus = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUserId = await ApiService.currentUserId;
      _loadUsers();
    } catch (e) {
      debugPrint('Error loading current user: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
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

      // Load users based on the isFollowers flag
      List<Map<String, dynamic>> loadedUsers;
      if (widget.isFollowers) {
        loadedUsers = await ApiService.getUserFollowers(widget.userId);
      } else {
        loadedUsers = await ApiService.getUserFollowing(widget.userId);
      }

      // Check following status for each user
      for (var user in loadedUsers) {
        final isFollowingUser = await ApiService.isFollowing(user['_id']);
        followingStatus[user['_id']] = isFollowingUser;
      }

      if (mounted) {
        setState(() {
          users = loadedUsers;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(String userId) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final isCurrentlyFollowing = followingStatus[userId] ?? false;

      if (isCurrentlyFollowing) {
        await ApiService.unfollowUser(userId);
      } else {
        await ApiService.followUser(userId);
      }

      // Set a static flag so parent knows to refresh when this screen pops
      _hasChangedFollowStatus = true;

      setState(() {
        followingStatus[userId] = !isCurrentlyFollowing;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${followingStatus[userId] ?? false ? 'unfollow' : 'follow'} user')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          Navigator.pop(context, _hasChangedFollowStatus);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: const TopBarWithoutMenu(),
        body: Column(
          children: [
            // Second app bar with back button and title
            Container(
              color: const Color(0xFF4F245A),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: const Color(0xFF4F245A),
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                      onPressed: () {
                        Navigator.pop(context, _hasChangedFollowStatus);
                      },
                    ),
                    title: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(
                    color: Colors.grey.shade700,
                    thickness: 0.5,
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error: $error',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUsers,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFDCC87),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        )
                      : users.isEmpty
                          ? Center(
                              child: Text(
                                widget.isFollowers ? 'No followers yet' : 'Not following anyone',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadUsers,
                              color: const Color(0xFFFDCC87),
                              child: ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final isCurrentUser = user['_id'] == currentUserId;
                                  final isFollowing = followingStatus[user['_id']] ?? false;

                                  return ListTile(
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFFDCC87), width: 1),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundImage: user['profileImage'] != null && user['profileImage'].isNotEmpty
                                            ? NetworkImage(ApiService.resolveImageUrl(user['profileImage']))
                                            : const AssetImage('assets/default_profile.png') as ImageProvider,
                                      ),
                                    ),
                                    title: Text(
                                      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '@${user['username'] ?? ''}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    trailing: isCurrentUser
                                        ? const Text(
                                            '',
                                            style: TextStyle(
                                              color: Color(0xFFFDCC87),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isFollowing ? Colors.grey : const Color(0xFFFDCC87),
                                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                            onPressed: () => _toggleFollow(user['_id']),
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
                                      // Navigate to user profile
                                      if (user['_id'] != currentUserId) {
                                        Navigator.pushNamed(
                                          context,
                                          '/profile',
                                          arguments: user['_id'],
                                        );
                                      } else {
                                        Navigator.pushNamed(context, '/user');
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
} 