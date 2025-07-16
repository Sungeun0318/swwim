// lib/features/training_generation/tg_video_manager.dart

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoManager {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  VideoManager(String videoAssetPath) {
    _initializeVideo(videoAssetPath);
  }

  VideoPlayerController get controller => _videoController;
  bool get isInitialized => _isInitialized;

  Future<void> _initializeVideo(String videoAssetPath) async {
    try {
      _videoController = VideoPlayerController.asset(videoAssetPath);
      await _videoController.initialize();
      _videoController.setLooping(true);
      _isInitialized = true;
    } catch (error) {
      if (kDebugMode) {
        print("Video initialization error: $error");
      }
      _isInitialized = false;
    }
  }

  Future<void> play() async {
    if (!_isInitialized) return;

    try {
      await _videoController.play();
    } catch (e) {
      if (kDebugMode) {
        print("Video play error: $e");
      }
    }
  }

  Future<void> pause() async {
    if (!_isInitialized) return;

    try {
      await _videoController.pause();
    } catch (e) {
      if (kDebugMode) {
        print("Video pause error: $e");
      }
    }
  }

  Future<void> reset() async {
    if (!_isInitialized) return;

    try {
      await _videoController.pause();
      await _videoController.seekTo(Duration.zero);
    } catch (e) {
      if (kDebugMode) {
        print("Video reset error: $e");
      }
    }
  }

  void dispose() {
    if (_isInitialized) {
      _videoController.dispose();
    }
  }
}