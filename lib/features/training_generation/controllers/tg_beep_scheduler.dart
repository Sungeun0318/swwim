// lib/features/training_generation/tg_beep_scheduler.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:swim/features/swimming/models/training_detail_data.dart';
import '../services/tg_sound_manager.dart';


class BeepScheduler {
  final SoundManager _soundManager = SoundManager();
  final List<Timer> _scheduledBeeps = [];
  final Function(String) onEvent;

  // 소리 관련 설정
  final String beepSound;
  final int numPeople;
  bool _isCompleted = false;

  BeepScheduler({
    required this.beepSound,
    required this.numPeople,
    required this.onEvent,
  });

  void playStartBeep() {
    // 소리 크기 향상을 위한 설정
    _soundManager.playSound(beepSound, volume: 1.0);
    onEvent("cycle_beep");

    // 소리가 끊기지 않도록 짧은 지연 후 다시 재생
    Future.delayed(const Duration(milliseconds: 50), () {
      _soundManager.playSound(beepSound, volume: 1.0);
    });
  }


  void setCompleted(bool completed) {
    _isCompleted = completed;
    if (_isCompleted) {
      cancelScheduledBeeps(); // 훈련 완료 시 모든 예약된 비프음 취소
    }
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

    if (startTime == null || _isCompleted) return; // 훈련 완료 시 비프음 예약 안 함

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
      // 마지막 훈련의 마지막 싸이클은 비프음 없음 - 마지막 훈련 체크 강화
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
          // 마지막 훈련의 마지막 싸이클은 비프음 없음 - 로직 수정
          // 마지막 싸이클에서 모든 사람이 출발할 수 있도록 조건 수정
          if (isLastTraining && cycle == totalCycles - 1) {
            continue;
          }

          // 마지막 개수에서 모든 사람이 출발할 수 있도록 로직 수정
          // 모든 사람이 마지막 싸이클을 수행할 수 있도록 함
          if (cycle == totalCycles - 1) {
            // 마지막 싸이클에서는 모든 인원이 출발할 수 있어야 함
            // 출발 간격 * 인원 수가 싸이클 시간보다 크지 않도록 확인
            if (personIndex * intervalMs >= cycleMs) {
              continue; // 이 경우 비프음 예약하지 않음
            }
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
        if (isRunning && !isPaused && !_isCompleted) {
          // 소리가 끊기지 않도록 최대 볼륨으로 설정하고 짧은 지연 후 다시 재생
          _soundManager.playSound(beepSound, volume: 1.0);

          // 짧은 지연 후 다시 재생하여 끊김 방지
          Future.delayed(const Duration(milliseconds: 50), () {
            if (isRunning && !isPaused && !_isCompleted) {
              _soundManager.playSound(beepSound, volume: 1.0);
            }
          });

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