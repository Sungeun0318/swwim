// lib/models/training_step.dart

/// 각 훈련 단계의 설명과 지속 시간을 초 단위로 저장하는 모델입니다.
class TrainingStep {
  final String description;
  final int duration; // 초 단위

  TrainingStep({required this.description, required this.duration});

  @override
  String toString() => 'TrainingStep(description: $description, duration: $duration)';
}
