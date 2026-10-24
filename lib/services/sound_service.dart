import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static Future<void> playBeep() async {
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
      await player.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      // Sound fail ho to bhi scanning par koi asar nahi.
    }
  }
}
