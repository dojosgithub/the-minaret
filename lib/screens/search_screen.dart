import 'package:flutter/material.dart';
import '../widgets/screen_wrapper.dart';
import '../services/api_service.dart';
import '../widgets/post.dart';
import 'home_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String? _selectedSortBy;
  String? _selectedDatePosted;
  String? _selectedPostedBy;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      debugPrint('Loading recent searches...');
      final searches = await ApiService.getRecentSearches();
      debugPrint('Loaded recent searches: $searches');
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recent searches: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ApiService.searchPosts(
        query: _searchController.text,
        sortBy: _selectedSortBy,
        datePosted: _selectedDatePosted,
        postedBy: _selectedPostedBy,
      );

      await ApiService.addRecentSearch(_searchController.text);
      await _loadRecentSearches();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to perform search')),
        );
      }
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      await ApiService.clearRecentSearches();
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF4F245A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4F245A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
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
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.grey),
                    onPressed: _performSearch,
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
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
                                  _performSearch();
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
            : _searchResults.isNotEmpty
                ? ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final post = _searchResults[index];
                      debugPrint('Post author data: ${post['author']}');
                      return Post(
                        id: post['_id'] ?? '',
                        name: '${post['author']['firstName'] ?? ''} ${post['author']['lastName'] ?? ''}',
                        username: post['author']['username'] ?? '',
                        profilePic: post['author']['profileImage'] ?? 'assets/default_profile.png',
                        title: post['title'] ?? '',
                        text: post['body'] ?? '',
                        media: List<Map<String, dynamic>>.from(post['media'] ?? []),
                        links: List<Map<String, dynamic>>.from(post['links'] ?? []),
                        upvoteCount: post['upvotes'] ?? 0,
                        downvoteCount: post['downvotes'] ?? 0,
                        repostCount: post['reposts'] ?? 0,
                        createdAt: post['createdAt'] ?? '',
                        authorId: post['author']['_id'] ?? '',
                      );
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recently Searched",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_recentSearches.isNotEmpty)
                              TextButton(
                                onPressed: _clearRecentSearches,
                                child: const Text(
                                  "Clear All",
                                  style: TextStyle(color: Color(0xFFFDCC87)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_recentSearches.isEmpty)
                          const Center(
                            child: Text(
                              "No recent searches",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else
                          ..._recentSearches.map((search) => _buildRecentlySearchedOption(search)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildRecentlySearchedOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFFFDCC87)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                _recentSearches.remove(text);
              });
            },
          ),
        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}