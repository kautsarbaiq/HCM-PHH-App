/// Fallback [AlarmPlayer] used only when neither `dart:js_interop` (web) nor
/// `dart:io` (mobile/desktop) is available — e.g. during static analysis on an
/// unsupported target. No-op so the app still compiles everywhere.
class AlarmPlayer {
  void play() {}
  void stop() {}
}
