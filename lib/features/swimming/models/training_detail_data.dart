// lib/features/training/models/training_detail_data.dart 수정

class TrainingDetailData {
  String title;
  int distance;
  int count;
  int cycle;
  int restTime;
  int interval;
  int personnel;

  TrainingDetailData({
    this.title = "",
    this.distance = 10,
    this.count = 1,
    this.cycle = 60,
    this.restTime = 0,
    this.interval = 5,
    this.personnel = 1,
  });

  // Firebase용 변환 메서드 추가
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'distance': distance,
      'count': count,
      'cycle': cycle,
      'restTime': restTime,
      'interval': interval,
      'personnel': personnel,
    };
  }

  factory TrainingDetailData.fromMap(Map<String, dynamic> map) {
    return TrainingDetailData(
      title: map['title'] ?? '',
      distance: map['distance'] ?? 10,
      count: map['count'] ?? 1,
      cycle: map['cycle'] ?? 60,
      restTime: map['restTime'] ?? 0,
      interval: map['interval'] ?? 5,
      personnel: map['personnel'] ?? 1,
    );
  }

  // 기존 게터들
  int get totalDistance => distance * count;
  int get totalTime => (cycle * count) + restTime;
}