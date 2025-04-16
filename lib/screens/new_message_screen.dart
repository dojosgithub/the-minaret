import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/message_service.dart';
import 'conversation_screen.dart';
import '../widgets/top_bar_without_menu.dart';
import 'dart:async';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await MessageService.getConversations();
      final currentUserId = await ApiService.currentUserId;
      final users = conversations
          .map((conv) => conv.getOtherParticipant(currentUserId ?? ''))
          .where((userId) => userId != currentUserId)
          .toList();
      
      // Fetch user details for each user ID
      final userDetails = await Future.wait(
        users.map((userId) => ApiService.getUserById(userId))
      );
      
      setState(() {
        _users = userDetails;
        _filteredUsers = List.from(_users);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _filteredUsers = _users;
        });
        return;
      }

      // First search in existing conversations
      final localResults = _users.where((user) {
        final fullName = '${user['firstName']} ${user['lastName']}'.toLowerCase();
        final username = user['username'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return fullName.contains(searchQuery) || username.contains(searchQuery);
      }).toList();

      if (localResults.isNotEmpty) {
        setState(() {
          _filteredUsers = localResults;
        });
        return;
      }

      // If no local results, make API call
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final searchResults = await ApiService.searchUsers(query);
        final currentUserId = await ApiService.currentUserId;
        // Filter out current user from API results as well
        final filteredResults = searchResults.where((user) => user['_id'] != currentUserId).toList();
        setState(() {
          _filteredUsers = filteredResults;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const TopBarWithoutMenu(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF3A1E47),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDCC87),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user['profileImage'] != null
                                      ? NetworkImage(user['profileImage'])
                                      : const AssetImage(
                                              'assets/default_profile.png')
                                          as ImageProvider,
                                ),
                                title: Text(
                                  '${user['firstName']} ${user['lastName']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '@${user['username']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConversationScreen(
                                        conversationId: user['_id'],
                                        otherUser: user,
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
    );
  }
} 