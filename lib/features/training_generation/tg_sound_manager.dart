// lib/features/training_generation/tg_sound_manager.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  void playSound(String filePath) {
    // 이미 재생 중이면 중복 재생 방지
    if (_isPlaying) return;

    try {
      _isPlaying = true;

      if (kDebugMode) {
        print("사운드 재생: $filePath");
      }

      // 소리 재생
      _audioPlayer.play(AssetSource(filePath));

      // 짧은 시간 후 플래그 초기화
      Future.delayed(const Duration(milliseconds: 100), () {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) {
        print("사운드 재생 오류: $e");
      }
    }
  }

  void pauseSound() {
    _audioPlayer.pause();
  }

  void resumeSound() {
    _audioPlayer.resume();
  }

  void stopSound() {
    _audioPlayer.stop();
    _isPlaying = false;
  }

  void dispose() {
    _audioPlayer.dispose();
    _isPlaying = false;
  }
}