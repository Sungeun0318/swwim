import 'package:flutter/material.dart';
import 'package:swim/common/community/models/community_post.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onCommentsUpdated;
  const PostDetailScreen({Key? key, required this.post, required this.onCommentsUpdated}) : super(key: key);
  @override State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  @override void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  void _addComment() {
    final t = _commentController.text.trim();
    if (t.isEmpty) return;
    setState(() => widget.post.comments.add(t));
    widget.onCommentsUpdated();
    _commentController.clear();
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시물 상세')),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.post.avatarUrl)),
            const SizedBox(width: 8),
            Text(widget.post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(widget.post.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.post.content),
          const SizedBox(height: 12),
          Row(children: [const Icon(Icons.comment), const SizedBox(width: 4), Text('${widget.post.comments.length} comments')]),
          const Divider(height: 32),
          const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...widget.post.comments.map((c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('- $c'))),
        ]))),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [
          Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: '댓글을 입력하세요'))),
          IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
        ])),
      ]),
    );
  }
}
