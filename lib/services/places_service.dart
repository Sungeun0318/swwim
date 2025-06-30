// lib/services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  static const String _apiKey = 'AIzaSyDJCqPAwtXCsPX2Jcptoykesc_R9xOj3z0'; // 실제 API 키로 교체
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // 주변 수영장 검색
  Future<List<Map<String, dynamic>>> searchNearbyPools({
    required double latitude,
    required double longitude,
    int radius = 5000, // 5km
  }) async {
    if (kDebugMode) {
      print('API 키 확인: ${_apiKey.substring(0, 10)}...'); // API 키 일부만 로그
      print('검색 위치: $latitude, $longitude');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json'
            '?location=$latitude,$longitude'
            '&radius=$radius'
            '&keyword=수영장'
            '&language=ko'
            '&key=$_apiKey',
      );

      if (kDebugMode) {
        print('요청 URL: $url');
      }

      final response = await http.get(url);

      if (kDebugMode) {
        print('응답 상태: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 에러 체크
        if (data['status'] != 'OK') {
          if (kDebugMode) {
            print('API 오류: ${data['status']} - ${data['error_message'] ?? '알 수 없는 오류'}');
          }
          return _getDummyPools(latitude, longitude);
        }

        final results = data['results'] as List;

        return results.map((place) {
          final location = place['geometry']['location'];
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            location['lat'],
            location['lng'],
          ).round();

          // 사진 정보 처리
          String? photoUrl;
          if (place['photos'] != null && place['photos'].isNotEmpty) {
            final photoReference = place['photos'][0]['photo_reference'];
            photoUrl = getPhotoUrl(photoReference, maxWidth: 400);
          }

          return {
            'name': place['name'] ?? '수영장',
            'address': place['vicinity'] ?? '',
            'lat': location['lat'],
            'lng': location['lng'],
            'distance': distance,
            'rating': place['rating']?.toDouble() ?? 0.0,
            'place_id': place['place_id'],
            'photo_reference': place['photos']?[0]?['photo_reference'],
            'photo_url': photoUrl, // 사진 URL 추가
            'business_status': place['business_status'],
            'price_level': place['price_level'],
            'types': place['types'], // 장소 유형 정보
          };
        }).toList();
      } else {
        throw Exception('Places API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('수영장 검색 오류: $e');
      }
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

        if (data['status'] != 'OK') {
          return [];
        }

        final results = data['results'] as List;

        return results.map((place) {
          final location = place['geometry']['location'];
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            location['lat'],
            location['lng'],
          ).round();

          // 사진 정보 처리
          String? photoUrl;
          if (place['photos'] != null && place['photos'].isNotEmpty) {
            final photoReference = place['photos'][0]['photo_reference'];
            photoUrl = getPhotoUrl(photoReference, maxWidth: 400);
          }

          return {
            'name': place['name'] ?? '수영장',
            'address': place['formatted_address'] ?? '',
            'lat': location['lat'],
            'lng': location['lng'],
            'distance': distance,
            'rating': place['rating']?.toDouble() ?? 0.0,
            'place_id': place['place_id'],
            'photo_reference': place['photos']?[0]?['photo_reference'],
            'photo_url': photoUrl, // 사진 URL 추가
            'business_status': place['business_status'],
            'price_level': place['price_level'],
            'types': place['types'],
          };
        }).toList();
      } else {
        throw Exception('Places API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('텍스트 검색 오류: $e');
      }
      return [];
    }
  }

  // 장소 세부 정보 가져오기
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
            '?place_id=$placeId'
            '&fields=name,formatted_address,formatted_phone_number,opening_hours,website,rating,reviews,photos'
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
      if (kDebugMode) {
        print('장소 세부 정보 가져오기 오류: $e');
      }
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

  // 더미 데이터 (개발 및 테스트용) - 사진 URL 포함
  List<Map<String, dynamic>> _getDummyPools(double lat, double lng) {
    if (kDebugMode) {
      print('더미 데이터 반환 중...');
    }

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
        'photo_url': 'https://via.placeholder.com/400x300/0066cc/ffffff?text=올림픽수영장', // 더미 이미지
        'types': ['swimming_pool', 'establishment'],
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
        'photo_url': 'https://via.placeholder.com/400x300/4CAF50/ffffff?text=시민수영장', // 더미 이미지
        'types': ['swimming_pool', 'establishment'],
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
        'photo_url': 'https://via.placeholder.com/400x300/FF9800/ffffff?text=구민체육센터', // 더미 이미지
        'types': ['gym', 'swimming_pool', 'establishment'],
      },
      {
        'name': '스포츠센터 수영장',
        'address': '서울특별시 마포구 월드컵로 240',
        'lat': lat - 0.008,
        'lng': lng + 0.008,
        'distance': 1350,
        'rating': 4.3,
        'phone': '02-234-5678',
        'place_id': 'dummy_4',
        'business_status': 'OPERATIONAL',
        'photo_url': 'https://via.placeholder.com/400x300/9C27B0/ffffff?text=스포츠센터', // 더미 이미지
        'types': ['swimming_pool', 'gym', 'establishment'],
      },
    ];
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
      if (kDebugMode) {
        print('주소 변환 오류: $e');
      }
      return null;
    }
  }
}