// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/swimming_pool_selector.dart';
import '../widgets/swimming_pool_search.dart';
import '../widgets/user_stats_widget.dart';
import '../../training/training_selection/training_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedPoolName;
  Map<String, dynamic>? selectedPool;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSelectedPool();
  }

  Future<void> _loadUserSelectedPool() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['selectedPool'] != null) {
        setState(() {
          selectedPool = Map<String, dynamic>.from(doc.data()!['selectedPool']);
          selectedPoolName = selectedPool!['name'];
        });
      }
    } catch (e) {
      print('사용자 수영장 정보 로드 실패: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectPool(Map<String, dynamic> pool) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'selectedPool': pool});

      setState(() {
        selectedPool = pool;
        selectedPoolName = pool['name'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pool['name']}이(가) 선택되었습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수영장 선택에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // S.png 로고
            Image.asset(
              'assets/images/S.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            // Swimming Starter 텍스트를 가운데 정렬
            Expanded(
              child: Column(
                children: const [
                  Text(
                    'Swimming',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Starter',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 왕관 아이콘
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swimming 버튼
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrainingScreen(),
                      ),
                    );
                  },
                  child: const Center(
                    child: Text(
                      'Swimming',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 사용자 통계
            const UserStatsWidget(),

            const SizedBox(height: 30),

            // My Swimming Pool 섹션
            Row(
              children: [
                const Icon(
                  Icons.sports_tennis,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'My Swimming Pool',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 선택된 수영장 또는 수영장 고르기
            SwimmingPoolSelector(
              selectedPool: selectedPool,
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SwimmingPoolSearchScreen(),
                  ),
                );
                if (result != null) {
                  await _selectPool(result);
                }
              },
            ),

            const SizedBox(height: 30),

            // 수영장 검색 섹션
            const Text(
              '수영장 이름, 동네 지역 검색',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            // 검색창
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '수영장 이름, 동네 지역 검색',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SwimmingPoolSearchScreen(),
                    ),
                  );
                },
                readOnly: true,
              ),
            ),

            const SizedBox(height: 30),

            // 우리동네 수영장 섹션
            Row(
              children: [
                const Text(
                  '우리동네 수영장',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 수영장 목록 (현재는 예시)
            Column(
              children: [
                _buildPoolListItem('자유수영', '수영장'),
                _buildPoolListItem('헬스', '헬스장'),
                _buildPoolListItem('골프', '골프장'),
                _buildPoolListItem('탁구', '탁구장'),
                _buildPoolListItem('클라이밍', '클라이밍'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolListItem(String name, String category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            category,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}