import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/language_provider.dart';
import '../models/medha_models.dart';

class MedhaPreferencesNotifier extends StateNotifier<MedhaPreferences> {
  MedhaPreferencesNotifier(this._preferences)
      : super(
          MedhaPreferences(
            companion: MedhaCompanionTypeX.parse(
              _preferences.getString(_companionKey),
            ),
            enabled: _preferences.getBool(_enabledKey) ?? true,
            voiceEnabled: _preferences.getBool(_voiceKey) ?? false,
            soundsEnabled: _preferences.getBool(_soundsKey) ?? false,
          ),
        ) {
    _migrateMissingDefaults();
  }

  static const _companionKey = 'medha_selected_companion';
  static const _enabledKey = 'medha_companion_enabled';
  static const _voiceKey = 'medha_voice_enabled';
  static const _soundsKey = 'medha_sounds_enabled';

  final SharedPreferences _preferences;

  Future<void> _migrateMissingDefaults() async {
    // Existing users should receive Kiro without overwriting an explicit
    // choice, including an explicit MEDHA-off preference.
    if (!_preferences.containsKey(_companionKey)) {
      await _preferences.setString(_companionKey, MedhaCompanionType.kiro.name);
    }
    if (!_preferences.containsKey(_enabledKey)) {
      await _preferences.setBool(_enabledKey, true);
    }
    if (!_preferences.containsKey(_voiceKey)) {
      await _preferences.setBool(_voiceKey, false);
    }
    if (!_preferences.containsKey(_soundsKey)) {
      await _preferences.setBool(_soundsKey, false);
    }
  }

  Future<void> selectCompanion(MedhaCompanionType companion) async {
    state = state.copyWith(companion: companion);
    await _preferences.setString(_companionKey, companion.name);
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _preferences.setBool(_enabledKey, value);
  }

  Future<void> setVoiceEnabled(bool value) async {
    state = state.copyWith(voiceEnabled: value);
    await _preferences.setBool(_voiceKey, value);
  }

  Future<void> setSoundsEnabled(bool value) async {
    state = state.copyWith(soundsEnabled: value);
    await _preferences.setBool(_soundsKey, value);
  }
}

final medhaPreferencesProvider =
    StateNotifierProvider<MedhaPreferencesNotifier, MedhaPreferences>((ref) {
  return MedhaPreferencesNotifier(ref.watch(sharedPreferencesProvider));
});

final medhaHiddenForSessionProvider = StateProvider<bool>((ref) => false);

final medhaModalOpenProvider = StateProvider<bool>((ref) => false);

/// The single story/brief context consumed by the app-shell MEDHA overlay.
/// Screens publish data here; they never mount another companion.
class MedhaActiveContextController extends StateNotifier<MedhaContext?> {
  MedhaActiveContextController() : super(null);

  Object? _owner;
  String? _signature;

  static String signatureOf(MedhaContext? context) {
    if (context == null) return 'none';
    return Object.hashAll([
      context.route,
      context.screenType,
      context.contentMode,
      context.contentLocale,
      context.articleId,
      context.articleTitle,
      context.articleSummary,
      context.articleBody,
      context.visibleSection,
      context.currentScrollSection,
      context.currentDeckCardIndex,
      context.currentDeckCardTitle,
      context.currentDeckCardText,
      Object.hashAll(context.allDeckCards),
      Object.hashAll(context.keyNumbers),
      context.whyItMatters,
      Object.hashAll(context.relatedArticleIds),
    ]).toString();
  }

  bool publish({required Object owner, required MedhaContext context}) {
    final signature = signatureOf(context);
    if (identical(_owner, owner) && _signature == signature) return false;
    _owner = owner;
    _signature = signature;
    state = context;
    return true;
  }

  void release({required Object owner, MedhaContext? restore}) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    final signature = signatureOf(restore);
    if (_signature == signature) return;
    _signature = signature;
    state = restore;
  }
}

final medhaActiveContextProvider =
    StateNotifierProvider<MedhaActiveContextController, MedhaContext?>(
  (ref) => MedhaActiveContextController(),
);
