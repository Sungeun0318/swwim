import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class SwimMateListScreen extends StatelessWidget {
  const SwimMateListScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchMateProfiles(List<dynamic> mateUids) async {
    if (mateUids.isEmpty) return [];
    final usersRef = FirebaseFirestore.instance.collection('users');
    final futures = mateUids.map((uid) async {
      final doc = await usersRef.doc(uid).get();
      final data = doc.data();
      if (data != null) {
        return {
          'uid': uid,
          'nickname': data['nickname'] ?? '알 수 없음',
          'avatarUrl': data['avatarUrl'] ?? '',
        };
      } else {
        return {'uid': uid, 'nickname': '알 수 없음', 'avatarUrl': ''};
      }
    }).toList();
    return await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0061A8),
        title: const Text('나의 스윔 메이트', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: \n${snapshot.error.toString()}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final mates = data?['followers'] as List<dynamic>? ?? [];
          if (mates.isEmpty) {
            return const Center(child: Text('아직 스윔메이트가 없습니다.'));
          }
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchMateProfiles(mates),
            builder: (context, mateSnap) {
              if (mateSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final mateProfiles = mateSnap.data ?? [];
              return ListView.builder(
                itemCount: mateProfiles.length,
                itemBuilder: (context, i) {
                  final mate = mateProfiles[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB0B0B0), width: 1),
                    ),
                    child: Row(
                      children: [
                        mate['avatarUrl'] != ''
                            ? CircleAvatar(radius: 22, backgroundImage: NetworkImage(mate['avatarUrl']))
                            : const CircleAvatar(radius: 22, backgroundColor: Color(0xFF8B94A3), child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(mate['nickname'], style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 18)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0061A8)),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatScreen(mateUid: mate['uid'], mateNickname: mate['nickname']),
                            ));
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF7F9FB),
    );
  }
} 