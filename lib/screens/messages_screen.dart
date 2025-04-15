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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await MessageService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: const TopBarWithoutMenu(),
      floatingActionButton: FloatingActionButton(
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
      ),
      
      body: _isLoading
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
                        onPressed: _loadConversations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDCC87),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
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
                            final otherUser = conversation
                                .getOtherParticipant(ApiService.currentUserId ?? '');
                            final lastMessage = conversation.lastMessage;
                            final isLastMessageFromMe = lastMessage?.senderId == ApiService.currentUserId;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: otherUser['profileImage'] != null
                                    ? NetworkImage(otherUser['profileImage'])
                                    : const AssetImage('assets/default_profile.png')
                                        as ImageProvider,
                              ),
                              title: Text(
                                '${otherUser['firstName']} ${otherUser['lastName']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                lastMessage?.content ?? 'No messages yet',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  overflow: TextOverflow.ellipsis,
                                ),
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