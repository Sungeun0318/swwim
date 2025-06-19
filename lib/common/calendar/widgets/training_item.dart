class TrainingItem {
  final DateTime date;
  final String name;
  final String distance;
  final String time;
  final String? id; // Firebase 문서 ID 추가

  TrainingItem({
    required this.date,
    required this.name,
    required this.distance,
    required this.time,
    this.id,
  });
}
