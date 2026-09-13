import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ensure you override this provider in the ProviderScope
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ContentLanguageNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const _key = 'preferred_content_language';

  ContentLanguageNotifier(this._prefs) : super(_prefs.getString(_key) ?? 'en');

  void setLanguage(String lang) {
    state = lang;
    _prefs.setString(_key, lang);
  }
}

final contentLanguageProvider = StateNotifierProvider<ContentLanguageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ContentLanguageNotifier(prefs);
});
