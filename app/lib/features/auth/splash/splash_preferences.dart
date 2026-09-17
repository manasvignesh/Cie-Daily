/// Determines splash experience based on **how the app was launched**, not
/// whether the user has seen it before. The full cinematic intro is part of
/// Breakpoint's identity and plays on every normal cold launch.
enum LaunchExperience {
  /// Normal launcher icon / app drawer / fresh process → full ~6s cinematic.
  cinematic,

  /// Notification tap, shortcut, widget, deep link → quick ~0.8s.
  quickAccess,
}

class SplashPreferences {
  LaunchExperience _experience = LaunchExperience.cinematic;

  /// Call once at startup from main.dart or app.dart based on the launch source.
  void configure(LaunchExperience experience) {
    _experience = experience;
  }

  /// Always returns immediately — no async, no SharedPreferences check.
  LaunchExperience get experience => _experience;

  /// Returns true for full cinematic, false for quick access.
  bool get needsCinematic => _experience == LaunchExperience.cinematic;
}
