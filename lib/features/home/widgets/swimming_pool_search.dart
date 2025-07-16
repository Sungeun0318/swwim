// lib/features/home/widgets/swimming_pool_search.dart - 완전한 코드
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/places_service.dart';

class SwimmingPoolSearch extends StatefulWidget {
  const SwimmingPoolSearch({super.key});

  @override
  State<SwimmingPoolSearch> createState() => _SwimmingPoolSearchState();
}

class _SwimmingPoolSearchState extends State<SwimmingPoolSearch> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();

  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allPools = [];
  bool _isLoading = false;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadNearbyPools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
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
            const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

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
    if (_currentPosition == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final pools = await _placesService.searchNearbyPools(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 15000, // 15km 반경
      );

      if (mounted) {
        setState(() {
          _allPools = pools;
          _searchResults = pools;
          _isLoading = false;
        });
      }

      await _updateMarkers();
      print('수영장 검색 완료: ${pools.length}개');
    } catch (e) {
      print('수영장 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateMarkers() async {
    if (_currentPosition == null) return;

    final Set<Marker> markers = {};

    // 수영장 마커들
    for (int i = 0; i < _searchResults.length; i++) {
      final pool = _searchResults[i];
      if (pool['lat'] != null && pool['lng'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId(pool['place_id']?.toString() ?? pool['name'].toString()),
            position: LatLng(
                (pool['lat'] as num).toDouble(),
                (pool['lng'] as num).toDouble()
            ),
            infoWindow: InfoWindow(
              title: pool['name']?.toString() ?? '수영장',
              snippet: '${((pool['distance'] as num?) ?? 0) / 1000}km • ⭐${pool['rating'] ?? 0}',
            ),
            onTap: () => _selectPool(pool),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }

    // 현재 위치 마커
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '현재 위치'),
      ),
    );

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<void> _searchByKeyword(String keyword) async {
    if (keyword.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = _allPools;
        });
      }
      await _updateMarkers();
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      List<Map<String, dynamic>> results = [];

      if (_currentPosition != null) {
        // Google Places API로 텍스트 검색
        final apiResults = await _placesService.searchPoolsByText(
          query: keyword,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
        results.addAll(apiResults);

        // 로컬 데이터에서도 검색
        final lowercaseKeyword = keyword.toLowerCase();
        final localResults = _allPools.where((pool) {
          final name = (pool['name']?.toString() ?? '').toLowerCase();
          final address = (pool['address']?.toString() ?? '').toLowerCase();

          return name.contains(lowercaseKeyword) || address.contains(lowercaseKeyword);
        }).toList();

        results.addAll(localResults);

        // 중복 제거 (place_id 기준)
        final uniqueResults = <String, Map<String, dynamic>>{};
        for (var result in results) {
          final key = result['place_id']?.toString() ?? result['name']?.toString() ?? 'unknown';
          if (!uniqueResults.containsKey(key)) {
            uniqueResults[key] = result;
          }
        }

        // 거리순 정렬
        final finalResults = uniqueResults.values.toList();
        finalResults.sort((a, b) {
          final distanceA = (a['distance'] as num?) ?? 0;
          final distanceB = (b['distance'] as num?) ?? 0;
          return distanceA.compareTo(distanceB);
        });

        if (mounted) {
          setState(() {
            _searchResults = finalResults;
            _isLoading = false;
          });
        }

        await _updateMarkers();
        print('검색 완료: ${finalResults.length}개 결과');
      }
    } catch (e) {
      print('검색 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectPool(Map<String, dynamic> pool) {
    // 수영장 선택 시 이전 화면으로 데이터 전달
    Navigator.pop(context, pool);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수영장 검색'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '수영장 이름, 지역을 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchByKeyword('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
              ),
              onChanged: _searchByKeyword,
            ),
          ),

          // 지도/리스트 전환 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap = true),
                    icon: Icon(Icons.map, size: 20),
                    label: const Text('지도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showMap ? Colors.blue : Colors.grey.shade200,
                      foregroundColor: _showMap ? Colors.white : Colors.grey.shade600,
                      elevation: _showMap ? 2 : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap = false),
                    icon: Icon(Icons.list, size: 20),
                    label: const Text('리스트'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showMap ? Colors.blue : Colors.grey.shade200,
                      foregroundColor: !_showMap ? Colors.white : Colors.grey.shade600,
                      elevation: !_showMap ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 결과 수 표시
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '검색 결과: ${_searchResults.length}개',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // 지도 또는 리스트 표시
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('수영장을 검색하는 중...'),
                ],
              ),
            )
                : _showMap
                ? _buildMapView()
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: Text('위치 정보를 가져올 수 없습니다'),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 13,
      ),
      markers: _markers,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildListView() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 키워드로 검색해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pool = _searchResults[index];
        return _buildPoolCard(pool);
      },
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool) {
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
      child: InkWell(
        onTap: () => _selectPool(pool),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 수영장 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pool['name'] ?? '수영장',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (pool['distance'] != null)
                    Text(
                      '${(pool['distance'] / 1000).toStringAsFixed(1)}km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    pool['address'] ?? pool['vicinity'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
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
                      // 수영장 타입 표시
                      if (pool['types'] != null && pool['types'].isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (pool['types'] as List).first.toString()
                                .replaceAll('_', ' ')
                                .replaceAll('swimming pool', '수영장')
                                .replaceAll('gym', '헬스장'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 선택 버튼
            Column(
              children: [
                IconButton(
                  onPressed: () => _selectPool(pool),
                  icon: Icon(
                    Icons.add_circle,
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                ),
                Text(
                  '선택',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}