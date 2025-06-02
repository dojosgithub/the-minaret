import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../services/api_service.dart';
import '../utils/time_utils.dart';
import '../screens/profile_screen.dart';

class RepostContent extends StatefulWidget {
  final Map<String, dynamic> originalPost;
  final String authorId;

  const RepostContent({
    super.key,
    required this.originalPost,
    required this.authorId,
  });

  @override
  State<RepostContent> createState() => _RepostContentState();
}

class _RepostContentState extends State<RepostContent> {
  final List<bool> _loadingImages = [];

  @override
  void initState() {
    super.initState();
    _initializeImageLoading();
  }

  void _initializeImageLoading() {
    // Initialize all images as loading by default
    _loadingImages.clear();
    if (widget.originalPost['media'] != null) {
      for (int i = 0; i < widget.originalPost['media'].length; i++) {
        _loadingImages.add(true); // Set to true to load images automatically
      }
    }
  }

  @override
  void didUpdateWidget(RepostContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalPost['media']?.length != widget.originalPost['media']?.length) {
      _initializeImageLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalPost = widget.originalPost;
    final originalAuthor = originalPost['author'];
    // Use the same time format as in posts
    final timeAgo = getTimeAgo(DateTime.parse(originalPost['createdAt']));

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF4F245A), // Slightly lighter than the parent post
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDCC87).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original post author and time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (originalAuthor['_id'] != widget.authorId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          userId: originalAuthor['_id'],
                        ),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: originalAuthor['profileImage'] != null
                      ? NetworkImage(ApiService.resolveImageUrl(originalAuthor['profileImage']))
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (originalAuthor['_id'] != widget.authorId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: originalAuthor['_id'],
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originalAuthor['firstName'] != null && originalAuthor['lastName'] != null
                            ? '${originalAuthor['firstName']} ${originalAuthor['lastName']}'
                            : originalAuthor['username'] ?? 'Unknown User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${originalAuthor['username']}',
                        style: const TextStyle(
                          color: Color(0xFFFDCC87),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // Original post content
          if (originalPost['title'] != null && originalPost['title'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                originalPost['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          if (originalPost['body'] != null && originalPost['body'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                originalPost['body'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          // Original post media
          if (originalPost['media'] != null && originalPost['media'].isNotEmpty)
            _buildMediaGrid(originalPost['media']),
          // Original post links
          if (originalPost['links'] != null && originalPost['links'].isNotEmpty)
            _buildLinks(originalPost['links']),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<dynamic> media) {
    if (media.isEmpty) return const SizedBox.shrink();

    if (media.length == 1) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            ApiService.resolveImageUrl(media[0]['url']),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                width: double.infinity,
                height: 150,
                child: Container(
                  color: const Color(0xFF4F245A),
                  padding: const EdgeInsets.all(8),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Color(0xFFFDCC87), size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Color(0xFFFDCC87),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: media.length > 4 ? 4 : media.length,
      itemBuilder: (context, index) {
        final bool isLastItem = index == 3 && media.length > 4;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ApiService.resolveImageUrl(media[index]['url']),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDCC87)),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF4F245A),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Color(0xFFFDCC87), size: 16),
                          SizedBox(height: 4),
                          Text(
                            'Image not found',
                            style: TextStyle(
                              color: Color(0xFFFDCC87),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isLastItem)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Text(
                    '+${media.length - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLinks(List<dynamic> links) {
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: links.map((link) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: InkWell(
            onTap: () => _launchURL(link['url']),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F245A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDCC87), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFFFDCC87)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link['title'] ?? link['url'],
                      style: const TextStyle(
                        color: Color(0xFFFDCC87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      // Ensure the URL has a scheme
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      // Try to launch the URL
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // Show error message to user if context is available
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }
} 