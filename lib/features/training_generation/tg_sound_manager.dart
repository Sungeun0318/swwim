// lib/features/training_generation/tg_sound_manager.dart
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<DateTime, bool> _recentPlayTimes = {};

  // 최근 100ms 이내에 재생된 소리가 있는지 확인
  bool _hasSoundPlayedRecently() {
    final now = DateTime.now();

    // 100ms 이상 지난 항목 제거
    _recentPlayTimes.removeWhere((time, _) {
      return now.difference(time).inMilliseconds > 100;
    });

    return _recentPlayTimes.isNotEmpty;
  }

  void playSound(String filePath) {
    // 최근 100ms 이내에 재생된 소리가 있으면 무시
    if (_hasSoundPlayedRecently()) {
      return;
    }

    // 현재 시간 기록
    _recentPlayTimes[DateTime.now()] = true;

    // 소리 재생
    _audioPlayer.play(AssetSource(filePath));
  }

  void pauseSound() {
    _audioPlayer.pause();
  }

  void resumeSound() {
    _audioPlayer.resume();
  }

  void stopSound() {
    _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}