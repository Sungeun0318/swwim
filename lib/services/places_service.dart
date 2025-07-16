// lib/services/places_service.dart - 최종 완성 버전 (Google Places API만 사용)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  // 실제 Google Places API 키 (작동 확인됨)
  static const String _apiKey = 'AIzaSyDJCqPAwtXCsPX2Jcptoykesc_R9xOj3z0'; // 여기에 실제 키 입력
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // API 키 설정 확인
  static bool get isApiKeyConfigured =>
      _apiKey.isNotEmpty &&
          _apiKey != 'YOUR_ACTUAL_API_KEY_HERE' &&
          _apiKey.length > 10;

  // 주변 수영장 검색 (Google Places API만 사용)
  Future<List<Map<String, dynamic>>> searchNearbyPools({
    required double latitude,
    required double longitude,
    int radius = 10000,
  }) async {
    if (!isApiKeyConfigured) {
      if (kDebugMode) {
        print('Google Places API 키가 설정되지 않음');
      }
      return [];
    }

    if (kDebugMode) {
      print('Google Places API로 수영장 검색: $latitude, $longitude');
    }

    try {
      // 한국어 키워드로 다양하게 검색
      final keywords = [
        '수영장',
        'swimming pool',
        '실내수영장',
        '수영센터',
        '아쿠아센터',
        '스포츠센터 수영장'
      ];

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

      // 거리순 정렬
      final finalResults = uniqueResults.values.toList();
      finalResults.sort((a, b) {
        final distanceA = a['distance'] ?? 0;
        final distanceB = b['distance'] ?? 0;
        return distanceA.compareTo(distanceB);
      });

      if (kDebugMode) {
        print('Google Places API 검색 완료: ${finalResults.length}개 수영장');
      }

      return finalResults;
    } catch (e) {
      if (kDebugMode) {
        print('Google Places API 검색 오류: $e');
      }
      return [];
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
        if (kDebugMode) {
          print('HTTP 오류: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('키워드 "$keyword" 검색 실패: $e');
      }
      return [];
    }
  }

  // 검색 결과 처리 (타입 안전)
  List<Map<String, dynamic>> _processPlaceResults(
      List results,
      double userLat,
      double userLng,
      ) {
    return results.map<Map<String, dynamic>?>((place) {
      try {
        final location = place['geometry']['location'];

        final lat = _safeDouble(location['lat']);
        final lng = _safeDouble(location['lng']);

        final distance = Geolocator.distanceBetween(userLat, userLng, lat, lng);

        String? photoUrl;
        if (place['photos'] != null && place['photos'].isNotEmpty) {
          final photoReference = place['photos'][0]['photo_reference'];
          if (photoReference != null) {
            photoUrl = getPhotoUrl(photoReference, maxWidth: 400);
          }
        }

        return {
          'place_id': place['place_id'],
          'name': place['name'] ?? '수영장',
          'address': place['vicinity'] ?? place['formatted_address'] ?? '',
          'lat': lat,
          'lng': lng,
          'distance': distance.round(),
          'rating': _safeDouble(place['rating']),
          'photo_reference': place['photos']?[0]?['photo_reference'],
          'photo_url': photoUrl,
          'business_status': place['business_status'],
          'price_level': place['price_level'],
          'types': place['types'] ?? [],
          'user_ratings_total': place['user_ratings_total'] ?? 0,
          'opening_hours': place['opening_hours'],
        };
      } catch (e) {
        if (kDebugMode) {
          print('장소 처리 오류: $e');
        }
        return null;
      }
    }).where((element) => element != null).cast<Map<String, dynamic>>().toList();
  }

  // 안전한 타입 변환
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  // 텍스트 검색
  Future<List<Map<String, dynamic>>> searchPoolsByText({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    if (!isApiKeyConfigured) {
      return [];
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
      return [];
    }
  }

  // 장소 상세 정보 가져오기
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!isApiKeyConfigured) return null;

    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
            '?place_id=$placeId'
            '&fields=name,formatted_address,formatted_phone_number,opening_hours,website,rating,user_ratings_total,geometry,photos'
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
        print('장소 상세 정보 오류: $e');
      }
      return null;
    }
  }

  // 사진 URL 생성
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    if (!isApiKeyConfigured || photoReference.isEmpty) return '';
    return '$_baseUrl/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }

  // Places API로 다음 페이지 결과 가져오기 (선택사항)
  Future<List<Map<String, dynamic>>> getNextPageResults(String nextPageToken, double latitude, double longitude) async {
    if (!isApiKeyConfigured || nextPageToken.isEmpty) return [];

    try {
      // Google API는 next_page_token 사용 시 약간의 지연이 필요
      await Future.delayed(const Duration(seconds: 2));

      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json'
            '?pagetoken=$nextPageToken'
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
        print('다음 페이지 로드 오류: $e');
      }
      return [];
    }
  }
}