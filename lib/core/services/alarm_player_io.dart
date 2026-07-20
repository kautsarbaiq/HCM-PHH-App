import 'package:audioplayers/audioplayers.dart';

/// Mobile/desktop buzzer via audioplayers — reliable on Android/iOS, where the
/// guards and residents actually run the app. Loops until [stop].
class AlarmPlayer {
  final AudioPlayer _p = AudioPlayer();

  void play() async {
    try {
      await _p.setReleaseMode(ReleaseMode.loop);
      await _p.setVolume(1.0);
      await _p.play(AssetSource('audio/alarm.mp3'));
    } catch (_) {
      // Never let an audio hiccup crash the emergency banner.
    }
  }

  void stop() async {
    try {
      await _p.stop();
    } catch (_) {}
  }
}
