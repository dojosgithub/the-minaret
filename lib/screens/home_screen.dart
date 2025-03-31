import 'package:flutter/material.dart';
import '../widgets/post.dart';
import '../widgets/screen_wrapper.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _initializePosts();
  }

  void _initializePosts() {
    _postsFuture = ApiService.getPosts().catchError((error) {
      print('Error fetching posts: $error');
      return []; // Return empty list on error
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 0,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _initializePosts();
          });
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializePosts();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data ?? [];
            
            if (posts.isEmpty) {
              return const Center(
                child: Text('No posts available'),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: posts.map((post) => Post(
                  name: "${post['author']['firstName']} ${post['author']['lastName']}",
                  username: post['author']['username'],
                  profilePic: post['author']['profileImage'],
                  title: post['title'],
                  text: post['body'],
                  media: List<Map<String, dynamic>>.from(post['media'] ?? []),
                  links: List<Map<String, dynamic>>.from(post['links'] ?? []),
                  upvoteCount: post['likes']?.length ?? 0,
                  downvoteCount: 0,
                  repostCount: 0,
                )).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
