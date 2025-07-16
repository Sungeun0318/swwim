import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// 커뮤니티 게시글 카드 (좋아요/댓글/공유/더보기 메뉴 포함)
class CommunityPostCardStyled extends StatefulWidget {
  final CommunityPost post;
  const CommunityPostCardStyled({Key? key, required this.post}) : super(key: key);

  @override
  State<CommunityPostCardStyled> createState() => _CommunityPostCardStyledState();
}

class _CommunityPostCardStyledState extends State<CommunityPostCardStyled> {
  bool _isLiked = false;
  int _likeCount = 0;
  int _shareCount = 0;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likes;
    _shareCount = widget.post.shares;
    _comments = List<Comment>.from(widget.post.comments);
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.post.id);
    final doc = await postRef.get();
    final likedUserIds = (doc.data()?['likedUserIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    setState(() {
      _isLiked = likedUserIds.contains(user.uid);
    });
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.post.id);
    final doc = await postRef.get();
    final likedUserIds = (doc.data()?['likedUserIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final isLiked = likedUserIds.contains(user.uid);
    if (!isLiked) {
      await postRef.update({
        'likedUserIds': FieldValue.arrayUnion([user.uid]),
        'likes': FieldValue.increment(1),
      });
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    } else {
      await postRef.update({
        'likedUserIds': FieldValue.arrayRemove([user.uid]),
        'likes': FieldValue.increment(-1),
      });
      setState(() {
        _isLiked = false;
        _likeCount = _likeCount > 0 ? _likeCount - 1 : 0;
      });
    }
  }

  void _incrementShare() async {
    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.post.id);
    await postRef.update({'shares': _shareCount + 1});
    setState(() {
      _shareCount++;
    });
    _showShareOptions();
  }

  void _showComments() {
    final TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: Row(
                  children: [
                    const Text('댓글', style: TextStyle(fontFamily: 'MyCustomFont', fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B94A3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.author,
                                  style: const TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.only(left: 12, right: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 8, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(hintText: '댓글을 입력하세요'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final text = _commentController.text.trim();
                        if (text.isNotEmpty) {
                          _addCommentFirestore(text, setModalState);
                          _commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addCommentFirestore(String text, StateSetter setModalState) async {
    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.post.id);
    final newComment = Comment(author: 'Me', content: text).toJson();
    await postRef.update({
      'comments': FieldValue.arrayUnion([newComment])
    });
    setModalState(() {
      _comments.add(Comment.fromJson(newComment));
    });
    setState(() {
      _comments = List<Comment>.from(_comments);
    });
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('공유하기', style: TextStyle(fontFamily: 'MyCustomFont', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, '복사', () async {
                  final url = 'https://yourapp.com/post/${widget.post.id}';
                  await Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크가 복사되었습니다.')));
                }),
                _buildShareOption(Icons.share, '공유', () async {
                  final url = 'https://yourapp.com/post/${widget.post.id}';
                  await Share.share('게시글을 공유합니다: $url');
                  Navigator.pop(context);
                }),
                _buildShareOption(Icons.bookmark_border, '저장', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 저장되었습니다. (예시)')));
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 12)),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}초 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  Widget _buildPostMenu(CommunityPost post) {
    final user = FirebaseAuth.instance.currentUser;
    final isMine = user != null && (post.author == user.displayName || post.author == user.email || post.author == user.uid);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.black, size: 24),
      onSelected: (value) async {
        if (isMine) {
          if (value == 'edit') {
            // TODO: 수정 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정 기능은 추후 지원됩니다.')));
          } else if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('게시글 삭제'),
                content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              await FirebaseFirestore.instance.collection('community_posts').doc(post.id).delete();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
            }
          }
        } else {
          if (value == 'report') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
          } else if (value == 'block') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('해당 사용자가 차단되었습니다. (예시)')));
          }
        }
      },
      itemBuilder: (context) => isMine
          ? [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
            ]
          : [
              const PopupMenuItem(value: 'report', child: Text('신고')),
              const PopupMenuItem(value: 'block', child: Text('차단')),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B94A3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: post.avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          post.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 22, color: Colors.white);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author, style: const TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
              // 시간 표시
              Text(_formatTimeAgo(post.createdAt), style: const TextStyle(color: Color(0xFF8B94A3), fontSize: 13)),
              const SizedBox(width: 4),
              // 수정/삭제/신고/차단 메뉴
              _buildPostMenu(post),
            ],
          ),
          const SizedBox(height: 10),
          if (post.title.isNotEmpty)
            Text(post.title, style: const TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black)),
          if (post.title.isNotEmpty) const SizedBox(height: 4),
          Text(post.content, style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 16, color: Colors.black)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await _toggleLike();
                },
                child: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 2),
              Text('$_likeCount', style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 15)),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: _showComments,
                child: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 2),
              Text('${_comments.length}', style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 15)),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: _incrementShare,
                child: const Icon(Icons.reply, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 2),
              Text('$_shareCount', style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
} 