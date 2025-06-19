// lib/features/home/widgets/swimming_pool_search.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스를 활성화해주세요')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 필요합니다')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // 현재 위치 주변 수영장 검색
      await _searchNearbyPools();
    } catch (e) {
      print('위치 가져오기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치를 가져올 수 없습니다')),
      );
    }
  }

  Future<void> _searchNearbyPools() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Google Places API를 사용한 실제 수영장 검색
      final pools = await _placesService.searchNearbyPools(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 5000, // 5km 반경
      );

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

        // 현재 위치 마커 추가
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
      print('수영장 검색 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수영장 검색에 실패했습니다')),
      );
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
      // Google Places API를 사용한 텍스트 검색
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
      print('검색 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPool(Map<String, dynamic> pool) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pool['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pool['address'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${pool['distance']}m'),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${pool['rating']}'),
              ],
            ),
            if (pool['phone'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(pool['phone']),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 바텀시트 닫기
                  Navigator.pop(context, pool); // 선택된 수영장 반환
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '이 수영장 선택',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
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
          Padding(
            padding: const EdgeInsets.all(16),
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
                ),
              ),
              onSubmitted: _searchByKeyword,
            ),
          ),

          // 로딩 표시
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          // 지도 또는 리스트 뷰
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
        child: CircularProgressIndicator(),
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
    );
  }

  Widget _buildListView() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pool = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.pool, color: Colors.white),
            ),
            title: Text(
              pool['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pool['address']),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.directions_walk, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${pool['distance']}m'),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${pool['rating']}'),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _selectPool(pool),
          ),
        );
      },
    );
  }
}