// lib/features/training/screens/timer_screen.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/training_detail_data.dart';

class TimerScreen extends StatefulWidget {
  final List<TrainingDetailData> trainingDetails;
  final String beepSound;

  const TimerScreen({
    Key? key,
    required this.trainingDetails,
    required this.beepSound,
  }) : super(key: key);

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int currentStepIndex = 0;
  late int totalDuration; // 총 지속 시간 (초)
  late int remainingSeconds;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if (widget.trainingDetails.isNotEmpty) {
      _initializeStep();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 현재 훈련 단계의 데이터를 기반으로 총 지속 시간과 남은 시간을 초기화합니다.
  void _initializeStep() {
    final data = widget.trainingDetails[currentStepIndex];
    // 예시 공식: 총 지속 시간 = (싸이클 시간 * 개수) + 쉬는 시간
    // 실제 공식은 요구사항에 맞게 조정하세요.
    totalDuration = (data.cycle * data.count) + data.restTime;
    if (totalDuration <= 0) totalDuration = 1;
    remainingSeconds = totalDuration;
  }

  // 1초 간격으로 타이머를 진행합니다.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          timer.cancel();
          // 다음 훈련 단계로 전환
          if (currentStepIndex < widget.trainingDetails.length - 1) {
            currentStepIndex++;
            _initializeStep();
            _startTimer();
          } else {
            // 모든 단계 완료
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("모든 훈련 단계 완료")),
            );
          }
        }
      });
    });
  }

  // 음성 재생 (beepSound 파일)
  Future<void> _playBeep() async {
    String soundFile = widget.beepSound.replaceFirst('assets/', '');
    await _audioPlayer.play(AssetSource(soundFile));
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = currentStepIndex < widget.trainingDetails.length
        ? widget.trainingDetails[currentStepIndex].title
        : "훈련 완료";
    return Scaffold(
      appBar: AppBar(
        title: Text("훈련: $currentTitle"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "남은 시간: $remainingSeconds 초",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: totalDuration > 0 ? remainingSeconds / totalDuration : 0,
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }
}
