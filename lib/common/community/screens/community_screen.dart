import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swim/common/community/models/community_post.dart';
import 'package:swim/common/community/models/community_post_card.dart';
import 'new_post_screen.dart';
import 'followers_screen.dart';
import 'search_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_detail_screen.dart';
import 'profile_edit_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);
  @override State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPosts();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('posts');
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        _posts = list.map((e) => CommunityPost.fromJson(e)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('posts', jsonEncode(_posts.map((e) => e.toJson()).toList()));
  }

  void _openFollowers() => Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowersScreen()));
  void _openProfile()   => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  void _openSearch()    => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
  void _openMessages()  => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
  Future<void> _createNewPost() async {
    final newPost = await Navigator.push<CommunityPost>(
        context, MaterialPageRoute(builder: (_) => const NewPostScreen()));
    if (newPost != null) {
      setState(() => _posts.insert(0, newPost));
      await _savePosts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 등록되었습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 1,
        leading: IconButton(icon: const Icon(Icons.public, color: Colors.black), onPressed: _openFollowers),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: _openSearch),
          IconButton(icon: const Icon(Icons.send,   color: Colors.black), onPressed: _openMessages),
          IconButton(icon: const Icon(Icons.add_box,color: Colors.black), onPressed: _createNewPost),
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        // 프로필 헤더
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
            : null,
          builder: (context, snapshot) {
            final userData = snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>
                : null;
            final nickname = userData?['nickname'] ?? '이름 없음';
            final username = userData?['username'] ?? '@username';
            final avatarUrl = userData?['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=50';
            final interests = List<String>.from(userData?['interests'] ?? []);

            return Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(username, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ]),
                    GestureDetector(
                      onTap: _openProfile,
                      child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatarUrl)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      ...interests.map((interest) => Chip(label: Text(interest), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
                      ActionChip(
                        label: const Text('+'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    // Firestore 글 개수 기준 팔로워 수
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('community_posts').snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Text('팔로워 ${count}명', style: const TextStyle(color: Colors.grey,  fontWeight: FontWeight.bold));
                      },
                    ),
                  ],),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())), child: const Text('프로필 편집', style: TextStyle(color: Colors.grey)))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('프로필 공유', style: TextStyle(color: Colors.grey)))),
                  ]),
                ],
              ),
            );
          }
        ),
        // 탭바
        Material(color: Colors.white, child: TabBar(controller: _tabController, labelColor: Colors.black, unselectedLabelColor: Colors.grey, tabs: const [
          Tab(text: '게시글'), Tab(text: '공감'), Tab(text: '팔로우'), Tab(text: '피드'),
        ])),
        // 탭 콘텐츠
        Expanded(child: TabBarView(controller: _tabController, children: [
          // 게시글 탭: Firestore 실시간 연동
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('community_posts').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final posts = snapshot.data!.docs.map((doc) => CommunityPost.fromJson(doc.data() as Map<String, dynamic>)).toList();
              if (posts.isEmpty) {
                return const Center(child: Text('아직 게시물이 없습니다.')); 
              }
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (ctx,i)=>GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: posts[i], onCommentsUpdated: () {}),
                    ));
                  },
                  child: CommunityPostCard(post: posts[i]),
                ),
              );
            },
          ),
          // 공감 탭: 댓글 있는 글만
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('community_posts').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final posts = snapshot.data!.docs.map((doc) => CommunityPost.fromJson(doc.data() as Map<String, dynamic>)).where((p)=>p.comments.isNotEmpty).toList();
              return ListView(children: posts.map((p)=>ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(p.avatarUrl)),
                title: Text(p.title),
                subtitle: Text('${p.comments.length}개의 댓글'),
              )).toList());
            },
          ),
          // 팔로우 탭(임시): 기존 화면 유지
          const FollowersScreen(),
          // 피드 탭: 전체 글 요약
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('community_posts').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final posts = snapshot.data!.docs.map((doc) => CommunityPost.fromJson(doc.data() as Map<String, dynamic>)).toList();
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder:(ctx,i)=>ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(posts[i].avatarUrl)),
                  title: Text(posts[i].author),
                  subtitle: Text(posts[i].content, maxLines:2, overflow: TextOverflow.ellipsis),
                ),
              );
            },
          ),
        ])),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _createNewPost, child: const Icon(Icons.add)),
    );
  }
}
