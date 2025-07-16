import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post.dart';
import 'community_post_card.dart';

class CommunityPostList extends StatelessWidget {
  final String searchQuery;
  final bool onlyMine;
  const CommunityPostList({Key? key, required this.searchQuery, required this.onlyMine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_posts')
        .orderBy('createdAt', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: \n${snapshot.error.toString()}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('데이터 없음'));
        }
        final posts = snapshot.data!.docs.map((doc) => CommunityPost.fromJson(doc.data() as Map<String, dynamic>, id: doc.id)).toList();
        final filtered = searchQuery.isEmpty
            ? posts
            : posts.where((p) => p.title.contains(searchQuery) || p.content.contains(searchQuery)).toList();
        final display = onlyMine && user != null
            ? filtered.where((p) => p.author == user.displayName || p.author == user.email || p.author == user.uid).toList()
            : filtered;
        if (display.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          itemCount: display.length,
          itemBuilder: (ctx, i) => CommunityPostCardStyled(post: display[i]),
        );
      },
    );
  }
} 