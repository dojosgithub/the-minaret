import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/api_service.dart';
import '../screens/post_detail_screen.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Keep track of scroll position
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when widget updates (new messages arrive)
    _scrollToBottom();
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
      await _loadMessages();
      await _loadUserDetails();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    try {
      debugPrint('Loading messages for conversation: ${widget.conversationId}');
      final messages = await MessageService.getMessages(widget.conversationId);
      debugPrint('Loaded ${messages.length} messages');
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final userDetails = await ApiService.getUserById(widget.otherUser['_id']);
      setState(() {
        widget.otherUser.updateAll((key, value) => userDetails[key] ?? value);
      });
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      // Ensure the recipient ID is properly formatted
      final recipientId = widget.otherUser['_id']?.toString();
      if (recipientId == null || recipientId.isEmpty) {
        throw Exception('Invalid recipient ID');
      }

      await ApiService.sendMessage(
        recipientId,
        content,
      );
      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _handlePostTap(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F245A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFDCC87),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: widget.otherUser['profileImage'] != null
                    ? NetworkImage(ApiService.resolveImageUrl(widget.otherUser['profileImage']))
                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                radius: 24,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.otherUser['firstName']} ${widget.otherUser['lastName']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${widget.otherUser['username']}',
                  style: TextStyle(
                    color: const Color(0xFFFDCC87),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                              onPressed: _loadData,
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
                        child: _messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                reverse: false,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isMe = _currentUserId != null && message.senderId == _currentUserId;

                                  return Align(
                                    alignment: isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFFFDCC87)
                                            : const Color(0xFF9D3267),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe)
                                            Text(
                                              '${widget.otherUser['firstName']} ${widget.otherUser['lastName']}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          if (message.postId != null)
                                            GestureDetector(
                                              onTap: () => _handlePostTap(message.postId!),
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.5,
                                                padding: const EdgeInsets.all(12),
                                                margin: const EdgeInsets.symmetric(vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isMe ? const Color(0xFF9D3267) : const Color(0xFFFDCC87),
                                                  borderRadius: BorderRadius.circular(15),
                                                  border: Border.all(
                                                    color: const Color(0xFFFDCC87).withValues(alpha: 72),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: FutureBuilder<Map<String, dynamic>>(
                                                    future: ApiService.getPost(message.postId!),
                                                    builder: (context, snapshot) {
                                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                                        return const Center(
                                                          child: CircularProgressIndicator(
                                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                                                          ),
                                                        );
                                                      }
                                                      if (snapshot.hasError) {
                                                        return const Center(
                                                          child: Text(
                                                            'Post is Unavailable',
                                                            style: TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      final post = snapshot.data;
                                                      if (post == null) {
                                                        return const Center(
                                                          child: Text(
                                                            'Post not found',
                                                            style: TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            post['title'] ?? '',
                                                            style: TextStyle(
                                                              color: isMe ? Colors.white : Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (post['body'] != null) ...[
                                                            const SizedBox(height: 8),
                                                            Text(
                                                              post['body'],
                                                              style: TextStyle(
                                                                color: isMe ? Colors.white70 : Colors.black87,
                                                                fontSize: 14,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Text(
                                            message.content,
                                            style: TextStyle(
                                              color: isMe ? Colors.black : Colors.white,
                                            ),
                                          ),
                                          Text(
                                            _formatTime(message.createdAt),
                                            style: TextStyle(
                                              color: isMe ? Colors.black54 : Colors.grey[200],
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),
            decoration: BoxDecoration(
              color: const Color(0xFF4F245A),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF3A1E47),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFDCC87)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
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