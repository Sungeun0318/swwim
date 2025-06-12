// lib/services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY'; // 실제 API 키로 교체
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // 주변 수영장 검색
  Future<List<Map<String, dynamic>>> searchNearbyPools({
    required double latitude,
    required double longitude,
    int radius = 5000, // 5km
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json'
            '?location=$latitude,$longitude'
            '&radius=$radius'
            '&keyword=수영장'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((place) {
          final location = place['geometry']['location'];
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            location['lat'],
            location['lng'],
          ).round();

          return {
            'name': place['name'] ?? '수영장',
            'address': place['vicinity'] ?? '',
            'lat': location['lat'],
            'lng': location['lng'],
            'distance': distance,
            'rating': place['rating']?.toDouble() ?? 0.0,
            'place_id': place['place_id'],
            'photo_reference': place['photos']?[0]?['photo_reference'],
            'business_status': place['business_status'],
            'price_level': place['price_level'],
          };
        }).toList();
      } else {
        throw Exception('Places API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('수영장 검색 오류: $e');
      // 오류 발생 시 더미 데이터 반환
      return _getDummyPools(latitude, longitude);
    }
  }

  // 텍스트 검색
  Future<List<Map<String, dynamic>>> searchPoolsByText({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/textsearch/json'
            '?query=$query 수영장'
            '&location=$latitude,$longitude'
            '&radius=10000'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((place) {
          final location = place['geometry']['location'];
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            location['lat'],
            location['lng'],
          ).round();

          return {
            'name': place['name'] ?? '수영장',
            'address': place['formatted_address'] ?? '',
            'lat': location['lat'],
            'lng': location['lng'],
            'distance': distance,
            'rating': place['rating']?.toDouble() ?? 0.0,
            'place_id': place['place_id'],
            'photo_reference': place['photos']?[0]?['photo_reference'],
            'business_status': place['business_status'],
            'price_level': place['price_level'],
          };
        }).toList();
      } else {
        throw Exception('Places API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('텍스트 검색 오류: $e');
      return [];
    }
  }

  // 장소 세부 정보 가져오기
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
            '?place_id=$placeId'
            '&fields=name,formatted_address,formatted_phone_number,opening_hours,website,rating,reviews'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'];
      }
      return null;
    } catch (e) {
      print('장소 세부 정보 가져오기 오류: $e');
      return null;
    }
  }

  // 사진 URL 가져오기
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }

  // 주소에서 좌표 가져오기 (Geocoding)
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
            '?address=${Uri.encodeComponent(address)}'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          return {
            'lat': location['lat'],
            'lng': location['lng'],
          };
        }
      }
      return null;
    } catch (e) {
      print('주소 변환 오류: $e');
      return null;
    }
  }

  // 더미 데이터 (개발 및 테스트용)
  List<Map<String, dynamic>> _getDummyPools(double lat, double lng) {
    return [
      {
        'name': '올림픽수영장',
        'address': '서울특별시 송파구 올림픽로 424',
        'lat': lat + 0.01,
        'lng': lng + 0.01,
        'distance': 1200,
        'rating': 4.5,
        'phone': '02-410-1234',
        'place_id': 'dummy_1',
        'business_status': 'OPERATIONAL',
      },
      {
        'name': '시민수영장',
        'address': '서울특별시 강남구 테헤란로 123',
        'lat': lat - 0.01,
        'lng': lng + 0.005,
        'distance': 800,
        'rating': 4.2,
        'phone': '02-123-4567',
        'place_id': 'dummy_2',
        'business_status': 'OPERATIONAL',
      },
      {
        'name': '구민체육센터',
        'address': '서울특별시 서초구 서초대로 456',
        'lat': lat + 0.005,
        'lng': lng - 0.01,
        'distance': 1500,
        'rating': 4.0,
        'phone': '02-567-8901',
        'place_id': 'dummy_3',
        'business_status': 'OPERATIONAL',
      },
      {
        'name': '동네수영장',
        'address': '서울특별시 강동구 천호대로 1000',
        'lat': lat - 0.005,
        'lng': lng - 0.005,
        'distance': 600,
        'rating': 3.8,
        'phone': '02-789-0123',
        'place_id': 'dummy_4',
        'business_status': 'OPERATIONAL',
      },
      {
        'name': '스포츠센터',
        'address': '서울특별시 성동구 왕십리로 200',
        'lat': lat + 0.008,
        'lng': lng - 0.008,
        'distance': 1100,
        'rating': 4.3,
        'phone': '02-345-6789',
        'place_id': 'dummy_5',
        'business_status': 'OPERATIONAL',
      },
      {
        'name': '종합스포츠센터',
        'address': '서울특별시 마포구 월드컵로 240',
        'lat': lat - 0.008,
        'lng': lng + 0.008,
        'distance': 1350,
        'rating': 4.1,
        'phone': '02-234-5678',
        'place_id': 'dummy_6',
        'business_status': 'OPERATIONAL',
      },
      {
        'name': '청소년수련관',
        'address': '서울특별시 영등포구 여의대로 108',
        'lat': lat + 0.012,
        'lng': lng + 0.003,
        'distance': 1450,
        'rating': 3.9,
        'phone': '02-345-6789',
        'place_id': 'dummy_7',
        'business_status': 'OPERATIONAL',
      },
    ];
  }

  // 인기 수영장 검색 (평점 기준)
  Future<List<Map<String, dynamic>>> getPopularPools({
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    final allPools = await searchNearbyPools(
      latitude: latitude,
      longitude: longitude,
      radius: 10000, // 10km
    );

    // 평점 순으로 정렬
    allPools.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));

    return allPools.take(limit).toList();
  }

  // 가까운 수영장 검색 (거리 기준)
  Future<List<Map<String, dynamic>>> getNearestPools({
    required double latitude,
    required double longitude,
    int limit = 5,
  }) async {
    final allPools = await searchNearbyPools(
      latitude: latitude,
      longitude: longitude,
    );

    // 거리 순으로 정렬
    allPools.sort((a, b) => (a['distance'] ?? 0).compareTo(b['distance'] ?? 0));

    return allPools.take(limit).toList();
  }
}