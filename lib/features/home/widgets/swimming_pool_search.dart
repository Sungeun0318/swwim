// lib/features/home/widgets/swimming_pool_search.dart - 오류 수정됨
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/places_service.dart';

class SwimmingPoolSearch extends StatefulWidget {
  const SwimmingPoolSearch({super.key}); // Key? key 제거

  @override
  State<SwimmingPoolSearch> createState() => _SwimmingPoolSearchState();
}

class _SwimmingPoolSearchState extends State<SwimmingPoolSearch> {
  GoogleMapController? _mapController; // 사용하지 않는 변수 유지 (향후 사용 가능)
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
    _mapController?.dispose(); // null 체크 추가
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
            const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      if (kDebugMode) {
        print('현재 위치: ${position.latitude}, ${position.longitude}');
      }
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

  Future<void> _loadNearbyPools() async {
    if (_currentPosition == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (kDebugMode) {
        print('Google Places API로 주변 수영장 검색...');
      }

      final pools = await _placesService.searchNearbyPools(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 15000, // 15km 반경으로 확장
      );

      if (kDebugMode) {
        print('검색된 수영장 수: ${pools.length}');
      }

      if (mounted) {
        setState(() {
          _allPools = pools;
          _searchResults = pools;
        });
      }

      await _updateMarkers();
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateMarkers() async {
    if (_currentPosition == null) return;

    final markers = <Marker>{};

    // 수영장 마커들
    for (var pool in _searchResults) {
      final isGoogleData = pool['place_id'] != null &&
          !pool['place_id'].toString().startsWith('local_');

      markers.add(
        Marker(
          markerId: MarkerId(pool['place_id']?.toString() ?? pool['id']?.toString() ?? pool['name'].toString()),
          position: LatLng(
              (pool['lat'] as num).toDouble(),
              (pool['lng'] as num).toDouble()
          ),
          infoWindow: InfoWindow(
            title: pool['name']?.toString() ?? '수영장',
            snippet: '${((pool['distance'] as num?) ?? 0) / 1000}km • ⭐${pool['rating'] ?? 0} • ${isGoogleData ? 'Google' : 'Local'}',
          ),
          onTap: () => _selectPool(pool),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              isGoogleData ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue
          ),
        ),
      );
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
        if (PlacesService.isApiKeyConfigured) {
          final apiResults = await _placesService.searchPoolsByText(
            query: keyword,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          results.addAll(apiResults);
        }

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
          });
        }

        await _updateMarkers();

        if (kDebugMode) {
          print('검색 결과: ${finalResults.length}개 (키워드: $keyword)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('검색 오류: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectPool(Map<String, dynamic> pool) async {
    if (kDebugMode) {
      print('선택된 수영장: ${pool['name']}');
    }

    // Google Places API에서 상세 정보 가져오기
    Map<String, dynamic>? details;
    if (pool['place_id'] != null && PlacesService.isApiKeyConfigured) {
      try {
        details = await _placesService.getPlaceDetails(pool['place_id'].toString());
      } catch (e) {
        if (kDebugMode) {
          print('상세 정보 가져오기 실패: $e');
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPoolDetailModal(pool, details),
    );
  }

  Widget _buildPoolDetailModal(Map<String, dynamic> pool, Map<String, dynamic>? details) {
    final hasPhoto = pool['photo_url'] != null &&
        pool['photo_url'].toString().isNotEmpty;
    final isGoogleData = pool['place_id'] != null &&
        !pool['place_id'].toString().startsWith('local_');

    return Container(
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

          // 수영장 이미지
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                pool['photo_url'].toString(),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isGoogleData ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pool,
                    size: 80,
                    color: isGoogleData ? Colors.green.shade300 : Colors.blue.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isGoogleData ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGoogleData ? Colors.green.shade200 : Colors.blue.shade200,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.pool,
                  size: 50,
                  color: isGoogleData ? Colors.green.shade400 : Colors.blue.shade400,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 수영장 정보
          Row(
            children: [
              Expanded(
                child: Text(
                  pool['name']?.toString() ?? '수영장',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoogleData ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isGoogleData ? 'Google Maps' : 'Local Data',
                  style: TextStyle(
                    fontSize: 12,
                    color: isGoogleData ? Colors.green.shade700 : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 상세 정보
          _buildInfoRow(Icons.location_on, '주소',
              pool['address']?.toString() ?? pool['vicinity']?.toString() ?? ''),
          _buildInfoRow(Icons.star, '평점',
              pool['rating'] != null ? '${pool['rating']} (${pool['user_ratings_total'] ?? 0}명 평가)' : ''),
          if (pool['distance'] != null)
            _buildInfoRow(Icons.directions_walk, '거리',
                '${((pool['distance'] as num) / 1000).toStringAsFixed(1)}km'),

          // Google Places API에서 가져온 추가 정보
          if (details != null) ...[
            if (details['formatted_phone_number'] != null)
              _buildInfoRow(Icons.phone, '전화번호',
                  details['formatted_phone_number'].toString()),
            if (details['website'] != null)
              _buildInfoRow(Icons.language, '웹사이트',
                  details['website'].toString()),
          ],

          const SizedBox(height: 24),

          // 선택 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 모달 닫기
                Navigator.of(context).pop(pool); // 검색 화면 닫으면서 데이터 반환
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isGoogleData ? Colors.green : Colors.blue,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
        elevation: 0,
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
          // 상태 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: PlacesService.isApiKeyConfigured
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  PlacesService.isApiKeyConfigured ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: PlacesService.isApiKeyConfigured
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  PlacesService.isApiKeyConfigured
                      ? 'Google Places API 연결됨 - 실시간 검색'
                      : 'API 키 미설정 - 데모 데이터 사용',
                  style: TextStyle(
                    fontSize: 12,
                    color: PlacesService.isApiKeyConfigured
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: PlacesService.isApiKeyConfigured
                    ? '구글 맵에서 수영장 검색'
                    : '수영장 이름, 지역을 검색하세요',
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
                  borderSide: BorderSide(
                    color: PlacesService.isApiKeyConfigured ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              onChanged: _searchByKeyword,
              onSubmitted: _searchByKeyword,
            ),
          ),

          // 검색 결과 개수 표시
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '검색 결과: ${_searchResults.length}개',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_currentPosition != null)
                    Text(
                      '거리순 정렬',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

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
        zoom: 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildListView() {
    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _currentPosition == null
                  ? '위치 권한을 허용해주세요'
                  : '검색 결과가 없습니다',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_currentPosition == null)
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('위치 허용'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pool = _searchResults[index];
        final hasPhoto = pool['photo_url'] != null &&
            pool['photo_url'].toString().isNotEmpty;
        final isGoogleData = pool['place_id'] != null &&
            !pool['place_id'].toString().startsWith('local_');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
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
                  pool['photo_url'].toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.pool,
                    color: isGoogleData ? Colors.green.shade400 : Colors.blue.shade400,
                  ),
                ),
              )
                  : Icon(
                Icons.pool,
                color: isGoogleData ? Colors.green.shade400 : Colors.blue.shade400,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    pool['name']?.toString() ?? '수영장',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pool['address'] != null || pool['vicinity'] != null)
                  Text(
                    pool['address']?.toString() ?? pool['vicinity']?.toString() ?? '',
                    style: TextStyle(color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (pool['rating'] != null && (pool['rating'] as num) > 0) ...[
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${pool['rating']}'),
                      if (pool['user_ratings_total'] != null && (pool['user_ratings_total'] as num) > 0)
                        Text(' (${pool['user_ratings_total']})'),
                      const SizedBox(width: 16),
                    ],
                    if (pool['distance'] != null) ...[
                      Icon(Icons.directions_walk, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text('${((pool['distance'] as num) / 1000).toStringAsFixed(1)}km'),
                    ],
                  ],
                ),
              ],
            ),
            onTap: () => _selectPool(pool),
          ),
        );
      },
    );
  }
}