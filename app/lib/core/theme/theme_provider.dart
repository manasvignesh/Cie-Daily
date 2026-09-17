import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceMode { automatic, sunlight, moonlight }

class AppearanceState {
  final AppearanceMode mode;
  final double coolFactor;

  const AppearanceState({required this.mode, required this.coolFactor});
}

const String _appearancePreferenceKey = 'breakpoint_appearance';

class AppearanceNotifier extends StateNotifier<AppearanceState> {
  AppearanceNotifier()
      : super(const AppearanceState(
          mode: AppearanceMode.automatic,
          coolFactor: 0,
        )) {
    _loadSavedAppearance();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedAppearance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_appearancePreferenceKey);
      final mode = switch (saved) {
        'sunlight' => AppearanceMode.sunlight,
        'moonlight' => AppearanceMode.moonlight,
        _ => AppearanceMode.automatic,
      };
      state = AppearanceState(mode: mode, coolFactor: _coolFactor(mode));
    } catch (_) {
      _refresh();
    }
  }

  Future<void> setAppearance(AppearanceMode mode) async {
    state = AppearanceState(mode: mode, coolFactor: _coolFactor(mode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appearancePreferenceKey, mode.name);
    } catch (_) {}
  }

  void _refresh() {
    state = AppearanceState(
      mode: state.mode,
      coolFactor: _coolFactor(state.mode),
    );
  }

  double _coolFactor(AppearanceMode mode) {
    if (mode == AppearanceMode.sunlight) return 0;
    if (mode == AppearanceMode.moonlight) return 1;

    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute + now.second / 60;
    if (minutes >= 18 * 60 || minutes < 5 * 60 + 15) return 1;
    if (minutes >= 17 * 60 + 15) {
      return (minutes - (17 * 60 + 15)) / 45;
    }
    if (minutes < 6 * 60) {
      return ((6 * 60) - minutes) / 45;
    }
    return 0;
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceNotifier, AppearanceState>((ref) {
  return AppearanceNotifier();
});

// Kept only for older isolated tests; the app runtime uses AppearanceNotifier.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('user_theme_mode');
    if (value == 'light') state = ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_theme_mode', mode.name);
  }
}
