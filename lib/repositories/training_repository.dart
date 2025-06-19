import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:swim/features/training_generation/models/training_session.dart';

class TrainingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> saveTrainingSession(TrainingSession session) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      final docRef = await _firestore
          .collection('training_sessions')
          .add(session.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('훈련 저장 실패: $e');
    }
  }

  Future<TrainingSession?> getTrainingSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) return null;

      return TrainingSession.fromFirestore(doc, null);
    } catch (e) {
      throw Exception('훈련 불러오기 실패: $e');
    }
  }

  Stream<List<TrainingSession>> getUserTrainingSessions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('training_sessions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TrainingSession.fromFirestore(doc, null))
        .toList());
  }

  Future<void> updateTrainingComplete(String sessionId) async {
    try {
      await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('훈련 완료 업데이트 실패: $e');
    }
  }

  Future<void> updateTrainingProgress(
      String sessionId,
      int currentIndex,
      int currentCycle,
      double progress,
      ) async {
    try {
      await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .update({
        'currentProgress': {
          'trainingIndex': currentIndex,
          'cycleIndex': currentCycle,
          'progressPercent': progress,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('진행 상태 업데이트 실패: $e');
      }
    }
  }
  Future<void> addTrainingToCalendar(
      String sessionId,
      Map<String, dynamic> calendarData,
      ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      // calendar_events 컬렉션에 저장
      await _firestore.collection('calendar_events').add({
        'userId': user.uid,
        'sessionId': sessionId,
        'date': calendarData['date'],
        'title': calendarData['title'],
        'totalTime': calendarData['totalTime'],
        'totalDistance': calendarData['totalDistance'],
        'trainings': calendarData['trainings'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // training_sessions의 캘린더 추가 상태 업데이트
      await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .update({'addedToCalendar': true});
    } catch (e) {
      throw Exception('캘린더 추가 실패: $e');
    }
  }
}