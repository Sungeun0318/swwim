// lib/features/home/screens/home_screen.dart - Google Places API 사용
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/swimming_pool_selector.dart';
import '../widgets/swimming_pool_search.dart';
import '../../swimming/screens/swimming_main_screen.dart';
import '../../../services/places_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedPoolName;
  Map<String, dynamic>? selectedPool;
  List<Map<String, dynamic>> nearbyPools = [];
  bool isLoading = true;
  Position? _currentPosition;
  final PlacesService _placesService = PlacesService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    await _loadUserSelectedPool();
    await _loadNearbyPools();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 서비스를 활성화해주세요')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('위치 권한이 필요합니다')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('설정에서 위치 권한을 허용해주세요')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });

      print('현재 위치: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('위치 가져오기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 가져올 수 없습니다')),
        );
      }
    }
  }

  Future<void> _loadNearbyPools() async {
    if (_currentPosition == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('Google Places API로 주변 수영장 검색 중...');

      final pools = await _placesService.searchNearbyPools(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 10000, // 10km 반경
      );

      setState(() {
        nearbyPools = pools;
        isLoading = false;
      });

      if (PlacesService.isApiKeyConfigured) {
        print('Google Places API로 ${pools.length}개 수영장 검색 완료');
      } else {
        print('API 키 미설정 - 로컬 데이터 ${pools.length}개 사용');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Places API 키를 설정하면 실제 수영장 데이터를 검색할 수 있습니다'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('수영장 검색 실패: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수영장 검색에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _loadUserSelectedPool() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userDocRef.get();

      if (!doc.exists) {
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'selectedPool': null,
          'favoritePools': [],
        });
        print('새 사용자 문서 생성: ${user.uid}');
      } else if (doc.data()?['selectedPool'] != null) {
        setState(() {
          selectedPool = Map<String, dynamic>.from(doc.data()!['selectedPool']);
          selectedPoolName = selectedPool!['name'];
        });
      }
    } catch (e) {
      print('사용자 수영장 정보 로드 실패: $e');
    }
  }

  Future<void> _selectPool(Map<String, dynamic> pool) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Google Places API에서 상세 정보 가져오기 시도
      Map<String, dynamic>? details;
      if (pool['place_id'] != null && PlacesService.isApiKeyConfigured) {
        details = await _placesService.getPlaceDetails(pool['place_id']);
      }

      final poolData = {
        'id': pool['place_id'] ?? pool['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': pool['name'],
        'address': pool['address'] ?? pool['vicinity'] ?? '',
        'imageUrl': pool['photo_url'] ?? '',
        'rating': (pool['rating'] ?? 0.0).toDouble(),
        'lat': pool['lat'],
        'lng': pool['lng'],
        'distance': pool['distance'] ?? 0,
        'types': pool['types'] ?? [],
        'user_ratings_total': pool['user_ratings_total'] ?? 0,
        'phone': details?['formatted_phone_number'] ?? '',
        'website': details?['website'] ?? '',
        'opening_hours': details?['opening_hours'] ?? {},
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${poolData['name']}이(가) 선택되었습니다')),
        );
      }
    } catch (e) {
      print('수영장 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수영장 선택에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/S.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            // API 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: PlacesService.isApiKeyConfigured
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                PlacesService.isApiKeyConfigured ? 'Live' : 'Demo',
                style: TextStyle(
                  fontSize: 10,
                  color: PlacesService.isApiKeyConfigured
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('주변 수영장을 검색하는 중...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swimming 버튼
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SwimmingMainScreen(),
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

            const SizedBox(height: 30),

            // My Swimming Pool 섹션
            Row(
              children: [
                const Icon(
                  Icons.pool,
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

            // 선택된 수영장 표시
            SwimmingPoolSelector(
              selectedPool: selectedPool,
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SwimmingPoolSearch(),
                  ),
                );
                if (result != null) {
                  await _selectPool(result);
                }
              },
            ),

            const SizedBox(height: 30),

            // 검색 섹션
            Row(
              children: [
                Text(
                  PlacesService.isApiKeyConfigured
                      ? '실시간 수영장 검색'
                      : '수영장 이름, 동네 지역 검색',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                if (PlacesService.isApiKeyConfigured)
                  Icon(
                    Icons.live_tv,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
              ],
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
                  hintText: PlacesService.isApiKeyConfigured
                      ? '구글 맵에서 수영장 검색'
                      : '수영장 이름, 동네 지역 검색',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SwimmingPoolSearch(),
                    ),
                  );
                  if (result != null) {
                    await _selectPool(result);
                  }
                },
                readOnly: true,
              ),
            ),

            const SizedBox(height: 30),

            // 주변 수영장 섹션
            Row(
              children: [
                Text(
                  PlacesService.isApiKeyConfigured ? '주변 수영장' : '데모 수영장',
                  style: const TextStyle(
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
                const SizedBox(width: 4),
                Text(
                  '${nearbyPools.length}개',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadNearbyPools,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 위치 권한 안내
            if (_currentPosition == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '위치 권한을 허용하면 주변 수영장을 검색할 수 있습니다',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('허용하기'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 수영장 목록
            if (nearbyPools.isEmpty && !isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pool_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentPosition == null
                            ? '위치 권한을 허용해주세요'
                            : '주변 수영장을 찾을 수 없습니다',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _currentPosition == null
                            ? _getCurrentLocation
                            : _loadNearbyPools,
                        child: Text(_currentPosition == null ? '위치 허용' : '다시 찾기'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: nearbyPools.map((pool) => _buildPoolListItem(pool)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolListItem(Map<String, dynamic> pool) {
    final hasPhoto = pool['photo_url'] != null && pool['photo_url'].isNotEmpty;
    final isGoogleData = pool['place_id'] != null && !pool['place_id'].toString().startsWith('local_');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGoogleData ? Colors.green.shade200 : Colors.grey.shade200,
          width: isGoogleData ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGoogleData
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 수영장 이미지/아이콘
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isGoogleData ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGoogleData ? Colors.green.shade200 : Colors.blue.shade200,
              ),
            ),
            child: hasPhoto
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pool['photo_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.pool,
                  color: isGoogleData ? Colors.green.shade400 : Colors.blue.shade400,
                  size: 30,
                ),
              ),
            )
                : Icon(
              Icons.pool,
              color: isGoogleData ? Colors.green.shade400 : Colors.blue.shade400,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // 수영장 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pool['name'] ?? '수영장',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (pool['distance'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(pool['distance'] / 1000).toStringAsFixed(1)}km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pool['address'] ?? pool['vicinity'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (pool['rating'] != null && pool['rating'] > 0) ...[
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${pool['rating']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (pool['user_ratings_total'] != null && pool['user_ratings_total'] > 0) ...[
                        Text(
                          ' (${pool['user_ratings_total']})',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                    ],
                    // 데이터 소스 표시
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGoogleData ? Colors.green.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGoogleData ? 'Google' : 'Local',
                        style: TextStyle(
                          fontSize: 10,
                          color: isGoogleData ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 수영장 타입 표시
                if (pool['types'] != null && pool['types'].isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: (pool['types'] as List).take(2).map((type) {
                      String displayType = type.toString()
                          .replaceAll('_', ' ')
                          .replaceAll('swimming pool', '수영장')
                          .replaceAll('gym', '헬스장')
                          .replaceAll('health', '헬스케어');

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayType,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // 선택 버튼
          IconButton(
            onPressed: () => _selectPool(pool),
            icon: Icon(
              Icons.add_circle_outline,
              color: isGoogleData ? Colors.green.shade600 : Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
}