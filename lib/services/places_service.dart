// lib/services/places_service.dart - 실제 Google Places API 사용
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  // TODO: 여기에 실제 Google Places API 키를 입력하세요
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // API 키가 설정되었는지 확인
  static bool get isApiKeyConfigured => _apiKey != 'YOUR_GOOGLE_PLACES_API_KEY';

  // 주변 수영장 검색 (실제 Google Places API 사용)
  Future<List<Map<String, dynamic>>> searchNearbyPools({
    required double latitude,
    required double longitude,
    int radius = 10000, // 10km 반경
  }) async {
    if (!isApiKeyConfigured) {
      if (kDebugMode) {
        print('Google Places API 키가 설정되지 않음. 로컬 데이터 사용');
      }
      return _getLocalPoolData(latitude, longitude);
    }

    if (kDebugMode) {
      print('Google Places API로 수영장 검색 시작 - 위치: $latitude, $longitude');
    }

    try {
      // 한국어 키워드로 수영장 검색
      final keywords = ['수영장', 'swimming pool', '실내수영장', '야외수영장', '아쿠아센터'];
      List<Map<String, dynamic>> allResults = [];

      for (String keyword in keywords) {
        final results = await _searchByKeyword(
          keyword: keyword,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );
        allResults.addAll(results);
      }

      // 중복 제거 (place_id 기준)
      final uniqueResults = <String, Map<String, dynamic>>{};
      for (var result in allResults) {
        final placeId = result['place_id'];
        if (placeId != null && !uniqueResults.containsKey(placeId)) {
          uniqueResults[placeId] = result;
        }
      }

      final finalResults = uniqueResults.values.toList();

      if (kDebugMode) {
        print('총 검색 결과: ${finalResults.length}개 수영장 발견');
      }

      return finalResults;
    } catch (e) {
      if (kDebugMode) {
        print('Google Places API 검색 오류: $e');
      }
      // API 오류 시 로컬 데이터로 fallback
      return _getLocalPoolData(latitude, longitude);
    }
  }

  // 키워드별 검색
  Future<List<Map<String, dynamic>>> _searchByKeyword({
    required String keyword,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json'
            '?location=$latitude,$longitude'
            '&radius=$radius'
            '&keyword=$keyword'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return _processPlaceResults(results, latitude, longitude);
        } else {
          if (kDebugMode) {
            print('API 상태 오류: ${data['status']} - ${data['error_message'] ?? ''}');
          }
          return [];
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('키워드 "$keyword" 검색 실패: $e');
      }
      return [];
    }
  }

  // 검색 결과 처리
  List<Map<String, dynamic>> _processPlaceResults(
      List results,
      double userLat,
      double userLng,
      ) {
    return results.map((place) {
      final location = place['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      final distance = Geolocator.distanceBetween(userLat, userLng, lat, lng);

      String? photoUrl;
      if (place['photos'] != null && place['photos'].isNotEmpty) {
        final photoReference = place['photos'][0]['photo_reference'];
        photoUrl = getPhotoUrl(photoReference, maxWidth: 400);
      }

      return {
        'place_id': place['place_id'],
        'name': place['name'] ?? '수영장',
        'address': place['vicinity'] ?? place['formatted_address'] ?? '',
        'lat': lat,
        'lng': lng,
        'distance': distance.round(),
        'rating': place['rating']?.toDouble() ?? 0.0,
        'photo_reference': place['photos']?[0]?['photo_reference'],
        'photo_url': photoUrl,
        'business_status': place['business_status'],
        'price_level': place['price_level'],
        'types': place['types'] ?? [],
        'user_ratings_total': place['user_ratings_total'] ?? 0,
        'opening_hours': place['opening_hours'],
      };
    }).toList();
  }

  // 텍스트 검색
  Future<List<Map<String, dynamic>>> searchPoolsByText({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    if (!isApiKeyConfigured) {
      return _searchLocalPoolsByText(query, latitude, longitude);
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/textsearch/json'
            '?query=$query 수영장'
            '&location=$latitude,$longitude'
            '&radius=20000'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return _processPlaceResults(results, latitude, longitude);
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('텍스트 검색 오류: $e');
      }
      return _searchLocalPoolsByText(query, latitude, longitude);
    }
  }

  // 장소 상세 정보 가져오기
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!isApiKeyConfigured) return null;

    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
            '?place_id=$placeId'
            '&fields=name,formatted_address,formatted_phone_number,opening_hours,website,rating,user_ratings_total,photos'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('상세 정보 가져오기 실패: $e');
      }
      return null;
    }
  }

  // 사진 URL 생성
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    if (!isApiKeyConfigured) return '';
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$_apiKey';
  }

  // API 키 미설정 시 로컬 데이터 사용
  List<Map<String, dynamic>> _getLocalPoolData(double latitude, double longitude) {
    final localPools = [
      {
        'place_id': 'local_1',
        'name': '수원시민수영장',
        'address': '경기 수원시 팔달구 중부대로 120',
        'lat': 37.2636,
        'lng': 127.0286,
        'rating': 4.2,
        'photo_url': '',
        'types': ['swimming_pool', 'gym'],
        'user_ratings_total': 150,
      },
      {
        'place_id': 'local_2',
        'name': '영통수영장',
        'address': '경기 수원시 영통구 영통로 205',
        'lat': 37.2572,
        'lng': 127.0456,
        'rating': 4.0,
        'photo_url': '',
        'types': ['swimming_pool'],
        'user_ratings_total': 89,
      },
      {
        'place_id': 'local_3',
        'name': '장안스포츠센터 수영장',
        'address': '경기 수원시 장안구 정조로 966',
        'lat': 37.3017,
        'lng': 127.0103,
        'rating': 4.3,
        'photo_url': '',
        'types': ['swimming_pool', 'gym', 'health'],
        'user_ratings_total': 234,
      },
      {
        'place_id': 'local_4',
        'name': '권선구민회관 수영장',
        'address': '경기 수원시 권선구 권선로 540',
        'lat': 37.2484,
        'lng': 126.9976,
        'rating': 3.9,
        'photo_url': '',
        'types': ['swimming_pool'],
        'user_ratings_total': 67,
      },
      {
        'place_id': 'local_5',
        'name': '아주대학교 수영장',
        'address': '경기 수원시 영통구 월드컵로 206',
        'lat': 37.2837,
        'lng': 127.0451,
        'rating': 4.1,
        'photo_url': '',
        'types': ['swimming_pool', 'university'],
        'user_ratings_total': 123,
      },
    ];

    // 거리 계산
    for (var pool in localPools) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        pool['lat'],
        pool['lng'],
      );
      pool['distance'] = distance.round();
    }

    // 거리순 정렬
    localPools.sort((a, b) => a['distance'].compareTo(b['distance']));

    return localPools;
  }

  // 로컬 데이터에서 텍스트 검색
  List<Map<String, dynamic>> _searchLocalPoolsByText(
      String query,
      double latitude,
      double longitude,
      ) {
    final allPools = _getLocalPoolData(latitude, longitude);
    final lowercaseQuery = query.toLowerCase();

    return allPools.where((pool) {
      final name = (pool['name'] ?? '').toLowerCase();
      final address = (pool['address'] ?? '').toLowerCase();
      return name.contains(lowercaseQuery) || address.contains(lowercaseQuery);
    }).toList();
  }
}