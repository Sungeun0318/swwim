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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('이용범', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('yongb._', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ]),
                GestureDetector(
                  onTap: _openProfile,
                  child: const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=50')),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton(onPressed: () {}, child: const Text('+ 관심사 추가', style: TextStyle(color: Colors.grey))),
                const Spacer(),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('팔로워 ${_posts.length * 1}명', style: const TextStyle(color: Colors.grey,  fontWeight: FontWeight.bold)),
              ],),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('프로필 편집', style: TextStyle(color: Colors.grey)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('프로필 공유', style: TextStyle(color: Colors.grey)))),
              ]),
            ],
          ),
        ),
        // 탭바
        Material(color: Colors.white, child: TabBar(controller: _tabController, labelColor: Colors.black, unselectedLabelColor: Colors.grey, tabs: const [
          Tab(text: '게시글'), Tab(text: '공감'), Tab(text: '팔로우'), Tab(text: '피드'),
        ])),
        // 탭 콘텐츠
        Expanded(child: TabBarView(controller: _tabController, children: [
          ListView.builder(itemCount: _posts.length, itemBuilder: (ctx,i)=>CommunityPostCard(post: _posts[i])),
          ListView(children: _posts.where((p)=>p.comments.isNotEmpty).map((p)=>ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(p.avatarUrl)),
            title: Text(p.title),
            subtitle: Text('${p.comments.length}개의 댓글'),
          )).toList()),
          const FollowersScreen(),
          ListView.builder(itemCount: _posts.length, itemBuilder:(ctx,i)=>ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(_posts[i].avatarUrl)),
            title: Text(_posts[i].author),
            subtitle: Text(_posts[i].content, maxLines:2, overflow: TextOverflow.ellipsis),
          )),
        ])),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _createNewPost, child: const Icon(Icons.add)),
    );
  }
}
