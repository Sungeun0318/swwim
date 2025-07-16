// lib/features/training_generation/models/training_session.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim/features/swimming/models/training_detail_data.dart';

class TrainingSession {
  final String id;
  final String userId;
  final List<TrainingDetailData> trainings;
  final String beepSound;
  final int numPeople;
  final DateTime createdAt;
  final bool isCompleted;
  final int totalTime;
  final int totalDistance;
  final String? title;
  final Map<String, dynamic>? metadata;

  TrainingSession({
    required this.id,
    required this.userId,
    required this.trainings,
    required this.beepSound,
    required this.numPeople,
    required this.createdAt,
    this.isCompleted = false,
    required this.totalTime,
    required this.totalDistance,
    this.title,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'trainings': trainings.map((t) => t.toMap()).toList(),
      'beepSound': beepSound,
      'numPeople': numPeople,
      'createdAt': createdAt,
      'isCompleted': isCompleted,
      'totalTime': totalTime,
      'totalDistance': totalDistance,
      'title': title ?? '훈련 ${DateTime.now().toString()}',
      'metadata': metadata ?? {},
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TrainingSession.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return TrainingSession(
      id: snapshot.id,
      userId: data?['userId'] ?? '',
      trainings: (data?['trainings'] as List)
          .map((item) => TrainingDetailData.fromMap(item))
          .toList(),
      beepSound: data?['beepSound'] ?? '',
      numPeople: data?['numPeople'] ?? 1,
      createdAt: (data?['createdAt'] as Timestamp).toDate(),
      isCompleted: data?['isCompleted'] ?? false,
      totalTime: data?['totalTime'] ?? 0,
      totalDistance: data?['totalDistance'] ?? 0,
      title: data?['title'],
      metadata: data?['metadata'],
    );
  }
}