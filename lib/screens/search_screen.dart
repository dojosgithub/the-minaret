import 'package:flutter/material.dart';
import '../widgets/screen_wrapper.dart';
import '../services/api_service.dart';
import '../widgets/post.dart';
import '../widgets/connection_error_widget.dart';
import 'home_screen.dart';

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
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _error;
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
        _hasError = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
      setState(() {
        _hasError = e.toString().contains('Failed to connect to server');
        _error = e.toString();
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _error = null;
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

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = e.toString().contains('Failed to connect to server');
          _error = e.toString();
          _searchResults = []; // Clear search results on error
        });
      }
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      await ApiService.clearRecentSearches();
      setState(() {
        _recentSearches = [];
        _hasError = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
      setState(() {
        _hasError = e.toString().contains('Failed to connect to server');
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F245A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
          onPressed: () {
            widget.onIndexChanged(0);
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
          : _hasError && _error != null && _error!.contains('Failed to connect to server')
              ? ConnectionErrorWidget(
                  onRetry: () {
                    if (_searchController.text.isNotEmpty) {
                      _performSearch();
                    } else {
                      _loadRecentSearches();
                    }
                  },
                )
              : _searchResults.isNotEmpty
                  ? ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final post = _searchResults[index];
                        return Post(
                          id: post['_id'] ?? '',
                          name: post['author']['firstName'] != null && post['author']['lastName'] != null
                              ? '${post['author']['firstName']} ${post['author']['lastName']}'
                              : post['author']['username'] ?? 'Unknown User',
                          username: post['author']['username'] ?? '',
                          profilePic: post['author']['profileImage'] != null && post['author']['profileImage'].isNotEmpty
                              ? post['author']['profileImage']
                              : 'assets/default_profile.png',
                          title: post['title'] ?? '',
                          text: post['body'] ?? '',
                          media: List<Map<String, dynamic>>.from(post['media'] ?? []),
                          links: List<Map<String, dynamic>>.from(post['links'] ?? []),
                          upvoteCount: (post['upvotes'] as List?)?.length ?? 0,
                          downvoteCount: (post['downvotes'] as List?)?.length ?? 0,
                          repostCount: (post['reposts'] as List?)?.length ?? 0,
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
            child: GestureDetector(
              onTap: () {
                _searchController.text = text;
                _performSearch();
              },
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () async {
              try {
                await ApiService.deleteRecentSearch(text);
                await _loadRecentSearches();
              } catch (e) {
                debugPrint('Error deleting recent search: $e');
                setState(() {
                  _hasError = e.toString().contains('Failed to connect to server');
                  _error = e.toString();
                });
              }
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