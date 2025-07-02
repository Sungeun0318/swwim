// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/swimming_pool_selector.dart';
import '../widgets/swimming_pool_search.dart';
import '../../swimming/screens/swimming_main_screen.dart'; // 수정된 import

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedPoolName;
  Map<String, dynamic>? selectedPool;
  List<Map<String, dynamic>> nearbyPools = []; // 주변 수영장 목록
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSelectedPool();
    _loadNearbyPools(); // 주변 수영장 로드
  }

  Future<void> _loadNearbyPools() async {
    try {
      // Firebase에서 주변 수영장 데이터 로드
      final snapshot = await FirebaseFirestore.instance
          .collection('swimming_pools')
          .where('area', isEqualTo: '수원시') // 예시: 지역별 필터
          .limit(10)
          .get();

      final pools = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '수영장',
          'address': data['address'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'rating': data['rating'] ?? 0.0,
          'distance': data['distance'] ?? 0,
          'facilities': data['facilities'] ?? [],
        };
      }).toList();

      setState(() {
        nearbyPools = pools;
      });
    } catch (e) {
      print('주변 수영장 로드 실패: $e');
      // 오류 시 더미 데이터 사용
      setState(() {
        nearbyPools = [
          {
            'id': 'dummy1',
            'name': '올림픽수영장',
            'address': '수원시 영통구',
            'imageUrl': '',
            'rating': 4.5,
            'distance': 1200,
            'facilities': ['자유수영', '강습', '주차장'],
          },
          {
            'id': 'dummy2',
            'name': '시민수영장',
            'address': '수원시 팔달구',
            'imageUrl': '',
            'rating': 4.2,
            'distance': 800,
            'facilities': ['자유수영', '아쿠아로빅'],
          },
        ];
      });
    }
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
      // Firebase 구조에 맞게 데이터 정리
      final poolData = {
        'name': pool['name'],
        'address': pool['address'],
        'imageUrl': pool['imageUrl'] ?? '',
        'rating': pool['rating'] ?? 0.0,
        'facilities': pool['facilities'] ?? [],
        'selectedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'selectedPool': poolData});

      setState(() {
        selectedPool = poolData;
        selectedPoolName = poolData['name'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${poolData['name']}이(가) 선택되었습니다')),
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
            // S.png 로고 (왼쪽 배치)
            Image.asset(
              'assets/images/S.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
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
            // Swimming 버튼 - 직접 SwimmingMainScreen으로 이동
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
                        builder: (context) => const SwimmingMainScreen(), // 직접 이동
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

            // 사용자 통계 제거됨
            // const UserStatsWidget(),

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

            // 우리동네 수영장 목록
            Column(
              children: nearbyPools.map((pool) => _buildPoolListItem(
                pool['name'],
                pool['address'],
                pool['imageUrl'],
                pool['rating'].toDouble(),
                pool['facilities'],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolListItem(
      String name,
      String address,
      String imageUrl,
      double rating,
      List facilities,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 수영장 이미지
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.pool,
                  color: Colors.blue.shade400,
                  size: 30,
                ),
              ),
            )
                : Icon(
              Icons.pool,
              color: Colors.blue.shade400,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // 수영장 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        facilities.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 선택 버튼
          IconButton(
            onPressed: () => _selectPool({
              'name': name,
              'address': address,
              'imageUrl': imageUrl,
              'rating': rating,
              'facilities': facilities,
            }),
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
}