// lib/features/training_generation/tg_timer_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/tg_sound_manager.dart';
import '../utils/tg_format_time.dart';
import 'package:swim/features/swimming/models/training_detail_data.dart';

class TGTimerController {
  final List<TrainingDetailData> trainingList;
  final String beepSound;
  final int numPeople;
  final VoidCallback onUpdate;
  final void Function(String action)? onEvent; // "start", "pause", "resume", "reset", "cycle_beep", "complete"

  Timer? _timer;
  Timer? _restTimer;
  Timer? _nextTrainingNotificationTimer;
  final List<Timer> _scheduledBeeps = [];

  DateTime? _startTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStart;
  DateTime? _stopTime;

  int _currentTrainingIndex = 0;
  int _currentCycleCount = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFinalCycle = false;
  bool _isResting = false;
  int _restTimeRemaining = 0;
  String _restMessage = "";
  bool _isCompleted = false;
  bool _isFirstStart = true; // 첫 시작 여부 추가

  final SoundManager _soundManager = SoundManager();
  double? _lastTotalProgress; // 마지막으로 계산된 총 진행률
  double? _lastCurrentProgress; // 마지막으로 계산된 현재 진행률

  TGTimerController({
    required this.trainingList,
    required this.beepSound,
    required this.numPeople,
    required this.onUpdate,
    this.onEvent,
  });

  int get currentTrainingIndex => _currentTrainingIndex;
  int get currentCycleIndex => _currentCycleCount;
  int get currentCycleTime => _currentTrainingIndex < trainingList.length ? trainingList[_currentTrainingIndex].cycle : 0;
  bool get isFinalCycle => _isFinalCycle;
  bool get isResting => _isResting;
  bool get isPaused => _isPaused;
  bool get isRunning => _isRunning;
  int get restTimeRemaining => _restTimeRemaining;
  String get restMessage => _restMessage;
  bool get isCompleted => _isCompleted;

  // 총 훈련 진행률 (0.0 ~ 1.0) - 쉬는 시간 포함
  double get totalProgress {
    if (trainingList.isEmpty) return 0.0;
    if (_isCompleted) return 1.0; // 완료 시 항상 100%
    if (_isPaused) return _lastTotalProgress ?? 0.0; // 일시정지 상태면 마지막 진행도 반환

    // 완료된 훈련들의 총 시간 (쉬는 시간 포함)
    int completedTime = 0;
    for (int i = 0; i < _currentTrainingIndex; i++) {
      // 각 훈련의 실제 진행 시간
      completedTime += trainingList[i].cycle * trainingList[i].count;
      // 쉬는 시간 추가 (마지막 훈련 제외)
      if (i < trainingList.length - 1) {
        completedTime += trainingList[i].restTime;
      }
    }

    // 현재 훈련의 진행 시간
    int currentTrainingProgress = 0;
    if (_isResting) {
      // 현재 훈련의 사이클 시간은 모두 완료
      final current = trainingList[_currentTrainingIndex];
      currentTrainingProgress = current.cycle * current.count;
      // 쉬는 시간 진행도 추가 (총 쉬는 시간 - 남은 시간)
      currentTrainingProgress += (current.restTime - _restTimeRemaining);
    } else if (_startTime != null) {
      // 현재 훈련의 진행 시간 (최대 사이클 시간까지)
      final current = trainingList[_currentTrainingIndex];
      final elapsed = DateTime.now().difference(_startTime!) - _pausedDuration;
      final maxCycleTime = current.cycle * current.count;
      currentTrainingProgress = elapsed.inSeconds.clamp(0, maxCycleTime);
    }

    // 전체 시간 계산 (쉬는 시간 포함)
    int totalTime = 0;
    for (int i = 0; i < trainingList.length; i++) {
      // 각 훈련의 실제 진행 시간
      totalTime += trainingList[i].cycle * trainingList[i].count;
      // 쉬는 시간 추가 (마지막 훈련 제외)
      if (i < trainingList.length - 1) {
        totalTime += trainingList[i].restTime;
      }
    }

    if (totalTime == 0) return 1.0; // 예외 처리

    if (kDebugMode) {
      print("총 시간(쉬는시간포함): $totalTime초");
      print("완료 시간: $completedTime초, 현재 진행: $currentTrainingProgress초");
      print("총 진행률: ${(completedTime + currentTrainingProgress) / totalTime * 100}%");
    }

    final progress = (completedTime + currentTrainingProgress) / totalTime;
    _lastTotalProgress = progress.clamp(0.0, 1.0); // 진행도가 100%를 넘지 않도록
    return _lastTotalProgress!;
  }

  // 현재 훈련의 진행률 (0.0 ~ 1.0)
  double get currentProgress {
    if (_isCompleted) return 1.0;
    if (trainingList.isEmpty) return 0.0;
    if (_isPaused) return _lastCurrentProgress ?? 0.0; // 일시정지 상태면 마지막 진행도 반환

    final current = trainingList[_currentTrainingIndex];

    if (_isResting) {
      // 쉬는 시간 진행률 계산
      if (current.restTime <= 0) return 1.0;
      final progress = 1.0 - (_restTimeRemaining / current.restTime);
      _lastCurrentProgress = progress.clamp(0.0, 1.0); // 0~1 범위 보장
      return _lastCurrentProgress!;
    }

    if (_startTime == null) return 0.0;

    final totalCycleTime = current.cycle * current.count;
    if (totalCycleTime <= 0) return 0.0;

    final elapsed = DateTime.now().difference(_startTime!) - _pausedDuration;
    final progress = (elapsed.inMilliseconds / (totalCycleTime * 1000));
    _lastCurrentProgress = progress.clamp(0.0, 1.0); // 0~1 범위 보장
    return _lastCurrentProgress!;
  }

  String get formattedElapsedTime {
    if (_isResting) {
      return formatTime(_restTimeRemaining * 1000);
    }

    if (_startTime == null) return formatTime(0);

    // 완료 상태일 때는 stopTime 사용
    final now = _isCompleted ? _stopTime! :
    (_isPaused && _pauseStart != null ? _pauseStart! : DateTime.now());
    final elapsed = now.difference(_startTime!) - _pausedDuration;
    return formatTime(elapsed.inMilliseconds);
  }

  // 현재 훈련의 남은 시간
  String get formattedRemainingTime {
    if (_isCompleted) return "00:00:00.00"; // 완료 시 항상 0 표시
    if (_isResting) {
      return formatTime(_restTimeRemaining * 1000);
    }

    if (_startTime == null || _currentTrainingIndex >= trainingList.length) {
      return formatTime(0);
    }

    final current = trainingList[_currentTrainingIndex];
    final totalTime = current.cycle * current.count * 1000; // 총 시간 (밀리초)

    final now = _isPaused && _pauseStart != null ? _pauseStart! : DateTime.now();
    final elapsed = now.difference(_startTime!) - _pausedDuration;

    final remaining = totalTime - elapsed.inMilliseconds;
    return formatTime(remaining > 0 ? remaining : 0);
  }

  int calculateTotalTime() {
    int total = 0;
    for (var training in trainingList) {
      // cycle * count는 순수 훈련 시간
      total += training.cycle * training.count;
      // 쉬는 시간 포함 (마지막 훈련은 쉬는 시간 없음)
      if (trainingList.indexOf(training) < trainingList.length - 1) {
        total += training.restTime;
      }
    }
    return total;
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

  // 쉬는 시간용 이벤트 발생 메서드 (소리는 TGTimerScreen에서 처리)
  void _triggerRestBeep() {
    onEvent?.call("rest_beep");
  }

  // 훈련 완료용 이벤트 발생 메서드 (소리는 TGTimerScreen에서 처리)
  void _triggerCompleteBeep() {
    onEvent?.call("complete_beep");
  }

  // 타이머 시작 메서드
  void startTraining() {
    // 이미 모든 훈련이 완료되었으면 시작하지 않음
    if (_isCompleted) {
      onUpdate();
      return;
    }

    _isRunning = true;
    _isPaused = false;
    _isFinalCycle = false;
    _currentCycleCount = 0;
    _pausedDuration = Duration.zero;
    _restMessage = "";

    // 첫 훈련인 경우 바로 시작
    if (_currentTrainingIndex == 0) {
      _isResting = false;
      _startActualTraining();
    } else {
      // 두 번째 훈련부터는 쉬는 시간부터 시작
      _startRestBeforeTraining();
    }
  }

  // 실제 훈련 시작
  void _startActualTraining() {
    if (_isCompleted) return; // 완료 상태면 시작하지 않음

    _isResting = false;

    // 첫 번째 훈련의 첫 시작이 아닐 때만 비프음 재생
    if (!_isFirstStart) {
      _playBeep(); // 시작음
    }

    // 시작 이벤트
    onEvent?.call("start");

    // 첫 시작이면 바로 타이머 시작, 아니면 2.75초 후 시작
    if (_isFirstStart) {
      _isFirstStart = false; // 첫 시작 플래그 해제
      _startTime = DateTime.now();
      _scheduleBeeps(); // 비프 타이머 예약
      _startTimer();    // 타이머 시작
      onUpdate();
    } else {
      Future.delayed(const Duration(milliseconds: 2750), () {
        // 지연 시간 동안 상태가 변경됐을 수 있으므로 다시 확인
        if (!_isRunning || _isPaused || _isCompleted) {
          return;
        }

        _startTime = DateTime.now();
        _scheduleBeeps(); // 비프 타이머 예약
        _startTimer();    // 타이머 시작
        onUpdate();
      });
    }
  }

  // 쉬는 시간 시작
  void _startRestBeforeTraining() {
    // 현재 훈련의 쉬는 시간 가져오기
    final current = trainingList[_currentTrainingIndex];

    // 쉬는 시간이 0초이면 바로 다음 훈련 시작
    if (current.restTime <= 0) {
      _startActualTraining();
      return;
    }

    _isResting = true;
    _restTimeRemaining = current.restTime;

    if (kDebugMode) {
      print("쉬는 시간 시작: ${_restTimeRemaining}초, isResting: $_isResting");
    }

    // 쉬는 시간 시작 시 전용 비프음 이벤트 발생
    _triggerRestBeep();

    // 휴식 시작 이벤트
    onEvent?.call("rest_start");
    onUpdate();

    // 쉬는 시간 중 다음 훈련 시작 준비 비프음 예약 (2.75초 전)
    if (_restTimeRemaining > 3) { // 3초보다 길 때만 예약
      Timer(Duration(milliseconds: (_restTimeRemaining * 1000) - 2750), () { // 정확히 2.75초 전
        if (_isResting && !_isPaused && !_isCompleted) {
          _playBeep(); // 다음 훈련 준비 비프음
          if (kDebugMode) {
            print("다음 훈련 준비 비프음 (2.75초 전)");
          }
        }
      });
    }

    // 쉬는 시간 카운트다운 타이머 (1초마다)
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _isCompleted) return; // 완료 시 타이머 중지

      if (_restTimeRemaining > 0) {
        _restTimeRemaining--;
        onUpdate(); // UI 업데이트 (카운트다운 표시)
      } else {
        _restTimer?.cancel();
        _isResting = false;
        _restMessage = "";

        if (kDebugMode) {
          print("쉬는 시간 종료, isResting: $_isResting");
        }

        // 쉬는 시간 끝나면 바로 훈련 시작 (지연 없이 즉시)
        if (!_isCompleted) {
          _startTime = DateTime.now(); // 바로 시작 시간 설정
          _scheduleBeeps(); // 비프 타이머 예약
          _startTimer();    // 타이머 바로 시작
          onEvent?.call("start"); // 시작 이벤트
          onUpdate();
        }
      }
    });
  }

  void _scheduleBeeps() {
    _cancelScheduledBeeps(); // 이전 예약 취소

    if (_startTime == null) {
      if (kDebugMode) {
        print("경고: _startTime이 null입니다");
      }
      return;
    }

    final training = trainingList[_currentTrainingIndex];
    final intervalMs = training.interval * 1000; // 간격(ms)
    final cycleMs = training.cycle * 1000;      // 싸이클(ms)
    final totalCycles = training.count;         // 총 싸이클 수

    // 현재까지 경과한 시간 계산 (일시정지 시간 고려)
    final now = DateTime.now();
    final elapsedMs = now.difference(_startTime!).inMilliseconds - _pausedDuration.inMilliseconds;

    // 모든 비프음 시간을 저장할 Set (중복 제거를 위해 Set 사용)
    final Set<int> beepTimes = {};

    // 각 사람별로 비프음 스케줄 계산
    for (int personIndex = 0; personIndex < numPeople; personIndex++) {
      // 각 사람의 시작 시간 (0번 사람은 0초, 1번 사람은 interval초, ...)
      int personStartTime = intervalMs * personIndex;

      // 이 사람의 각 싸이클에 대한 비프음
      for (int cycle = 0; cycle < totalCycles; cycle++) {
        // 각 사이클의 시작 시간 계산
        int cycleStartTime = personStartTime + (cycleMs * cycle);

        // 비프음은 싸이클 시작 2.75초 전에 울림
        int beepTime = cycleStartTime - 2750;

        // 이미 지난 시간이면 예약하지 않음
        int timeUntilBeep = beepTime - elapsedMs;
        if (timeUntilBeep > 0) {
          beepTimes.add(timeUntilBeep);

          if (kDebugMode) {
            print("비프음 예약 - 사람: ${personIndex + 1}/${numPeople}, 싸이클: ${cycle + 1}/${totalCycles}, ${timeUntilBeep}ms 후");
          }
        }
      }
    }

    // 모든 비프음 시간을 정렬하고 타이머 예약
    final List<int> sortedBeepTimes = beepTimes.toList()..sort();

    if (kDebugMode) {
      print("총 예약된 비프음 횟수: ${sortedBeepTimes.length}");
    }

    for (final delay in sortedBeepTimes) {
      final t = Timer(Duration(milliseconds: delay), () {
        if (_isRunning && !_isPaused && !_isCompleted) {
          _playBeep();
          if (kDebugMode) {
            print("비프음 재생: ${delay}ms");
          }
        }
      });
      _scheduledBeeps.add(t);
    }
  }

  void _cancelScheduledBeeps() {
    for (final t in _scheduledBeeps) {
      t.cancel();
    }
    _scheduledBeeps.clear();
  }

  void _startTimer() {
    if (_currentTrainingIndex >= trainingList.length) {
      _completeAllTraining();
      return;
    }

    final training = trainingList[_currentTrainingIndex];
    final cycleMs = training.cycle * 1000;
    final totalCycles = training.count;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused || _startTime == null) return;

      final now = DateTime.now();
      final elapsedMs = now.difference(_startTime!).inMilliseconds - _pausedDuration.inMilliseconds;

      // 현재 싸이클 계산
      int currentCycle = elapsedMs ~/ cycleMs;

      // 싸이클이 변경되었을 때만 업데이트
      if (currentCycle != _currentCycleCount && currentCycle < totalCycles) {
        _currentCycleCount = currentCycle;
        if (kDebugMode) {
          print("현재 싸이클: ${_currentCycleCount + 1}/$totalCycles");
        }
      }

      // 훈련 종료 조건
      if (elapsedMs >= cycleMs * totalCycles) {
        timer.cancel();
        _timer = null;
        _currentCycleCount = totalCycles - 1;
        _goToRestOrNextTraining();
        return;
      }

      onUpdate();
    });
  }

  void _completeAllTraining() {
    // 모든 타이머 중지
    _timer?.cancel();
    _timer = null;
    _restTimer?.cancel();
    _restTimer = null;
    _nextTrainingNotificationTimer?.cancel();
    _nextTrainingNotificationTimer = null;
    _cancelScheduledBeeps();

    // 상태 업데이트
    _isRunning = false;
    _isPaused = false;
    _isFinalCycle = true;
    _isResting = false;
    _isCompleted = true;

    // 완료 시 프로그레스바를 100%로 설정
    _lastTotalProgress = 1.0;
    _lastCurrentProgress = 1.0;

    // 시계 멈추기 위해 현재 시간 저장
    _stopTime = DateTime.now();

    // 완료 비프음 재생
    _triggerCompleteBeep();

    // 완료 이벤트 발생 (자동 화면 이동 제거)
    onEvent?.call("complete");

    onUpdate();
  }

  // 훈련 이동 메서드
  void _goToNextTraining() {
    _nextTrainingNotificationTimer?.cancel();

    if (_currentTrainingIndex < trainingList.length - 1) {
      _currentTrainingIndex++;
      _currentCycleCount = 0;

      // 다음 훈련을 위해 상태 초기화
      _startTime = null;
      _pausedDuration = Duration.zero;
      _isResting = false;
      _restMessage = "";

      if (kDebugMode) {
        print("다음 훈련으로 이동: ${_currentTrainingIndex + 1}/${trainingList.length}");
      }

      startTraining(); // 다시 시작 (쉬는 시간부터)
    } else {
      _completeAllTraining();
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

    // 현재 진행률 저장
    _lastTotalProgress = totalProgress;
    _lastCurrentProgress = currentProgress;

    _timer?.cancel();
    _restTimer?.cancel();
    _nextTrainingNotificationTimer?.cancel();
    _cancelScheduledBeeps();
    _soundManager.pauseSound();
    onUpdate();
    onEvent?.call("pause");
  }

  void _resumeTimer() {
    if (_pauseStart != null && _startTime != null) {
      // 일시정지 지속 시간 계산
      final pauseDuration = DateTime.now().difference(_pauseStart!);
      _pausedDuration += pauseDuration;
    }

    _isPaused = false;
    _pauseStart = null;

    if (_isResting) {
      // 쉬는 시간 타이머 재시작 (카운트다운 방식)
      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) return;

        if (_restTimeRemaining > 0) {
          _restTimeRemaining--;
          onUpdate(); // UI 업데이트 (카운트다운 표시)
        } else {
          _restTimer?.cancel();
          _isResting = false;
          _restMessage = "";

          if (_currentTrainingIndex == 0) {
            _goToNextTraining();
          } else {
            _startActualTraining(); // 쉬는 시간 후 훈련 시작
          }
        }
      });
    } else {
      // 기존 비프음 취소 및 새로운 비프음 예약
      _cancelScheduledBeeps();
      _scheduleBeeps();

      // 타이머 재시작
      _startTimer();
    }

    _soundManager.resumeSound();
    onUpdate();
    onEvent?.call("resume");
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    _restTimer?.cancel();
    _restTimer = null;
    _nextTrainingNotificationTimer?.cancel();
    _nextTrainingNotificationTimer = null;
    _lastTotalProgress = null;
    _lastCurrentProgress = null;
    _cancelScheduledBeeps();

    _isRunning = false;
    _isPaused = false;
    _isFinalCycle = false;
    _isResting = false;
    _isCompleted = false;
    _currentCycleCount = 0;
    _currentTrainingIndex = 0;
    _startTime = null;
    _pauseStart = null;
    _pausedDuration = Duration.zero;
    _restTimeRemaining = 0;
    _restMessage = "";
    _isFirstStart = true; // 리셋 시 첫 시작 플래그 복구

    onUpdate();
    onEvent?.call("reset");
  }

  void _goToRestOrNextTraining() {
    // 현재 훈련 정보 가져오기
    final current = trainingList[_currentTrainingIndex];

    // 쉬는 시간이 있고 다음 훈련이 있을 때만 쉬는 시간 타이머 시작
    if (current.restTime > 0 && _currentTrainingIndex < trainingList.length - 1) {
      _isResting = true;
      _restTimeRemaining = current.restTime;

      // 쉬는 시간 시작 시 전용 비프음 이벤트 발생
      _triggerRestBeep();

      onEvent?.call("rest_start");

      // 쉬는 시간 중 다음 훈련 시작 준비 비프음 예약 (정확히 2.75초 전)
      Timer? preparationBeepTimer;
      Timer? screenChangeTimer;
      if (_restTimeRemaining > 3) { // 3초보다 길 때만 예약
        preparationBeepTimer = Timer(Duration(milliseconds: (_restTimeRemaining * 1000) - 2750), () { // 2.75초 전
          if (_isResting && !_isPaused && !_isCompleted) {
            _playBeep(); // 다음 훈련 준비 비프음
            if (kDebugMode) {
              print("다음 훈련 준비 비프음 (2.75초 전)");
            }
          }
        });

        // 쉬는 시간 끝나기 0.5초 전에 화면 전환
        screenChangeTimer = Timer(Duration(milliseconds: (_restTimeRemaining * 1000) - 500), () { // 0.5초 전
          if (_isResting && !_isPaused && !_isCompleted) {
            onEvent?.call("screen_transition"); // 화면 전환 이벤트
            if (kDebugMode) {
              print("화면 전환 이벤트 (0.5초 전)");
            }
          }
        });
      }

      // 쉬는 시간 카운트다운 타이머 (1초마다)
      _restTimer?.cancel();
      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) {
          preparationBeepTimer?.cancel();
          screenChangeTimer?.cancel();
          return;
        }

        if (_restTimeRemaining > 0) {
          _restTimeRemaining--;
          onUpdate(); // UI 업데이트 (카운트다운 표시)
        } else {
          _restTimer?.cancel();
          preparationBeepTimer?.cancel();
          screenChangeTimer?.cancel();

          // 이미 화면 전환이 안 됐다면 지금 전환
          if (_isResting) {
            _isResting = false;
          }
          _restMessage = "";
          _goToNextTraining();
        }
      });
      onUpdate();
    } else {
      _goToNextTraining();
    }
  }

  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _nextTrainingNotificationTimer?.cancel();
    _cancelScheduledBeeps();
    _soundManager.dispose();
  }
}