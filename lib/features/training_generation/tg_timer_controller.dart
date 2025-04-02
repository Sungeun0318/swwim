import 'dart:async';
import 'package:flutter/material.dart';
import 'tg_sound_manager.dart';
import 'tg_format_time.dart';
import 'package:swim/features/training/models/training_detail_data.dart';

class TGTimerController {
  final List<TrainingDetailData> trainingList;
  final String beepSound;
  final int numPeople;
  final VoidCallback onUpdate;

  Timer? _timer;
  final List<Timer> _scheduledBeeps = [];

  DateTime? _startTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStart;

  int _currentTrainingIndex = 0;
  int _currentCycleCount = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFinalCycle = false;
  bool _isResting = false;

  final SoundManager _soundManager = SoundManager();

  TGTimerController({
    required this.trainingList,
    required this.beepSound,
    required this.numPeople,
    required this.onUpdate,
  });

  int get currentTrainingIndex => _currentTrainingIndex;
  int get currentCycleIndex => _currentCycleCount;
  int get currentCycleTime => trainingList[_currentTrainingIndex].cycle;
  bool get isFinalCycle => _isFinalCycle;
  bool get isResting => _isResting;
  bool get isPaused => _isPaused;
  bool get isRunning => _isRunning;

  String get formattedElapsedTime {
    if (_startTime == null) return formatTime(0);
    final now = _isPaused && _pauseStart != null ? _pauseStart! : DateTime.now();
    final elapsed = now.difference(_startTime!) - _pausedDuration;
    return formatTime(elapsed.inMilliseconds);
  }

  String get timerButtonText => !_isRunning ? "시작" : (_isPaused ? "계속" : "정지");

  void _playBeep() {
    _soundManager.playSound(beepSound);
  }

  void startTraining() {
    _isRunning = true;
    _isPaused = false;
    _isFinalCycle = false;
    _isResting = false;
    _currentCycleCount = 0;
    _pausedDuration = Duration.zero;

    _playBeep(); // 시작음
    Future.delayed(const Duration(milliseconds: 2750), () {
      if (_isRunning && !_isPaused) {
        _startTime = DateTime.now();
        _scheduleBeeps(); // 비프 타이머 예약
        _startTimer();     // 타이머 시작
        onUpdate();
      }
    });
  }

  void _startTimer() {
    final training = trainingList[_currentTrainingIndex];
    final cycleMs = training.cycle * 1000;
    final totalCycles = training.count;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused || _startTime == null) return;

      final now = DateTime.now();
      final elapsedMs = now.difference(_startTime!).inMilliseconds - _pausedDuration.inMilliseconds;

      // 싸이클 증가
      int cycleIndex = elapsedMs ~/ cycleMs;
      if (cycleIndex != _currentCycleCount) {
        _currentCycleCount = cycleIndex;
        onUpdate();
      }

      // 훈련 종료
      if (_currentCycleCount >= totalCycles) {
        _timer?.cancel();
        _goToRestOrNextTraining();
      }

      onUpdate();
    });
  }

  void _scheduleBeeps() {
    _cancelScheduledBeeps(); // 이전 예약 취소

    final training = trainingList[_currentTrainingIndex];
    final intervalMs = training.interval * 1000;
    final cycleMs = training.cycle * 1000;
    final totalCycles = training.count;

    // 간격 기반 음
    if (numPeople > 1) {
      for (int i = 1; i < numPeople; i++) {
        int delay = (intervalMs * i) - 2750;
        if (delay >= 0) {
          final t = Timer(Duration(milliseconds: delay), () {
            if (_isRunning && !_isPaused) _playBeep();
          });
          _scheduledBeeps.add(t);
        }
      }
    }

    // 싸이클 반복 음
    for (int i = 1; i <= totalCycles; i++) {
      int delay = (cycleMs * i) - 2750;
      if (delay >= 0) {
        final t = Timer(Duration(milliseconds: delay), () {
          if (_isRunning && !_isPaused) _playBeep();
        });
        _scheduledBeeps.add(t);
      }
    }
  }

  void _cancelScheduledBeeps() {
    for (final t in _scheduledBeeps) {
      t.cancel();
    }
    _scheduledBeeps.clear();
  }

  void _goToRestOrNextTraining() {
    final current = trainingList[_currentTrainingIndex];
    if (current.restTime > 0) {
      _isResting = true;
      onUpdate();
      Future.delayed(Duration(seconds: current.restTime), () {
        _isResting = false;
        _goToNextTraining();
      });
    } else {
      _goToNextTraining();
    }
  }

  void _goToNextTraining() {
    if (_currentTrainingIndex < trainingList.length - 1) {
      _currentTrainingIndex++;
      _currentCycleCount = 0;
      _startTime = null;
      startTraining();
    } else {
      _isRunning = false;
      _isFinalCycle = true;
      onUpdate();
    }
  }

  void toggleTimer() {
    if (!_isRunning) {
      startTraining();
    } else if (_isPaused) {
      _resumeTimer();
    } else {
      _pauseTimer();
    }
  }

  void _pauseTimer() {
    _isPaused = true;
    _pauseStart = DateTime.now();
    _timer?.cancel();
    _cancelScheduledBeeps();
    _soundManager.pauseSound();
    onUpdate();
  }

  void _resumeTimer() {
    if (_pauseStart != null && _startTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStart!);
      _pausedDuration += pauseDuration;
    }
    _isPaused = false;
    _pauseStart = null;
    _scheduleBeeps();
    _startTimer();
    _soundManager.resumeSound();
    onUpdate();
  }

  void resetTimer() {
    _timer?.cancel();
    _cancelScheduledBeeps();
    _isRunning = false;
    _isPaused = false;
    _isFinalCycle = false;
    _isResting = false;
    _currentCycleCount = 0;
    _currentTrainingIndex = 0;
    _startTime = null;
    _pauseStart = null;
    _pausedDuration = Duration.zero;
    onUpdate();
  }

  void dispose() {
    _timer?.cancel();
    _cancelScheduledBeeps();
  }
}
