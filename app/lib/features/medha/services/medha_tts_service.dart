import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/medha_models.dart';

class MedhaTtsService {
  MedhaTtsService(this._tts);

  final FlutterTts _tts;

  Future<void> speak(
    String text,
    MedhaCompanionType companion, {
    String? locale,
  }) async {
    final profile = companion.voiceProfile;
    final effectiveLocale = locale ?? profile.locale;
    await _tts.stop();
    try {
      await _tts.setLanguage(effectiveLocale);
    } catch (_) {
      // Some engines do not expose language configuration; keep speaking.
    }
    final voice = await _selectBestAvailableVoice(companion, effectiveLocale);
    if (voice != null) {
      try {
        await _tts.setVoice(voice);
      } catch (_) {
        // A stale engine voice must not disable playback.
      }
    }
    try {
      await _tts.setPitch(profile.pitch);
    } catch (_) {
      // Unsupported tuning must not disable playback.
    }

    // flutter_tts uses 0.5 as Android's normal rate. The profile intentionally
    // stores portable 1.0-based multipliers.
    try {
      await _tts.setSpeechRate((profile.speechRate * 0.5).clamp(0.0, 1.0));
    } catch (_) {
      // Fall back to the engine's normal rate.
    }
    if (kDebugMode) {
      debugPrint(
        'MEDHA_TTS companion=${companion.name} '
        'voice=${voice?['name'] ?? 'engine-default'} '
        'locale=$effectiveLocale pitch=${profile.pitch} '
        'rateMultiplier=${profile.speechRate} engineRate='
        '${(profile.speechRate * 0.5).clamp(0.0, 1.0)}',
      );
    }
    await _tts.speak(text);
  }

  Future<Map<String, String>?> _selectBestAvailableVoice(
    MedhaCompanionType companion,
    String locale,
  ) async {
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return null;
      final language = locale.split(RegExp('[-_]')).first.toLowerCase();
      final voices = rawVoices
          .whereType<Map>()
          .map((raw) => raw.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ))
          .where((voice) {
        final voiceLocale = (voice['locale'] ?? '').toLowerCase();
        return voiceLocale == locale.toLowerCase() ||
            voiceLocale.startsWith('$language-') ||
            voiceLocale.startsWith('${language}_');
      }).toList(growable: false);
      if (voices.isEmpty) return null;
      final unique = <String, Map<String, String>>{};
      for (final voice in voices) {
        final key = '${voice['name'] ?? ''}|${voice['locale'] ?? ''}';
        unique.putIfAbsent(key, () => voice);
      }
      final compatible = unique.values.toList(growable: false)
        ..sort((a, b) {
          final aExact =
              (a['locale'] ?? '').toLowerCase() == locale.toLowerCase();
          final bExact =
              (b['locale'] ?? '').toLowerCase() == locale.toLowerCase();
          if (aExact != bExact) return aExact ? -1 : 1;
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        });
      if (kDebugMode) {
        debugPrint(
          'MEDHA_TTS_VOICES locale=$locale count=${compatible.length} '
          'ids=${compatible.map((voice) => voice['name']).join(',')}',
        );
      }
      // Stable round-robin assignments guarantee distinct voice IDs whenever
      // the engine exposes enough compatible voices. Pitch/rate still provide
      // character distinction on single-voice devices.
      return compatible[companion.index % compatible.length];
    } catch (_) {
      // Voice metadata varies by engine. Language, pitch and rate still apply.
      return null;
    }
  }
}
