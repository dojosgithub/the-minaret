import 'package:flutter/material.dart';

class RepostContent extends StatelessWidget {
  final Map<String, dynamic> originalPost;
  final VoidCallback onAuthorTap;
  final String? currentUserId;

  const RepostContent({
    super.key,
    required this.originalPost,
    required this.onAuthorTap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final author = originalPost['author'];
    final isCurrentUser = currentUserId == author['_id'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4F245A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDCC87), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original author info
          GestureDetector(
            onTap: () {
              if (isCurrentUser) {
                // Don't navigate if it's the current user
                return;
              }
              onAuthorTap();
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFDCC87),
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(author['profileImage']),
                    radius: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${author['firstName']} ${author['lastName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${author['username']}',
                      style: const TextStyle(
                        color: Color(0xFFFDCC87),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Original post content
          Text(
            originalPost['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            originalPost['body'],
            style: const TextStyle(
              color: Colors.white,
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
            media[0]['url'],
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
                color: Colors.grey[300],
                child: const Icon(Icons.error),
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
                media[index]['url'],
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
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            if (isLastItem)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+${media.length - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: links.map((link) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3D1B45),
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
        );
      }).toList(),
    );
  }
} 