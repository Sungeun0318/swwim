// lib/services/training_firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TrainingFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 훈련 세션을 생성하고 Firebase에 저장
  static Future<String> createTrainingSession({
    required String title,
    required List<Map<String, dynamic>> trainings,
    required int totalDistance,
    required String totalTime,
    required int numPeople,
    required bool beepSound,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      // training_sessions 컬렉션에 저장
      final docRef = await _firestore.collection('training_sessions').add({
        'userId': user.uid,
        'title': title,
        'trainings': trainings,
        'totalDistance': totalDistance,
        'totalTime': totalTime,
        'numPeople': numPeople,
        'beepSound': beepSound,
        'status': 'created',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('훈련 세션 생성 완료: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('훈련 세션 생성 실패: $e');
      }
      throw Exception('훈련 세션 생성 실패: $e');
    }
  }

  /// 훈련 완료 후 캘린더에 추가
  static Future<void> addTrainingToCalendar({
    required String sessionId,
    required String title,
    required int totalDistance,
    required String actualDuration,
    required String plannedTime,
    required int numPeople,
    required bool beepSound,
    required List<Map<String, dynamic>> trainings,
    DateTime? customDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      // 날짜 설정 (커스텀 날짜 또는 현재 날짜)
      final targetDate = customDate ?? DateTime.now();
      final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

      // 캘린더에 추가할 데이터
      final calendarEvent = {
        'userId': user.uid,
        'sessionId': sessionId,
        'date': Timestamp.fromDate(dateOnly),
        'title': title,
        'totalDistance': totalDistance,
        'totalTime': actualDuration,
        'plannedTime': plannedTime,
        'numPeople': numPeople,
        'beepSound': beepSound,
        'trainings': trainings,
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Firebase에 저장
      final docRef = await _firestore.collection('calendar_events').add(calendarEvent);
      if (kDebugMode) {
        print('캘린더 이벤트 저장 완료: ${docRef.id}');
      }

      // training_sessions 문서 업데이트
      await _firestore.collection('training_sessions').doc(sessionId).update({
        'addedToCalendar': true,
        'calendarAddedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      if (kDebugMode) {
        print('훈련 세션 완료 처리: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 추가 실패: $e');
      }
      throw Exception('캘린더 추가 실패: $e');
    }
  }

  /// 사용자의 캘린더 이벤트 조회
  static Future<List<Map<String, dynamic>>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      Query query = _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true);

      // 날짜 범위 필터링
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 이벤트 조회 실패: $e');
      }
      throw Exception('캘린더 이벤트 조회 실패: $e');
    }
  }

  /// 특정 캘린더 이벤트 삭제
  static Future<void> deleteCalendarEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      await _firestore.collection('calendar_events').doc(eventId).delete();

      if (kDebugMode) {
        print('캘린더 이벤트 삭제 완료: $eventId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 이벤트 삭제 실패: $e');
      }
      throw Exception('캘린더 이벤트 삭제 실패: $e');
    }
  }

  /// 훈련 세션 상태 업데이트
  static Future<void> updateTrainingSession({
    required String sessionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      await _firestore.collection('training_sessions').doc(sessionId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('훈련 세션 업데이트 완료: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('훈련 세션 업데이트 실패: $e');
      }
      throw Exception('훈련 세션 업데이트 실패: $e');
    }
  }

  /// 사용자의 훈련 통계 조회
  static Future<Map<String, dynamic>> getTrainingStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      final events = await getCalendarEvents(
        startDate: startDate,
        endDate: endDate,
      );

      int totalSessions = events.length;
      int totalDistance = 0;
      int totalMinutes = 0;
      double totalCalories = 0;

      for (var event in events) {
        totalDistance += (event['totalDistance'] as int? ?? 0);

        // 시간 파싱
        final timeStr = event['totalTime'] as String? ?? '00:00:00';
        final duration = _parseDuration(timeStr);
        totalMinutes += duration.inMinutes;

        // 칼로리 계산 (거리 기반 예시)
        final distance = (event['totalDistance'] as int? ?? 0);
        totalCalories += distance * 0.5; // 1m당 0.5kcal 가정
      }

      return {
        'totalSessions': totalSessions,
        'totalDistance': totalDistance,
        'totalMinutes': totalMinutes,
        'totalCalories': totalCalories.round(),
        'averageDistance': totalSessions > 0 ? totalDistance / totalSessions : 0,
        'averageTime': totalSessions > 0 ? totalMinutes / totalSessions : 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('훈련 통계 조회 실패: $e');
      }
      throw Exception('훈련 통계 조회 실패: $e');
    }
  }

  /// 시간 문자열을 Duration으로 변환
  static Duration _parseDuration(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2].split('.')[0]);
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    } catch (e) {
      if (kDebugMode) {
        print('시간 파싱 오류: $e');
      }
    }
    return Duration.zero;
  }

  /// 훈련 데이터 백업
  static Future<void> backupTrainingData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      final events = await getCalendarEvents();

      // 백업 컬렉션에 저장
      await _firestore.collection('training_backups').add({
        'userId': user.uid,
        'events': events,
        'backupAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('훈련 데이터 백업 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('훈련 데이터 백업 실패: $e');
      }
      throw Exception('훈련 데이터 백업 실패: $e');
    }
  }
}