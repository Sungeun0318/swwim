// lib/features/training_generation/models/training_detail_data.dart

class TrainingDetailData {
  String title;       // 훈련 제목
  int distance;       // 단위: m (10 ~ 10,000, 5m 단위)
  int count;          // 훈련 개수 (1 ~ 100)
  int cycle;          // 싸이클 시간 (초 단위, 최대 86400)
  int restTime;       // 쉬는 시간 (초, 2번째 훈련부터 적용, 최대 3600)
  int interval;       // 출발 간격 (초, 2명 이상일 때 활성화, 5~60)
  int personnel;      // 훈련 인원 (1 ~ 30)

  // 자동 계산된 값
  int get totalDistance => distance * count;
  int get totalTime => (cycle * count) + restTime;

  TrainingDetailData({
    this.title = "",
    this.distance = 10,
    this.count = 1,
    this.cycle = 60,
    this.restTime = 0,
    this.interval = 5,
    this.personnel = 1,
  });
}
