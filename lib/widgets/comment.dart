import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../services/api_service.dart';

class Comment extends StatefulWidget {
  final String authorName;
  final String authorUsername;
  final String authorProfilePic;
  final String text;
  final String createdAt;
  final List<Map<String, dynamic>> replies;
  final VoidCallback onReply;
  final String commentId;
  final String postId;
  final String authorId;
  final Function? onCommentDeleted;

  const Comment({
    super.key,
    required this.authorName,
    required this.authorUsername,
    required this.authorProfilePic,
    required this.text,
    required this.createdAt,
    this.replies = const [],
    required this.onReply,
    required this.commentId,
    required this.postId,
    required this.authorId,
    this.onCommentDeleted,
  });

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  List<Map<String, dynamic>> _replies = [];

  @override
  void initState() {
    super.initState();
    _replies = List<Map<String, dynamic>>.from(widget.replies);
  }

  @override
  void didUpdateWidget(Comment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replies != oldWidget.replies) {
      setState(() {
        _replies = List<Map<String, dynamic>>.from(widget.replies);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(widget.authorProfilePic),
                  radius: 16,
                  backgroundColor: const Color(0xFF3D1B45),
                  onBackgroundImageError: (_, __) {
                    // Handle image load errors
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '@${widget.authorUsername}',
                                  style: const TextStyle(
                                    color: Color(0xFFFDCC87),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          getTimeAgo(DateTime.parse(widget.createdAt)),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        FutureBuilder<String?>(
                          future: ApiService.currentUserId,
                          builder: (context, snapshot) {
                            final isAuthor = snapshot.hasData && snapshot.data == widget.authorId;
                            
                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                              color: const Color(0xFF3D1B45),
                              onSelected: (value) {
                                if (value == 'report') {
                                  _showReportDialog(context);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(context);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                if (isAuthor)
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  PopupMenuItem<String>(
                                    value: 'report',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.flag, size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Report',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onReply,
                          child: const Row(
                            children: [
                              Icon(Icons.reply, color: Color(0xFFFDCC87), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: Color(0xFFFDCC87),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._replies.map((reply) {
              return Container(
                margin: const EdgeInsets.only(left: 30, top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                          ApiService.resolveImageUrl(reply['author']['profileImage'] ?? ''),
                        ),
                        radius: 14,
                        backgroundColor: const Color(0xFF3D1B45),
                        onBackgroundImageError: (_, __) {
                          // Handle image load errors
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${reply['author']['firstName']} ${reply['author']['lastName']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '@${reply['author']['username']}',
                                        style: const TextStyle(
                                          color: Color(0xFFFDCC87),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                getTimeAgo(DateTime.parse(reply['createdAt'])),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              FutureBuilder<String?>(
                                future: ApiService.currentUserId,
                                builder: (context, snapshot) {
                                  final isReplyAuthor = snapshot.hasData && 
                                      snapshot.data == reply['author']['_id'];
                                  
                                  return PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                                    color: const Color(0xFF3D1B45),
                                    onSelected: (value) {
                                      if (value == 'report') {
                                        _showReportDialog(
                                          context,
                                          isReply: true,
                                          replyId: reply['_id'],
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(
                                          context,
                                          isReply: true,
                                          replyId: reply['_id'],
                                        );
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      if (isReplyAuthor)
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete, size: 16, color: Colors.red),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        PopupMenuItem<String>(
                                          value: 'report',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.flag, size: 16, color: Colors.red),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Report',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                }
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reply['text'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, {bool isReply = false, String? replyId}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1B45),
          title: Text(
            'Delete ${isReply ? 'Reply' : 'Comment'}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete this ${isReply ? 'reply' : 'comment'}? This action cannot be undone.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                try {
                  if (isReply) {
                    await ApiService.deleteReply(widget.postId, widget.commentId, replyId!);
                    // Update UI to remove the deleted reply
                    setState(() {
                      _replies.removeWhere((r) => r['_id'] == replyId);
                    });
                  } else {
                    await ApiService.deleteComment(widget.postId, widget.commentId);
                    if (widget.onCommentDeleted != null) {
                      widget.onCommentDeleted!();
                    }
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${isReply ? 'Reply' : 'Comment'} deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete ${isReply ? 'reply' : 'comment'}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, {bool isReply = false, String? replyId}) {
    final List<String> reportReasons = [
      'Inappropriate Content',
      'Misinformation',
      'Hate Speech',
      'Spam',
      'Harassment',
      'Violence',
      'Copyright Violation',
      'Other'
    ];
    
    String? selectedReason;
    final TextEditingController _additionalContextController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF3D1B45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReply ? 'Report Reply' : 'Report Comment',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Why are you reporting this ${isReply ? 'reply' : 'comment'}?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(builderContext).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: reportReasons.map((reason) {
                              return RadioListTile<String>(
                                title: Text(
                                  reason,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                value: reason,
                                groupValue: selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    selectedReason = value;
                                  });
                                },
                                activeColor: const Color(0xFFFDCC87),
                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return const Color(0xFFFDCC87);
                                    }
                                    return Colors.white;
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Additional Context (Optional)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _additionalContextController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Provide more details about this report...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF4F245A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDCC87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: selectedReason == null || _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    
                                    // Submit the report with both comment and post IDs
                                    ApiService.reportContent(
                                      commentId: widget.commentId,
                                      postId: widget.postId,
                                      replyId: replyId,
                                      contentType: isReply ? 'reply' : 'comment',
                                      reason: selectedReason!,
                                      additionalContext: _additionalContextController.text.trim()
                                    ).then((_) {
                                      // Success! Close dialog
                                      Navigator.pop(dialogContext);
                                      
                                      // Show success message
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Thank you for your report. We will review it shortly.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }).catchError((e) {
                                      if (context.mounted && dialogContext.mounted) {
                                        // Close dialog on error
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error reporting ${isReply ? 'reply' : 'comment'}: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    });
                                  },
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Report',
                                    style: TextStyle(color: Colors.red),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
} 