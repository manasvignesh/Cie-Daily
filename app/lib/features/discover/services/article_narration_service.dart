import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/structured_article_model.dart';

enum NarrationStatus { idle, playing, paused, stopped, unavailable, error }

@immutable
class NarrationState {
  const NarrationState({
    this.status = NarrationStatus.idle,
    this.articleId,
    this.title,
    this.sectionIndex = 0,
    this.sectionCount = 0,
    this.rate = 1,
    this.message,
  });

  final NarrationStatus status;
  final String? articleId;
  final String? title;
  final int sectionIndex;
  final int sectionCount;
  final double rate;
  final String? message;

  bool get isActive =>
      status == NarrationStatus.playing || status == NarrationStatus.paused;

  NarrationState copyWith({
    NarrationStatus? status,
    String? articleId,
    String? title,
    int? sectionIndex,
    int? sectionCount,
    double? rate,
    String? message,
  }) =>
      NarrationState(
        status: status ?? this.status,
        articleId: articleId ?? this.articleId,
        title: title ?? this.title,
        sectionIndex: sectionIndex ?? this.sectionIndex,
        sectionCount: sectionCount ?? this.sectionCount,
        rate: rate ?? this.rate,
        message: message,
      );
}

abstract class NarrationEngine {
  Future<void> initialize();
  Future<void> speak(String text);
  Future<void> pause();
  Future<void> stop();
  Future<void> setRate(double rate);
}

class DeviceNarrationEngine implements NarrationEngine {
  DeviceNarrationEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;

  @override
  Future<void> initialize() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-IN');
  }

  @override
  Future<void> pause() => _tts.pause().then((_) {});

  @override
  Future<void> setRate(double rate) =>
      _tts.setSpeechRate(_engineRate(rate)).then((_) {});

  @override
  Future<void> speak(String text) => _tts.speak(text).then((result) {
        if (result != 1) throw StateError('TTS engine unavailable');
      });

  @override
  Future<void> stop() => _tts.stop().then((_) {});

  double _engineRate(double userRate) => (0.48 * userRate).clamp(0.35, 0.72);
}

final articleNarrationProvider =
    StateNotifierProvider<ArticleNarrationController, NarrationState>((ref) {
  return ArticleNarrationController(DeviceNarrationEngine());
});

class ArticleNarrationController extends StateNotifier<NarrationState> {
  ArticleNarrationController(this._engine) : super(const NarrationState()) {
    unawaited(_initialize());
  }

  static const _rateKey = 'article_narration_rate';
  final NarrationEngine _engine;
  List<String> _sections = const [];
  int _session = 0;
  bool _ready = false;

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_rateKey);
      final rate = const [0.8, 1.0, 1.25, 1.5].contains(saved) ? saved! : 1.0;
      await _engine.initialize();
      await _engine.setRate(rate);
      _ready = true;
      state = state.copyWith(rate: rate);
    } catch (_) {
      state = state.copyWith(
        status: NarrationStatus.unavailable,
        message: 'Text-to-speech is unavailable on this device.',
      );
    }
  }

  Future<void> playArticle(StructuredArticleData article) async {
    await _start(
      articleId: article.id,
      title: article.headline,
      sections: articleNarrationSections(article),
    );
  }

  Future<void> playBrief({
    required String articleId,
    required String headline,
    required String summary,
    required List<String> facts,
  }) async {
    await _start(
      articleId: articleId,
      title: headline,
      sections: [headline, summary, ...facts],
    );
  }

  Future<void> _start({
    required String articleId,
    required String title,
    required List<String> sections,
  }) async {
    if (!_ready) {
      await _initialize();
      if (!_ready) return;
    }
    await _engine.stop();
    final session = ++_session;
    _sections =
        sections.map(normalizeForSpeech).where((s) => s.isNotEmpty).toList();
    if (_sections.isEmpty) return;
    state = NarrationState(
      status: NarrationStatus.playing,
      articleId: articleId,
      title: title,
      sectionCount: _sections.length,
      rate: state.rate,
    );
    await _speakFrom(0, session);
  }

  Future<void> _speakFrom(int start, int session) async {
    try {
      for (var index = start; index < _sections.length; index++) {
        if (session != _session || state.status != NarrationStatus.playing) {
          return;
        }
        state = state.copyWith(sectionIndex: index);
        await _engine.speak(_sections[index]);
      }
      if (session == _session) {
        state = state.copyWith(status: NarrationStatus.stopped);
      }
    } catch (_) {
      if (session == _session) {
        state = state.copyWith(
          status: NarrationStatus.error,
          message:
              "Narration couldn't continue. Check your device's speech settings.",
        );
      }
    }
  }

  Future<void> pause() async {
    if (state.status != NarrationStatus.playing) return;
    ++_session;
    await _engine.pause();
    state = state.copyWith(status: NarrationStatus.paused);
  }

  Future<void> resume() async {
    if (state.status != NarrationStatus.paused || _sections.isEmpty) return;
    final session = ++_session;
    state = state.copyWith(status: NarrationStatus.playing);
    await _speakFrom(state.sectionIndex, session);
  }

  Future<void> stop() async {
    ++_session;
    await _engine.stop();
    state = state.copyWith(status: NarrationStatus.stopped);
  }

  Future<void> next() async {
    if (_sections.isEmpty) return;
    final index = (state.sectionIndex + 1).clamp(0, _sections.length - 1);
    final session = ++_session;
    await _engine.stop();
    state =
        state.copyWith(status: NarrationStatus.playing, sectionIndex: index);
    await _speakFrom(index, session);
  }

  Future<void> previous() async {
    if (_sections.isEmpty) return;
    final index = (state.sectionIndex - 1).clamp(0, _sections.length - 1);
    final session = ++_session;
    await _engine.stop();
    state =
        state.copyWith(status: NarrationStatus.playing, sectionIndex: index);
    await _speakFrom(index, session);
  }

  Future<void> setRate(double rate) async {
    if (!const [0.8, 1.0, 1.25, 1.5].contains(rate)) return;
    await _engine.setRate(rate);
    await (await SharedPreferences.getInstance()).setDouble(_rateKey, rate);
    state = state.copyWith(rate: rate);
  }

  @override
  void dispose() {
    ++_session;
    unawaited(_engine.stop());
    super.dispose();
  }
}

List<String> articleNarrationSections(StructuredArticleData article) => [
      article.headline,
      article.hook,
      article.in20SecondsSummary,
      article.whyItMatters,
      ...article.exploreSections.expand((section) => [
            section.title,
            section.previewText,
          ]),
      if (article.quoteText?.trim().isNotEmpty == true)
        '${article.quoteText}. ${article.quoteSpeaker ?? ''}',
      if (article.takeaways.isNotEmpty) 'What to remember.',
      ...article.takeaways,
    ];

String normalizeForSpeech(String input) => input
    .replaceAll('₹', ' rupees ')
    .replaceAll(RegExp(r'\bAI\b'), 'A I')
    .replaceAll(RegExp(r'\bMW\b'), 'megawatts')
    .replaceAll('%', ' percent ')
    .replaceAll(RegExp(r'[•*_#]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int estimatedNarrationMinutes(StructuredArticleData article) {
  final words = articleNarrationSections(article)
      .join(' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
  return (words / 155).ceil().clamp(1, 99);
}
