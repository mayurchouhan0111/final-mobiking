// lib/services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart'; // Assuming you're using GetX

class SoundService extends GetxService {
  late AudioPlayer _audioPlayer;

  @override
  void onInit() {
    super.onInit();
    _audioPlayer = AudioPlayer();
    // Optional: Pre-load the sound if it's small and used frequently
    // This helps reduce latency for the first play.
    // Uncomment if you want to pre-load:
    // _audioPlayer.setSourceAsset('sounds/pop.mp3');
  }

  Future<void> playPopSound() async {
    // Ensure the asset path matches your pubspec.yaml declaration
    // Using AssetSource is for assets bundled with your app
    await _audioPlayer.play(AssetSource('sounds/pop.mp3'));
  }

  @override
  void onClose() {
    _audioPlayer
        .dispose(); // Release resources when the service is no longer needed
    super.onClose();
  }
}
