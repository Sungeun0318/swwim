
// lib/training_generation/tg_sound_manager.dart
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  final AudioPlayer _audioPlayer = AudioPlayer();

  void playSound(String filePath) {
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
