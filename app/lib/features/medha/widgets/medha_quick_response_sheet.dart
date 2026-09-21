import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/medha_models.dart';
import '../providers/medha_behavior_controller.dart';
import '../providers/medha_preferences_provider.dart';
import '../services/medha_assistant_service.dart';
import '../services/medha_tts_service.dart';
import '../../../core/router/app_router.dart';
import 'medha_companion_sprite.dart';

Future<bool> showMedhaQuickResponseSheet(
  BuildContext context, {
  required WidgetRef ref,
  required MedhaContext medhaContext,
  required String question,
}) async {
  final targetContext = rootNavigatorKey.currentContext ?? context;
  ref.read(medhaModalOpenProvider.notifier).state = true;
  try {
    return await showModalBottomSheet<bool>(
          context: targetContext,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _MedhaQuickResponseSheet(
            medhaContext: medhaContext,
            question: question,
          ),
        ) ??
        false;
  } catch (e, st) {
    debugPrint('MEDHA_ACTION quick response sheet error: $e\n$st');
    return false;
  } finally {
    ref.read(medhaModalOpenProvider.notifier).state = false;
  }
}

class _MedhaQuickResponseSheet extends ConsumerStatefulWidget {
  const _MedhaQuickResponseSheet({
    required this.medhaContext,
    required this.question,
  });

  final MedhaContext medhaContext;
  final String question;

  @override
  ConsumerState<_MedhaQuickResponseSheet> createState() =>
      _MedhaQuickResponseSheetState();
}

class _MedhaQuickResponseSheetState
    extends ConsumerState<_MedhaQuickResponseSheet> {
  final _tts = FlutterTts();
  late final MedhaTtsService _medhaTts = MedhaTtsService(_tts);
  MedhaAnswer? _answer;
  bool _loading = true;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadAnswer);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadAnswer() async {
    final preferences = ref.read(medhaPreferencesProvider);
    ref.read(medhaBehaviorControllerProvider.notifier).onThinking();
    final answer = await ref.read(medhaAssistantServiceProvider).ask(
      context: widget.medhaContext,
      companion: preferences.companion,
      question: widget.question,
      history: const [],
    );
    if (!mounted) return;
    setState(() {
      _answer = answer;
      _loading = false;
    });
    ref.read(medhaBehaviorControllerProvider.notifier).onAnswer(
          usedFallback: answer.usedFallback,
          outOfScope: answer.isOutOfScope,
        );
    if (preferences.voiceEnabled) await _speak(answer);
  }

  Future<void> _speak(MedhaAnswer answer) async {
    if (!mounted) return;
    setState(() => _speaking = true);
    ref.read(medhaBehaviorControllerProvider.notifier).onSpeaking();
    final companion = ref.read(medhaPreferencesProvider).companion;
    await _medhaTts.speak(
      answer.spokenText,
      companion,
      locale: widget.medhaContext.contentLocale,
    );
    if (!mounted) return;
    setState(() => _speaking = false);
    ref.read(medhaBehaviorControllerProvider.notifier).onReading();
  }

  @override
  Widget build(BuildContext context) {
    final companion = ref.watch(medhaPreferencesProvider).companion;
    final behaviorSnapshot = ref.watch(medhaBehaviorControllerProvider);
    final behavior = _loading
        ? MedhaBehaviorState.thinking
        : behaviorSnapshot.currentBehavior;
    return FractionallySizedBox(
      heightFactor: 0.64,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.cardBorderColor(context)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 10),
                child: Row(
                  children: [
                    MedhaCompanionSprite(
                      companion: companion,
                      state: behavior,
                      emotion: behaviorSnapshot.currentEmotion,
                      size: 52,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companion.profile.name,
                            style: TextStyle(
                              color: AppTheme.primaryTextColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.question,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(color: AppTheme.cardBorderColor(context), height: 1),
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.accentColor(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${companion.profile.name} is reading the story…',
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        children: [
                          ..._answer!.sections.map(
                            (section) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.cardBorderColor(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.label,
                                    style: TextStyle(
                                      color: AppTheme.accentColor(context),
                                      fontSize: 10,
                                      letterSpacing: 1.05,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    section.text,
                                    style: TextStyle(
                                      color: AppTheme.primaryTextColor(context),
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_answer!.usedFallback && !_answer!.isOutOfScope)
                            Text(
                              'Offline story answer',
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor(context),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
              ),
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _speaking ? null : () => _speak(_answer!),
                        icon: Icon(
                          _speaking
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_outlined,
                        ),
                        label: Text(_speaking ? 'Speaking' : 'Listen'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Ask more'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
