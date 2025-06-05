class SwimRecord {
  final DateTime date;
  final double distance;   // 미터 단위, 예: 1050
  final Duration duration; // 예: Duration(hours:1, minutes:39)

  SwimRecord({required this.date, required this.distance, required this.duration});
}

// 예시 더미 데이터
final List<SwimRecord> demoRecords = [
  SwimRecord(
    date: DateTime(2025,5,3),
    distance: 1050,
    duration: Duration(hours:1, minutes:39),
  ),
];