// lib/features/training_generation/tg_sound_manager.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class SoundManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false; // 이 변수 사용하기
  Timer? _playingTimer;

  void playSound(String filePath, {double volume = 1.0}) {
    try {
      // 이미 재생 중이면 중복 재생 방지
      if (_isPlaying) {
        if (kDebugMode) {
          print("이미 소리 재생 중, 중복 재생 방지");
        }
        return;
      }
      _isPlaying = true; // 재생 상태로 설정
      _playingTimer?.cancel();

      if (kDebugMode) {
        print("사운드 재생: $filePath, 볼륨: $volume");
      }

      // 볼륨 설정 추가
      _audioPlayer.setVolume(volume);

      // 새로운 소리 재생 전 기존 소리 중지 (끊김 방지)
      _audioPlayer.stop();

      // 소리 재생
      _audioPlayer.play(AssetSource(filePath));

      // 타이머를 사용하여 더 긴 시간 후에 플래그 초기화
      // 끊김 방지를 위해 시간을 길게 설정
      _playingTimer = Timer(const Duration(milliseconds: 500), () {
        _isPlaying = false; // 재생 완료 후 상태 초기화
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) {
        print("사운드 재생 오류: $e");
      }
    }
  }

  void pauseSound() {
    try {
      _audioPlayer.pause();
    } catch (e) {
      if (kDebugMode) {
        print("사운드 일시정지 오류: $e");
      }
    }
  }

  void resumeSound() {
    try {
      _audioPlayer.resume();
    } catch (e) {
      if (kDebugMode) {
        print("사운드 재개 오류: $e");
      }
    }
  }

  void stopSound() {
    try {
      _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        print("사운드 정지 오류: $e");
      }
    }
  }

  void dispose() {
    _playingTimer?.cancel();
    _audioPlayer.dispose();
    _isPlaying = false;
  }
}