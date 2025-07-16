// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 사용자 프로필 가져오기
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('사용자 프로필 가져오기 오류: $e');
      return null;
    }
  }

  // 선택한 수영장 저장
  Future<bool> saveSelectedPool(Map<String, dynamic> poolData) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'selectedPool': poolData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('수영장 선택 저장 오류: $e');
      return false;
    }
  }

  // 사용자의 수영 기록 통계 가져오기
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      // 이번 달 수영 기록 가져오기
      final snapshot = await _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
          .get();

      int totalSessions = snapshot.docs.length;
      double totalDistance = 0;
      int totalMinutes = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalDistance += (data['totalDistance'] ?? 0).toDouble();

        // 시간 파싱
        final timeStr = data['totalTime'] ?? '00:00:00';
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          totalMinutes += int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]);
        }
      }

      return {
        'totalSessions': totalSessions,
        'totalDistance': totalDistance,
        'totalMinutes': totalMinutes,
        'averageDistance': totalSessions > 0 ? totalDistance / totalSessions : 0,
      };
    } catch (e) {
      print('사용자 통계 가져오기 오류: $e');
      return {};
    }
  }

  // 즐겨찾는 수영장 목록 가져오기
  Future<List<Map<String, dynamic>>> getFavoritePools() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['favoritePools'] != null) {
        return List<Map<String, dynamic>>.from(doc.data()!['favoritePools']);
      }
      return [];
    } catch (e) {
      print('즐겨찾는 수영장 가져오기 오류: $e');
      return [];
    }
  }

  // 즐겨찾는 수영장 추가
  Future<bool> addFavoritePool(Map<String, dynamic> poolData) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'favoritePools': FieldValue.arrayUnion([poolData]),
      });
      return true;
    } catch (e) {
      print('즐겨찾는 수영장 추가 오류: $e');
      return false;
    }
  }

  // 즐겨찾는 수영장 제거
  Future<bool> removeFavoritePool(Map<String, dynamic> poolData) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'favoritePools': FieldValue.arrayRemove([poolData]),
      });
      return true;
    } catch (e) {
      print('즐겨찾는 수영장 제거 오류: $e');
      return false;
    }
  }

  // 사용자 설정 업데이트
  Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'settings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('사용자 설정 업데이트 오류: $e');
      return false;
    }
  }

  // 사용자의 월별 수영 기록 가져오기
  Future<List<Map<String, dynamic>>> getMonthlyRecords(DateTime month) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'date': (data['date'] as Timestamp).toDate(),
          'totalDistance': data['totalDistance'] ?? 0,
          'totalTime': data['totalTime'] ?? '00:00:00',
          'trainings': data['trainings'] ?? [],
        };
      }).toList();
    } catch (e) {
      print('월별 기록 가져오기 오류: $e');
      return [];
    }
  }

  // 사용자 프로필 업데이트
  Future<bool> updateUserProfile({
    String? name,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final updateData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (additionalData != null) updateData.addAll(additionalData);

      await _firestore.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      return true;
    } catch (e) {
      print('사용자 프로필 업데이트 오류: $e');
      return false;
    }
  }
}