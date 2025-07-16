import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swim/models/stat_item.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('프로필')),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('프로필이 없습니다. 생성해주세요.'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                      ).then((_) => setState(() {}));
                    },
                    child: const Text('프로필 생성'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final interests = List<String>.from(data['interests'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(data['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=50'),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(data['nickname'] ?? '이름 없음', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Center(child: Text(data['username'] ?? '@username', style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 8),
              Center(child: Text(data['bio'] ?? '', textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatItem(count: data['postCount'] ?? 0, label: '게시물'),
                  StatItem(count: data['followersCount'] ?? 0, label: '팔로워'),
                  StatItem(count: data['followingCount'] ?? 0, label: '팔로잉'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('관심사', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: interests.map((interest) => Chip(label: Text(interest))).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
