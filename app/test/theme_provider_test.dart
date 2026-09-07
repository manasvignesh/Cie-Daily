import 'package:cie_connect/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark mode is the default when no preference exists', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = ThemeModeNotifier();
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state, ThemeMode.dark);
    notifier.dispose();
  });

  test('an explicit light preference remains light', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ThemeModeNotifier();
    await first.setThemeMode(ThemeMode.light);
    first.dispose();

    final restored = ThemeModeNotifier();
    await Future<void>.delayed(Duration.zero);

    expect(restored.state, ThemeMode.light);
    restored.dispose();
  });
}
