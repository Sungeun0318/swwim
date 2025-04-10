// lib/features/training_generation/tg_beep_scheduler.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:swim/features/training/models/training_detail_data.dart';
import 'tg_sound_manager.dart';


class BeepScheduler {
  final SoundManager _soundManager = SoundManager();
  final List<Timer> _scheduledBeeps = [];
  final Function(String) onEvent;

  // 소리 관련 설정
  final String beepSound;
  final int numPeople;

  BeepScheduler({
    required this.beepSound,
    required this.numPeople,
    required this.onEvent,
  });

  void playStartBeep() {
    _soundManager.playSound(beepSound);
    onEvent("cycle_beep");
  }

  void scheduleBeeps({
    required DateTime? startTime,
    required Duration pausedDuration,
    required TrainingDetailData training,
    required bool isLastTraining,
    required bool isRunning,
    required bool isPaused,
  }) {
    cancelScheduledBeeps(); // 이전 예약 취소

    if (startTime == null) return;

    final intervalMs = training.interval * 1000; // 간격(ms)
    final cycleMs = training.cycle * 1000;      // 싸이클(ms)
    final totalCycles = training.count;         // 총 싸이클 수

    // 현재까지 경과한 시간 계산 (일시정지 시간 고려)
    final now = DateTime.now();
    final elapsedMs = now.difference(startTime).inMilliseconds - pausedDuration.inMilliseconds;

    // 모든 비프음 시간을 저장할 Set (중복 제거를 위해 Set 사용)
    final Set<int> beepTimes = {};

    // 1. 첫 번째 사람의 각 싸이클 비프음 (2.75초 전에 울림)
    for (int cycle = 1; cycle <= totalCycles; cycle++) {
      // 마지막 훈련의 마지막 싸이클은 비프음 없음
      if (isLastTraining && cycle == totalCycles) {
        continue;
      }

      int beepTimepoint = (cycleMs * cycle);
      int timeUntilBeep = beepTimepoint - elapsedMs - 2750;

      // 아직 울리지 않은 비프음만 예약 (양수 값)
      if (timeUntilBeep > 0) {
        beepTimes.add(timeUntilBeep);
      }
    }

    // 2. 2명 이상일 경우에만 추가 비프음
    if (numPeople > 1) {
      // 각 사람에 대한 시작 시간 계산 (1번 사람은 0초, 2번 사람은 interval초, ...)
      for (int personIndex = 1; personIndex < numPeople; personIndex++) {
        // 각 사람의 첫 시작 시간
        int personStartTime = intervalMs * personIndex;

        // 이 사람의 각 싸이클에 대한 비프음
        for (int cycle = 0; cycle < totalCycles; cycle++) {
          // 마지막 훈련의 마지막 싸이클은 비프음 없음
          if (isLastTraining && cycle == totalCycles - 1) {
            continue;
          }

          int beepTimepoint = personStartTime + (cycleMs * cycle);
          int timeUntilBeep = beepTimepoint - elapsedMs - 2750;

          // 아직 울리지 않은 비프음만 예약 (양수 값)
          if (timeUntilBeep > 0) {
            beepTimes.add(timeUntilBeep);
          }
        }
      }
    }

    // 모든 비프음 시간을 정렬하고 타이머 예약
    final List<int> sortedBeepTimes = beepTimes.toList()..sort();

    if (kDebugMode) {
      print("예약된 비프음 횟수: ${sortedBeepTimes.length}");
    }

    for (final delay in sortedBeepTimes) {
      final t = Timer(Duration(milliseconds: delay), () {
        if (isRunning && !isPaused) {
          _soundManager.playSound(beepSound);
          onEvent("cycle_beep");
          if (kDebugMode) {
            print("비프음 재생: 시작 후 ${delay + elapsedMs}ms");
          }
        }
      });
      _scheduledBeeps.add(t);
    }
  }

  void cancelScheduledBeeps() {
    for (final t in _scheduledBeeps) {
      t.cancel();
    }
    _scheduledBeeps.clear();
  }

  void pauseSound() {
    _soundManager.pauseSound();
  }

  void resumeSound() {
    _soundManager.resumeSound();
  }

  void dispose() {
    cancelScheduledBeeps();
    _soundManager.dispose();
  }
}