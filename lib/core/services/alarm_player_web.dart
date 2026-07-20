import 'package:web/web.dart' as web;

/// Web buzzer: a looping HTML5 `<audio>` element driven straight from the
/// browser. audioplayers' web backend throws MissingPluginException on
/// `audioplayers.global init` in the resolved version, so on web we bypass it.
///
/// Flutter serves a declared asset `assets/audio/alarm.mp3` at the URL
/// `assets/assets/audio/alarm.mp3`, resolved against the document base href.
class AlarmPlayer {
  web.HTMLAudioElement? _el;

  void play() {
    // An <audio> with no `controls` renders nothing, so no need to hide it.
    final el = _el ??= web.HTMLAudioElement()
      ..id = 'emergency-buzzer'
      ..src = 'assets/assets/audio/alarm.mp3'
      ..loop = true
      ..preload = 'auto';
    // Attaching to the document keeps some browsers happier about looping and
    // lets the alarm be inspected/paused reliably.
    if (!el.isConnected) web.document.body?.append(el);
    try {
      el.currentTime = 0;
      // play() returns a Promise; if autoplay is blocked (no user gesture yet)
      // it rejects harmlessly — the banner is already on screen either way.
      el.play();
    } catch (_) {}
  }

  void stop() {
    final el = _el;
    if (el == null) return;
    try {
      el.pause();
      el.currentTime = 0;
    } catch (_) {}
  }
}
