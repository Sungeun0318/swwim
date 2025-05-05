// lib/screens/training_level_selection_screen.dart

import 'package:flutter/material.dart';
import 'timer_screen.dart';
import '../models/training_step.dart';

class TrainingLevelSelectionScreen extends StatefulWidget {
  const TrainingLevelSelectionScreen({Key? key}) : super(key: key);

  @override
  _TrainingLevelSelectionScreenState createState() =>
      _TrainingLevelSelectionScreenState();
}

class _TrainingLevelSelectionScreenState
    extends State<TrainingLevelSelectionScreen> {
  String? _selectedLevel;

  // 각 레벨에 따른 훈련 단계 목록을 반환하는 함수
  List<TrainingStep> getStepsForLevel(String level) {
    if (level == "초급") {
      return [
        TrainingStep(description: "걷기로 몸풀기 50m", duration: 180), // 3분
        TrainingStep(
            description: "원터치 + 6박자 쉬고 물잡기 자유형 25m X 6개",
            duration: 300), // 50초 x 6
        TrainingStep(
            description: "원터치 자유형 25M X 6개", duration: 300), // 50초 x 6
        TrainingStep(description: "한바퀴 걸어갔다오면 쉬기 50M", duration: 180),
        TrainingStep(
            description: "배영 차렷 발차기 25m 3개", duration: 165), // 55초 x 3
        TrainingStep(
            description: "배영 만세 발차기 25m 3개", duration: 165), // 55초 x 3
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "배영 팔돌리기 25M 5개", duration: 275), // 55초 x 5
        TrainingStep(description: "75m 걷기", duration: 270), // 4분30초
      ];
    } else if (level == "중급") {
      return [
        TrainingStep(description: "걷기로 몸풀기 50m", duration: 180),
        TrainingStep(
            description: "자유형 팔돌리기 25M 6개", duration: 300), // 50초 x 6
        TrainingStep(
            description: "배영 팔돌리기 25m 6개", duration: 300), // 50초 x 6
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "평영 발차기 25m 4개", duration: 200), // 50초 x 4
        TrainingStep(description: "손동작만 하며 걷기 50M", duration: 240), // 4분
        TrainingStep(
            description: "평영 손발 콤비 25m 6개", duration: 360), // 1분 x 6
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "접영 차렷 발차기 25M 4개", duration: 240), // 1분 x 4
        TrainingStep(
            description: "접영 웨이브+팔돌리기 25m 6개", duration: 420), // 1분10초 x 6
        TrainingStep(
            description: "접영 콤비 맞추기 25m 4개", duration: 240), // 1분 x 4
        TrainingStep(description: "마무리 운동 걷기 100m", duration: 300), // 5분
      ];
    } else if (level == "상급") {
      return [
        TrainingStep(description: "자유형 몸풀기 200m", duration: 300), // 5분
        TrainingStep(
            description: "개인 혼영 100m 4개", duration: 720), // 3분 x 4
        TrainingStep(
            description: "no board 자유형 발차기 50m 6개", duration: 660), // 1분50초 x 6
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "자세 교정 훈련 300m", duration: 480), // 8분
        TrainingStep(
            description: "접영-배영, 배영-평영, 평영-자유형, 자유형-접영 50m 4개 2세트",
            duration: 720), // 1분30초 x 8
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(description: "접영 25m 2개", duration: 80), // 40초 x 2
        TrainingStep(description: "배영 25m 2개", duration: 80), // 40초 x 2
        TrainingStep(description: "평영 25m 2개", duration: 80), // 40초 x 2
        TrainingStep(description: "자유형 25m 2개", duration: 80), // 40초 x 2
        TrainingStep(description: "마무리 운동 걷기 100m", duration: 180), // 3분
      ];
    } else if (level == "마스터") {
      return [
        TrainingStep(description: "워밍업 자유형 400m", duration: 600), // 10분
        TrainingStep(
            description: "IM 100m 2개", duration: 300), // 2분30초 x 2
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "no board 킥 50m 6개", duration: 540), // 1분30초 x 6
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "길게 풀 100m 2개", duration: 300), // 2분30초 x 2
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "자유형 100m 3개", duration: 450), // 2분30초 x 3
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "자세 교정 훈련 300m", duration: 480), // 8분
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "자기 종목 인터벌 트레이닝 50m 4개", duration: 80), // 1분20초
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "자기 종목 인터벌 트레이닝 100m 4개", duration: 640), // 2분40초 x 4
        TrainingStep(description: "쉬는 시간", duration: 60),
        TrainingStep(
            description: "스프린트 훈련 25m 4개", duration: 240), // 1분 x 4
        TrainingStep(description: "마무리 운동 200", duration: 180), // 3분 (가정)
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("훈련 단계 선택"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: ["초급", "중급", "상급", "마스터"].map((level) {
                return RadioListTile<String>(
                  title: Text(level),
                  value: level,
                  groupValue: _selectedLevel,
                  onChanged: (val) {
                    setState(() {
                      _selectedLevel = val;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _selectedLevel == null
                ? null
                : () {
              List<TrainingStep> selectedSteps = getStepsForLevel(_selectedLevel!);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TimerScreen(
                    trainingDetails: [], // 또는 실제 훈련 데이터를 전달하세요.
                    beepSound: 'assets/ppppig.mp3',
                  ),
                ),
              );

            },
            child: const Text("다음"),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
