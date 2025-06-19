import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingResult {
  final String id;
  final String userId;
  final String sessionId;
  final List<TrainingDetailResult> trainings;
  final String totalTime;
  final int totalDistance;
  final DateTime completedAt;
  final bool addedToCalendar;

  TrainingResult({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.trainings,
    required this.totalTime,
    required this.totalDistance,
    required this.completedAt,
    this.addedToCalendar = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'trainings': trainings.map((t) => t.toMap()).toList(),
      'totalTime': totalTime,
      'totalDistance': totalDistance,
      'completedAt': completedAt,
      'addedToCalendar': addedToCalendar,
    };
  }

  factory TrainingResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainingResult(
      id: doc.id,
      userId: data['userId'],
      sessionId: data['sessionId'],
      trainings: (data['trainings'] as List)
          .map((t) => TrainingDetailResult.fromMap(t))
          .toList(),
      totalTime: data['totalTime'],
      totalDistance: data['totalDistance'],
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      addedToCalendar: data['addedToCalendar'] ?? false,
    );
  }
}

class TrainingDetailResult {
  final String title;
  final int distance;
  final int count;
  final int cycle;
  final String actualTime;
  final bool completed;

  TrainingDetailResult({
    required this.title,
    required this.distance,
    required this.count,
    required this.cycle,
    required this.actualTime,
    this.completed = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'distance': distance,
      'count': count,
      'cycle': cycle,
      'actualTime': actualTime,
      'completed': completed,
    };
  }

  factory TrainingDetailResult.fromMap(Map<String, dynamic> map) {
    return TrainingDetailResult(
      title: map['title'],
      distance: map['distance'],
      count: map['count'],
      cycle: map['cycle'],
      actualTime: map['actualTime'],
      completed: map['completed'] ?? true,
    );
  }
}