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
  final void Function(String action)? onEvent; // "start", "pause", "resume", "reset", "cycle_beep"

  Timer? _timer;
  Timer? _restTimer;
  Timer? _nextTrainingNotificationTimer;
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
  int _restTimeRemaining = 0;
  String _restMessage = "";

  final SoundManager _soundManager = SoundManager();

  TGTimerController({
    required this.trainingList,
    required this.beepSound,
    required this.numPeople,
    required this.onUpdate,
    this.onEvent,
  });

  int get currentTrainingIndex => _currentTrainingIndex;
  int get currentCycleIndex => _currentCycleCount;
  int get currentCycleTime => trainingList[_currentTrainingIndex].cycle;
  bool get isFinalCycle => _isFinalCycle;
  bool get isResting => _isResting;
  bool get isPaused => _isPaused;
  bool get isRunning => _isRunning;
  int get restTimeRemaining => _restTimeRemaining;
  String get restMessage => _restMessage;

  String get formattedElapsedTime {
    if (_isResting) {
      return formatTime(_restTimeRemaining * 1000);
    }

    if (_startTime == null) return formatTime(0);
    final now = _isPaused && _pauseStart != null ? _pauseStart! : DateTime.now();
    final elapsed = now.difference(_startTime!) - _pausedDuration;
    return formatTime(elapsed.inMilliseconds);
  }

  String get timerButtonText => !_isRunning ? "시작" : (_isPaused ? "계속" : "정지");

  String get displayTitle {
    if (_isResting) {
      return "쉬는 시간";
    } else if (_currentTrainingIndex < trainingList.length) {
      return trainingList[_currentTrainingIndex].title;
    }
    return "";
  }

  void _playBeep() {
    _soundManager.playSound(beepSound);
    // 비프음 이벤트를 cycle_beep로 표시하여 다른 이벤트와 구분
    onEvent?.call("cycle_beep");
  }

  void startTraining() {
    _isRunning = true;
    _isPaused = false;
    _isFinalCycle = false;
    _isResting = false;
    _currentCycleCount = 0;
    _pausedDuration = Duration.zero;
    _restMessage = "";

    _playBeep(); // 시작음
    // 시작 이벤트
    onEvent?.call("start");

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
    // 현재 훈련 정보 가져오기
    final current = trainingList[_currentTrainingIndex];

    // 쉬는 시간이 있고 다음 훈련이 있을 때만 쉬는 시간 타이머 시작
    if (current.restTime > 0 && _currentTrainingIndex < trainingList.length - 1) {
      _isResting = true;
      _restTimeRemaining = current.restTime;
      onEvent?.call("rest_start");

      // 쉬는 시간 타이머
      _restTimer?.cancel();
      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) return;

        if (_restTimeRemaining > 0) {
          _restTimeRemaining--;

          // 다음 훈련 시작 10초 전 알림
          if (_restTimeRemaining == 10) {
            _restMessage = "10초 후 다음 훈련이 시작됩니다";
            _playBeep(); // 알림음
          }

          onUpdate();
        } else {
          _restTimer?.cancel();
          _isResting = false;
          _restMessage = "";
          _goToNextTraining();
        }
      });
      onUpdate();
    } else {
      _goToNextTraining();
    }
  }

  void _goToNextTraining() {
    _nextTrainingNotificationTimer?.cancel();

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
    _restTimer?.cancel();
    _nextTrainingNotificationTimer?.cancel();
    _cancelScheduledBeeps();
    _soundManager.pauseSound();
    onUpdate();
    onEvent?.call("pause");
  }

  void _resumeTimer() {
    if (_pauseStart != null && _startTime != null && !_isResting) {
      final pauseDuration = DateTime.now().difference(_pauseStart!);
      _pausedDuration += pauseDuration;
    }

    _isPaused = false;
    _pauseStart = null;

    if (_isResting) {
      // 쉬는 시간 타이머 재시작
      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) return;

        if (_restTimeRemaining > 0) {
          _restTimeRemaining--;

          // 다음 훈련 시작 10초 전 알림
          if (_restTimeRemaining == 10) {
            _restMessage = "10초 후 다음 훈련이 시작됩니다";
            _playBeep(); // 알림음
          }

          onUpdate();
        } else {
          _restTimer?.cancel();
          _isResting = false;
          _restMessage = "";
          _goToNextTraining();
        }
      });
    } else {
      _scheduleBeeps();
      _startTimer();
    }

    _soundManager.resumeSound();
    onUpdate();
    onEvent?.call("resume");
  }

  void resetTimer() {
    _timer?.cancel();
    _restTimer?.cancel();
    _nextTrainingNotificationTimer?.cancel();
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
    _restTimeRemaining = 0;
    _restMessage = "";
    onUpdate();
    onEvent?.call("reset");
  }

  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _nextTrainingNotificationTimer?.cancel();
    _cancelScheduledBeeps();
  }
}