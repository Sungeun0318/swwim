import 'package:flutter/material.dart';
import '../models/training_step.dart';
import '/features/training/screens/timer_screen.dart';
import '../../../../common/widgets/distance_picker.dart';

class SwimmingQuickStartScreen extends StatefulWidget {
  final String level;
  const SwimmingQuickStartScreen({Key? key, required this.level}) : super(key: key);

  @override
  _SwimmingQuickStartScreenState createState() => _SwimmingQuickStartScreenState();
}

class _SwimmingQuickStartScreenState extends State<SwimmingQuickStartScreen> {
  // 거리 범위 상수
  static const double kMinDistance = 10;
  static const double kMaxDistance = 100;
  static const double kStepSize = 5;

  late List<TrainingStep> steps;

  @override
  void initState() {
    super.initState();
    steps = _getPredefinedSteps(widget.level);
  }

  List<TrainingStep> _getPredefinedSteps(String level) {
    if (level == "초급") {
      return [
        TrainingStep(description: "걷기로 몸풀기 50m", duration: 180),
        TrainingStep(description: "원터치 + 6박자 쉬고 물잡기 자유형 25m X 6개", duration: 300),
        TrainingStep(description: "원터치 자유형 25m X 6개", duration: 300),
        TrainingStep(description: "한바퀴 걸어갔다오면 쉬기 50m", duration: 180),
        TrainingStep(description: "배영 차렷 발차기 25m 3개", duration: 165),
        TrainingStep(description: "배영 만세 발차기 25m 3개", duration: 165),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "배영 팔돌리기 25m 5개", duration: 275),
        TrainingStep(description: "75m 걷기", duration: 270),
      ];
    } else if (level == "중급") {
      return [
        TrainingStep(description: "걷기로 몸풀기 50m", duration: 180),
        TrainingStep(description: "자유형 팔돌리기 25m 6개", duration: 300),
        TrainingStep(description: "배영 팔돌리기 25m 6개", duration: 300),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "평영 발차기 25m 4개", duration: 200),
        TrainingStep(description: "손동작만 하며 걷기 50m", duration: 240),
        TrainingStep(description: "평영 손발 콤비 25m 6개", duration: 360),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "접영 차렷 발차기 25m 4개", duration: 240),
        TrainingStep(description: "접영 웨이브+팔돌리기 25m 6개", duration: 420),
        TrainingStep(description: "접영 콤비 맞추기 25m 4개", duration: 240),
        TrainingStep(description: "마무리 운동 걷기 25m 4개", duration: 300),
      ];
    } else if (level == "상급") {
      return [
        TrainingStep(description: "자유형 몸풀기 25m 8개", duration: 300),
        TrainingStep(description: "개인 혼영 25m 16개", duration: 720),
        TrainingStep(description: "no board 자유형 발차기 25m 12개", duration: 660),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "자세 교정 훈련 25m 12개", duration: 480),
        TrainingStep(description: "접영-배영, 배영-평영, 평영-자유형, 자유형-접영 50m 4개 2세트", duration: 720),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "접영 25m 2개", duration: 80),
        TrainingStep(description: "배영 25m 2개", duration: 80),
        TrainingStep(description: "평영 25m 2개", duration: 80),
        TrainingStep(description: "자유형 25m 2개", duration: 80),
        TrainingStep(description: "마무리 운동 걷기 25m 4개", duration: 180),
      ];
    } else if (level == "마스터") {
      return [
        TrainingStep(description: "워밍업 자유형 50m 8개", duration: 600),
        TrainingStep(description: "IM 50m 4개", duration: 300),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "no board 킥 50m 6개", duration: 540),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "길게 풀 50m 4개", duration: 300),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "자유형 50m 6개", duration: 450),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "자세 교정 훈련 50m 6개", duration: 480),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "자기 종목 인터벌 트레이닝 50m 4개", duration: 80),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "자기 종목 인터벌 트레이닝 50m 8개", duration: 640),
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "스프린트 훈련 25m 4개", duration: 240),
        TrainingStep(description: "마무리 운동 50m 4개", duration: 180),
      ];
    }
    return [];
  }

  // 정규식으로 설명에서 제목, 거리, 횟수를 분리
  (String title, int? distance, int? count) _parseDescription(String desc) {
    final distanceRegex = RegExp(r'(\d+)\s*[mM]');
    final distanceMatch = distanceRegex.firstMatch(desc);
    int? foundDistance;
    if (distanceMatch != null) {
      foundDistance = int.parse(distanceMatch.group(1)!);
    }

    final countRegex = RegExp(r'[xX]\s*(\d+)\s*개');
    final countMatch = countRegex.firstMatch(desc);
    int? foundCount;
    if (countMatch != null) {
      foundCount = int.parse(countMatch.group(1)!);
    }

    String title = desc;
    if (distanceMatch != null) {
      title = title.replaceFirst(distanceRegex, '');
    }
    if (countMatch != null) {
      title = title.replaceFirst(countRegex, '');
    }
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    return (title, foundDistance, foundCount);
  }

  // description에서 첫 번째 'm' 관련 숫자를 newDistance로 치환
  String _updateDistanceInDescription(String description, int newDistance) {
    return description.replaceFirst(RegExp(r'\d+\s*[mM]'), '${newDistance}m');
  }

  // "쉬는 시간" 판별
  bool _isRestTime(String title) {
    return title.contains("쉬는 시간");
  }

  // description에서 첫 번째 'm' 관련 숫자를 추출
  int _extractDistance(String description) {
    final regExp = RegExp(r'(\d+)\s*[mM]');
    final match = regExp.firstMatch(description);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  void _startTraining() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          trainingDetails: [], // 실제 훈련 데이터를 여기에 전달하세요.
          beepSound: 'assets/ppppig.mp3',
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("퀵스타트 - 세부 훈련 내용 입력"),
      ),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) => _buildStepForm(index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startTraining,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _buildStepForm(int index) {
    final step = steps[index];
    final (title, distance, count) = _parseDescription(step.description);
    final bool isRest = _isRestTime(title);
    final bool adjustable = distance != null && !isRest;

    if (isRest) {
      // 쉬는 시간 단계: 제목은 수정 불가, 시간만 입력 가능
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "단계 ${index + 1}: 쉬는 시간",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: step.duration.toString()),
                decoration: const InputDecoration(labelText: "시간 (초)"),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final dur = int.tryParse(val);
                  if (dur != null) {
                    setState(() {
                      steps[index] = TrainingStep(
                        description: step.description,
                        duration: dur,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else if (adjustable) {
      int currentDistance = _extractDistance(step.description);
      if (currentDistance < kMinDistance.toInt()) currentDistance = kMinDistance.toInt();
      if (currentDistance > kMaxDistance.toInt()) currentDistance = kMaxDistance.toInt();

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("단계 ${index + 1}: $title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (count != null)
                Text("횟수: ${count}개", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              DistancePicker(
                initialDistance: currentDistance,
                minDistance: kMinDistance.toInt(),
                maxDistance: kMaxDistance.toInt(),
                step: kStepSize.toInt(),
                onChanged: (newVal) {
                  setState(() {
                    final updatedDescription = _updateDistanceInDescription(step.description, newVal);
                    steps[index] = TrainingStep(description: updatedDescription, duration: step.duration);
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: step.duration.toString()),
                decoration: const InputDecoration(labelText: "시간 (초)"),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final dur = int.tryParse(val);
                  if (dur != null) {
                    setState(() {
                      steps[index] = TrainingStep(
                        description: steps[index].description,
                        duration: dur,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else {
      final descriptionController = TextEditingController(text: step.description);
      final durationController = TextEditingController(text: step.duration.toString());
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("단계 ${index + 1}: $title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (count != null)
                Text("횟수: ${count}개", style: const TextStyle(fontSize: 16)),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "훈련 내용"),
                onChanged: (val) {
                  setState(() {
                    steps[index] = TrainingStep(description: val, duration: step.duration);
                  });
                },
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: "시간 (초)"),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final dur = int.tryParse(val);
                  if (dur != null) {
                    setState(() {
                      steps[index] = TrainingStep(
                        description: steps[index].description,
                        duration: dur,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
