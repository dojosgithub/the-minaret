import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../services/message_service.dart';
import '../services/api_service.dart';
import 'conversation_screen.dart';
import 'new_message_screen.dart';
import '../widgets/top_bar_without_menu.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Conversation> _conversations = [];
  List<Map<String, dynamic>> _userDetails = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {  
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentUserId = await ApiService.currentUserId;
      if (_currentUserId == null) {
        setState(() {
          _error = 'Please log in to view messages';
          _isLoading = false;
        });
        return;
      }
      await _loadConversations();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _error = 'Error loading messages. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await MessageService.getConversations();
      if (_currentUserId == null) {
        setState(() {
          _error = 'Please log in to view messages';
          _isLoading = false;
        });
        return;
      }

      final userDetails = await Future.wait(
        conversations.map((conv) => ApiService.getUserById(conv.getOtherParticipant(_currentUserId!)))
      );
      
      setState(() {
        _conversations = conversations;
        _userDetails = userDetails;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (e.toString().contains('Token is not valid')) {
        await ApiService.logout();
        setState(() {
          _error = 'Session expired. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      body: Column(
        children: [
          const TopBarWithoutMenu(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFDCC87)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Your Messages",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    
                  ),
                ),
              ],
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
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ApiService.logout();
                                _loadData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDCC87),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFFFDCC87),
                        child: _conversations.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _conversations.length,
                                itemBuilder: (context, index) {
                                  final conversation = _conversations[index];
                                  if (_currentUserId == null) return const SizedBox.shrink();
                                  
                                  final otherUser = _userDetails[index];
                                  final lastMessage = conversation.lastMessage;
                                  final isLastMessageFromMe = lastMessage?['sender']?['_id'] == _currentUserId;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: otherUser['profileImage'] != null
                                          ? NetworkImage(ApiService.resolveImageUrl(otherUser['profileImage'] as String))
                                          : null,
                                      child: otherUser['profileImage'] == null
                                          ? Text(
                                              '${otherUser['firstName']?[0] ?? ''}${otherUser['lastName']?[0] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      '${otherUser['firstName'] ?? ''} ${otherUser['lastName'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      lastMessage?['content'] ?? 'No messages yet',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatTime(conversation.lastMessageAt),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (conversation.unreadCount > 0 && !isLastMessageFromMe)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFDCC87),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              conversation.unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ConversationScreen(
                                            conversationId: conversation.id,
                                            otherUser: otherUser,
                                          ),
                                        ),
                                      ).then((_) => _loadConversations());
                                    },
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _currentUserId != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewMessageScreen(),
                  ),
                ).then((_) => _loadConversations());
              },
              backgroundColor: const Color(0xFFFDCC87),
              child: const Icon(Icons.message, color: Color(0xFF4F245A)),
            )
          : null,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 