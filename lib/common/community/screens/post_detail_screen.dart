import 'package:flutter/material.dart';
import 'package:swim/common/community/models/community_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  void _addComment() async {
    final t = _commentController.text.trim();
    if (t.isEmpty) return;
    // 현재 유저 닉네임 가져오기 (없으면 '익명')
    String nickname = '익명';
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (snap.exists && snap.data() != null && snap.data()!['nickname'] != null) {
        nickname = snap.data()!['nickname'];
      }
    }
    setState(() => widget.post.comments.add(Comment(author: nickname, content: t)));
    widget.onCommentsUpdated();
    _commentController.clear();
    // Firestore에 댓글 반영
    final query = await FirebaseFirestore.instance.collection('community_posts')
      .where('title', isEqualTo: widget.post.title)
      .where('author', isEqualTo: widget.post.author)
      .limit(1).get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      await doc.reference.update({'comments': widget.post.comments.map((c) => c.toJson()).toList()});
    }
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
          ...widget.post.comments.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('${c.author}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(c.content)),
              ],
            ),
          )),
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
