import 'package:flutter/material.dart';
import 'community_post.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  const CommunityPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundImage: NetworkImage(post.avatarUrl)),
              const SizedBox(width: 8),
              Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(post.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Icon(Icons.comment, size: 16),
              const SizedBox(width: 4),
              Text('${post.comments.length}'),
            ]),
          ],
        ),
      ),
    );
  }
}
