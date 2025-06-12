import 'package:flutter/material.dart';
import 'package:swim/common/community/models/community_post.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({Key? key}) : super(key: key);
  @override State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  @override void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 게시물 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: '제목')),
          const SizedBox(height: 12),
          TextField(controller: _contentController, decoration: const InputDecoration(labelText: '내용'), maxLines: 5),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {
            final t = _titleController.text.trim();
            final c = _contentController.text.trim();
            if (t.isEmpty || c.isEmpty) return;
            Navigator.pop(context, CommunityPost(author: 'Me', avatarUrl: 'https://i.pravatar.cc/150?img=100', title: t, content: c));
          }, child: const Text('등록')),
        ]),
      ),
    );
  }
}
