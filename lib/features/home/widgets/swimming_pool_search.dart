// lib/features/home/widgets/swimming_pool_search.dart - 최소한 수정
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/places_service.dart';

class SwimmingPoolSearch extends StatefulWidget {
  const SwimmingPoolSearch({Key? key}) : super(key: key);

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
            const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요')),
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
            if (pool['photo_url'] != null && pool['photo_url'].isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  pool['photo_url'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pool,
                      size: 80,
                      color: Colors.blue.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 수영장 정보
            Text(
              pool['name'] ?? '수영장',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (pool['address'] != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pool['address'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (pool['rating'] != null) ...[
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${pool['rating']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 선택 버튼 - 결과 반환하도록 수정
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 선택된 수영장 데이터를 이전 화면으로 반환
                  Navigator.of(context).pop(); // 모달 닫기
                  Navigator.of(context).pop(pool); // 검색 화면 닫으면서 데이터 반환
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
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
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '수영장 이름을 검색하세요',
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pool = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: pool['photo_url'] != null
                  ? Image.network(
                pool['photo_url'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.blue.shade50,
                  child: Icon(Icons.pool, color: Colors.blue.shade300),
                ),
              )
                  : Container(
                width: 60,
                height: 60,
                color: Colors.blue.shade50,
                child: Icon(Icons.pool, color: Colors.blue.shade300),
              ),
            ),
            title: Text(
              pool['name'] ?? '수영장',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pool['address'] != null)
                  Text(
                    pool['address'],
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (pool['rating'] != null && pool['rating'] > 0) ...[
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${pool['rating']}'),
                      const SizedBox(width: 16),
                    ],
                    if (pool['distance'] != null) ...[
                      Icon(Icons.directions_walk, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text('${(pool['distance'] / 1000).toStringAsFixed(1)}km'),
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