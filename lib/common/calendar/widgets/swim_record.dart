class SwimRecord {
  final DateTime date;
  final double distance;   // 미터 단위, 예: 1050
  final Duration duration; // 예: Duration(hours:1, minutes:39)
  final double? calories; // 칼로리
  final int? avgHeartRate; // 평균 심박수
  final String? avgPace; // 평균 페이스 (ex: 9'27")

  SwimRecord({
    required this.date,
    required this.distance,
    required this.duration,
    this.calories,
    this.avgHeartRate,
    this.avgPace,
  });
}

// 예시 더미 데이터
final List<SwimRecord> demoRecords = [
  SwimRecord(
    date: DateTime(2025,5,3),
    distance: 1050,
    duration: Duration(hours:1, minutes:39),
    calories: 193,
    avgHeartRate: 136,
    avgPace: "9'27\"",
  ),
];