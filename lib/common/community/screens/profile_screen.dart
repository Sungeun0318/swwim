import 'package:flutter/material.dart';
import 'package:swim/models/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=50')),
            const SizedBox(height: 12),
            const Text('이용범', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('yonb._', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            // 2) children 리스트에서 const 제거 (또는 아이템마다 const)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                StatItem(count: 12, label: '게시물'),
                StatItem(count: 34, label: '팔로워'),
                StatItem(count: 45, label: '팔로잉'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('프로필 편집')),
          ],
        ),
      ),
    );
  }
}
