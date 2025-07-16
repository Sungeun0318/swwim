import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post.dart';
import '../../more/more_screen.dart';
import 'profile_edit_screen.dart';

/// 프로필 상단 정보 및 버튼 위젯 모음
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback? onAddPost;
  final VoidCallback? onDM;
  final VoidCallback? onSwimMateList;
  const ProfileHeader({Key? key, this.userData, required this.onEdit, required this.onShare, this.onAddPost, this.onDM, this.onSwimMateList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nickname = userData?['nickname'] ?? '닉네임';
    final avatarUrl = userData?['avatarUrl'] ?? '';
    final interests = List<String>.from(userData?['interests'] ?? []);
    final bio = userData?['bio'] ?? '';
    final followers = userData?['followersCount'] ?? 0;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0061A8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 44, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 버튼
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MoreScreen()));
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_box_rounded, color: Colors.white, size: 28),
                onPressed: onAddPost,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                onPressed: onDM,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B94A3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40, color: Colors.white);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname, style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    if (interests.isNotEmpty)
                      Text('[${interests.join(' | ')}]', style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(bio, style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 14, color: Colors.white), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onSwimMateList,
                    child: Text('스윔메이트 $followers명', style: const TextStyle(fontFamily: 'MyCustomFont', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 2),
                  //Text('$followers명', style: const TextStyle(fontFamily: 'MyCustomFont', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 프로필 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0061A8), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onEdit,
                  child: const Text('프로필 편집', style: TextStyle(fontFamily: 'MyCustomFont', color: Color(0xFF0061A8), fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0061A8), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onShare,
                  child: const Text('프로필 공유', style: TextStyle(fontFamily: 'MyCustomFont', color: Color(0xFF0061A8), fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 