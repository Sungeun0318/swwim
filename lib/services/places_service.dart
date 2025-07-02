// lib/services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  // TODO: 실제 Google Places API 키로 교체 필요
  static const String _apiKey = 'AIzaSyDJCqPAwtXCsPX2Jcptoykesc_R9xOj3z0';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // 주변 수영장 검색
  Future<List<Map<String, dynamic>>> searchNearbyPools({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    if (kDebugMode) {
      print('수영장 검색 시작 - 위치: $latitude, $longitude');
    }

    // API 키가 기본값이면 빈 리스트 반환
    if (_apiKey == 'AIzaSyDJCqPAwtXCsPX2Jcptoykesc_R9xOj3z0') {
      if (kDebugMode) {
        print('API 키가 설정되지 않음');
      }
      return [];
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
        print('API 요청 URL: $url');
      }

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API 요청 시간 초과');
        },
      );

      if (kDebugMode) {
        print('API 응답 상태: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] != 'OK') {
          if (kDebugMode) {
            print('API 오류: ${data['status']} - ${data['error_message'] ?? '알 수 없는 오류'}');
          }
          return [];
        }

        final results = data['results'] as List;
        if (kDebugMode) {
          print('검색 결과: ${results.length}개 발견');
        }

        return results.map((place) {
          final location = place['geometry']['location'];
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            location['lat'],
            location['lng'],
          ).round();

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
            'photo_url': photoUrl,
            'business_status': place['business_status'],
            'price_level': place['price_level'],
            'types': place['types'],
          };
        }).toList();
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('수영장 검색 오류: $e');
      }
      return [];
    }
  }

  // 텍스트 검색
  Future<List<Map<String, dynamic>>> searchPoolsByText({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey == 'AIzaSyDJCqPAwtXCsPX2Jcptoykesc_R9xOj3z0') {
      return [];
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/textsearch/json'
            '?query=$query 수영장'
            '&location=$latitude,$longitude'
            '&radius=10000'
            '&language=ko'
            '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

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
            'photo_url': photoUrl,
            'business_status': place['business_status'],
            'types': place['types'],
          };
        }).toList();
      } else {
        throw Exception('텍스트 검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('텍스트 검색 오류: $e');
      }
      return [];
    }
  }

  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    if (_apiKey == 'AIzaSyDJCqPAwtXCsPX2Jcptoykesc_R9xOj3z0') {
      return '';
    }
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$_apiKey';
  }
}