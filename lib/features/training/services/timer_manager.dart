import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class TimerManager {
  final int beepInterval; // 초 단위 (사용자가 설정한 값)
  final String beepSound;

  bool isRunning = false;
  bool isStopped = false;
  bool _isPaused = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Duration> timeLine = [];

  late Timer _timer;
  final Duration _updateInterval = const Duration(milliseconds: 16); // 약 60FPS 업데이트
  final Stopwatch _stopwatch = Stopwatch();

  Duration _nextBeep = Duration();
  // 오프셋을 2.7초로 설정
  final Duration _offset = const Duration(milliseconds: 2700);

  TimerManager({
    required this.beepInterval,
    required this.beepSound,
  });

  /// 시작 버튼을 누르면 즉시 음성을 재생한 후 2.7초 후 타이머 시작
  Future<void> startTimerAfterAudioCue(void Function() callback) async {
    print("오디오 재생 시작: $beepSound");
    await _audioPlayer.play(AssetSource(beepSound));
    print("오디오 재생 완료, $_offset 후 타이머 시작");
    Future.delayed(_offset, () {
      print("타이머 시작 호출");
      startTimer(callback);
    });
  }

  /// 타이머 즉시 시작
  void startTimer(void Function() callback) {
    if (!isRunning) {
      _stopwatch
        ..reset()
        ..start();
      isRunning = true;
      isStopped = false;
      _isPaused = false;
      _nextBeep = Duration(seconds: beepInterval);
      timeLine.clear();

      _timer = Timer.periodic(_updateInterval, (timer) {
        final elapsed = _stopwatch.elapsed;
        if (elapsed >= (_nextBeep - _offset)) {
          _playBeepSound();
          _nextBeep += Duration(seconds: beepInterval);
        }
        callback();
      });
    }
  }

  void _playBeepSound() async {
    await _audioPlayer.play(AssetSource(beepSound));
  }

  void pauseTimer() {
    if (isRunning && !_isPaused) {
      _isPaused = true;
      _stopwatch.stop();
      _timer.cancel();
      _audioPlayer.pause(); // 음성 일시 정지
    }
  }

  void resumeTimer(void Function() callback) {
    if (isRunning && _isPaused) {
      _isPaused = false;
      _stopwatch.start();
      _timer = Timer.periodic(_updateInterval, (timer) {
        final elapsed = _stopwatch.elapsed;
        if (elapsed >= (_nextBeep - _offset)) {
          _playBeepSound();
          _nextBeep += Duration(seconds: beepInterval);
        }
        callback();
      });
      _audioPlayer.resume(); // 음성 이어서 재생
    }
  }

  void stopTimer() {
    if (isRunning) {
      isRunning = false;
      isStopped = true;
      _stopwatch.stop();
      _timer.cancel();
      _audioPlayer.stop();
    }
  }

  void resetTimer() {
    stopTimer();
    _stopwatch.reset();
    isRunning = false;
    _isPaused = false;
    isStopped = false;
    timeLine.clear();
    _audioPlayer.stop();
  }

  /// 현재 누적 시간을 랩 기록으로 저장
  void recordLap() {
    timeLine.add(_stopwatch.elapsed);
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    final hundredths = (d.inMilliseconds % 1000) ~/ 10;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${hundredths.toString().padLeft(2, '0')}';
  }

  String get formattedTime => formatDuration(_stopwatch.elapsed);

  bool get isPaused => _isPaused;
}
