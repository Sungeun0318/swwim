// lib/features/home/widgets/swimming_pool_search.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/places_service.dart';

class SwimmingPoolSearchScreen extends StatefulWidget {
  const SwimmingPoolSearchScreen({Key? key}) : super(key: key);

  @override
  State<SwimmingPoolSearchScreen> createState() => _SwimmingPoolSearchScreenState();
}

class _SwimmingPoolSearchScreenState extends State<SwimmingPoolSearchScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();

  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      await _searchNearbyPools();
    } catch (e) {
      if (kDebugMode) {
        print('위치 가져오기 오류: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 가져올 수 없습니다')),
        );
      }
    }
  }

  Future<void> _searchNearbyPools() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pools = await _placesService.searchNearbyPools(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 5000,
      );

      if (kDebugMode) {
        print('검색된 수영장 수: ${pools.length}');
      }

      setState(() {
        _searchResults = pools;
        _markers = pools.map((pool) {
          return Marker(
            markerId: MarkerId(pool['place_id'] ?? pool['name']),
            position: LatLng(pool['lat'], pool['lng']),
            infoWindow: InfoWindow(
              title: pool['name'],
              snippet: pool['address'],
            ),
            onTap: () => _selectPool(pool),
          );
        }).toSet();

        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '현재 위치'),
          ),
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('수영장 검색 오류: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수영장 검색에 실패했습니다')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchByKeyword(String keyword) async {
    if (keyword.trim().isEmpty || _currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _placesService.searchPoolsByText(
        query: keyword,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _searchResults = results;
        _markers = results.map((pool) {
          return Marker(
            markerId: MarkerId(pool['place_id'] ?? pool['name']),
            position: LatLng(pool['lat'], pool['lng']),
            infoWindow: InfoWindow(
              title: pool['name'],
              snippet: pool['address'],
            ),
            onTap: () => _selectPool(pool),
          );
        }).toSet();
      });
    } catch (e) {
      if (kDebugMode) {
        print('검색 오류: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPool(Map<String, dynamic> pool) {
    if (kDebugMode) {
      print('선택된 수영장: ${pool['name']}');
      print('사진 URL: ${pool['photo_url']}');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 수영장 사진
            if (pool['photo_url'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  child: Image.network(
                    pool['photo_url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      if (kDebugMode) {
                        print('이미지 로드 오류: $error');
                      }
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pool, size: 48, color: Colors.blue),
                              SizedBox(height: 8),
                              Text('수영장 이미지', style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // 사진이 없을 때 기본 아이콘 표시
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pool, size: 64, color: Colors.blue),
                      SizedBox(height: 12),
                      Text(
                        '수영장',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              pool['name'] ?? '수영장',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (pool['address'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pool['address'],
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                if (pool['distance'] != null) ...[
                  const Icon(Icons.directions_walk, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${pool['distance']}m'),
                  const SizedBox(width: 20),
                ],
                if (pool['rating'] != null && pool['rating'] > 0) ...[
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text('${pool['rating']}'),
                ],
              ],
            ),

            if (pool['phone'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(pool['phone']),
                ],
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (kDebugMode) {
                    print('수영장 선택 완료: ${pool['name']}');
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${pool['name']}이(가) 선택되었습니다!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  Navigator.pop(context); // 바텀시트 닫기
                  Navigator.pop(context, pool); // 선택된 수영장 반환
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '이 수영장 선택하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수영장 검색'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색창
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '수영장 이름이나 지역을 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchNearbyPools();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onSubmitted: _searchByKeyword,
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: _showMap ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('위치 정보를 가져오는 중...'),
          ],
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildListView() {
    if (_searchResults.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pool = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectPool(pool),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 수영장 사진
                if (pool['photo_url'] != null) ...[
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      child: Image.network(
                        pool['photo_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.blue.shade100,
                            child: const Center(
                              child: Icon(Icons.pool, size: 48, color: Colors.blue),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Center(
                      child: Icon(Icons.pool, size: 48, color: Colors.blue),
                    ),
                  ),
                ],

                // 수영장 정보
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pool['name'] ?? '수영장',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pool['address'] ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (pool['distance'] != null) ...[
                                Icon(Icons.directions_walk, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${pool['distance']}m',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                              ],
                              if (pool['rating'] != null && pool['rating'] > 0) ...[
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${pool['rating']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}