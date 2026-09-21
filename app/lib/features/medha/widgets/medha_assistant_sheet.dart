import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/medha_behavior_models.dart';
import '../models/medha_models.dart';
import '../providers/medha_behavior_controller.dart';
import '../providers/medha_preferences_provider.dart';
import '../services/medha_assistant_service.dart';
import '../services/medha_tts_service.dart';
import '../../../core/router/app_router.dart';
import 'medha_companion_sprite.dart';

Future<void> showMedhaAssistantSheet(
  BuildContext context, {
  required MedhaContext medhaContext,
  bool autoFocus = false,
}) {
  final targetContext = rootNavigatorKey.currentContext ?? context;
  return showModalBottomSheet<void>(
    context: targetContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MedhaAssistantSheet(
      medhaContext: medhaContext,
      autoFocus: autoFocus,
    ),
  );
}

class MedhaAssistantSheet extends ConsumerStatefulWidget {
  const MedhaAssistantSheet({
    super.key,
    required this.medhaContext,
    this.autoFocus = false,
  });

  final MedhaContext medhaContext;
  final bool autoFocus;

  @override
  ConsumerState<MedhaAssistantSheet> createState() =>
      _MedhaAssistantSheetState();
}

class _MedhaAssistantSheetState extends ConsumerState<MedhaAssistantSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _tts = FlutterTts();
  late final MedhaTtsService _medhaTts = MedhaTtsService(_tts);
  final List<_MedhaUiMessage> _messages = [];
  bool _asking = false;

  static const _quickActions = <String>[
    'Summarize this article',
    'Explain simply',
    'Go deeper',
    'Why does this matter?',
    'What should I learn next?',
  ];

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || _asking) return;
    _controller.clear();
    setState(() {
      _asking = true;
      _messages.add(_MedhaUiMessage.user(question));
    });
    ref.read(medhaBehaviorControllerProvider.notifier).onThinking();
    _scrollToEnd();

    final preferences = ref.read(medhaPreferencesProvider);
    final history = _messages
        .where((message) => message.answer == null)
        .map((message) => MedhaConversationTurn(
              role: message.isUser ? 'user' : 'assistant',
              text: message.text,
            ))
        .toList(growable: false);
    final answer = await ref.read(medhaAssistantServiceProvider).ask(
          context: widget.medhaContext,
          companion: preferences.companion,
          question: question,
          history: history,
        );
    if (!mounted) return;
    setState(() {
      _asking = false;
      _messages.add(_MedhaUiMessage.answer(answer));
    });
    ref.read(medhaBehaviorControllerProvider.notifier).onAnswer(
          usedFallback: answer.usedFallback,
          outOfScope: answer.isOutOfScope,
        );
    _scrollToEnd();
    if (preferences.voiceEnabled) {
      ref.read(medhaBehaviorControllerProvider.notifier).onSpeaking();
      // Read the current selection again so a companion switch applies now.
      final companion = ref.read(medhaPreferencesProvider).companion;
      await _medhaTts.speak(
        answer.spokenText,
        companion,
        locale: widget.medhaContext.contentLocale,
      );
      if (mounted) {
        ref.read(medhaBehaviorControllerProvider.notifier).onReading();
      }
    }
  }

  Future<void> _speak(MedhaAnswer answer) async {
    if (!mounted) return;
    ref.read(medhaBehaviorControllerProvider.notifier).onSpeaking();
    final companion = ref.read(medhaPreferencesProvider).companion;
    await _medhaTts.speak(
      answer.spokenText,
      companion,
      locale: widget.medhaContext.contentLocale,
    );
    if (mounted) {
      ref.read(medhaBehaviorControllerProvider.notifier).onReading();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(medhaPreferencesProvider);
    final companion = preferences.companion;
    final behaviorSnapshot = ref.watch(medhaBehaviorControllerProvider);
    final behavior = _asking
        ? MedhaBehaviorState.thinking
        : behaviorSnapshot.currentBehavior;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(top: 44, bottom: keyboard),
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
              _header(
                context,
                companion,
                behavior,
                behaviorSnapshot.currentEmotion,
              ),
              Divider(color: AppTheme.cardBorderColor(context), height: 1),
              Expanded(
                child: _messages.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                        itemCount: _messages.length + (_asking ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (_asking && index == _messages.length) {
                            return _ThinkingCard(companion: companion);
                          }
                          final message = _messages[index];
                          return _MessageCard(
                            message: message,
                            onSpeak: message.answer == null
                                ? null
                                : () => _speak(message.answer!),
                          );
                        },
                      ),
              ),
              _composer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    MedhaCompanionType companion,
    MedhaBehaviorState behavior,
    MedhaEmotion emotion,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          MedhaCompanionSprite(
            companion: companion,
            state: behavior,
            emotion: emotion,
            size: 58,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companion.profile.name,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.medhaContext.contentMode == MedhaContentMode.fullStory
                      ? 'Reading this story with you.'
                      : 'Reading this brief with you.',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close MEDHA',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.accentColor(context).withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.article_outlined,
                  size: 18, color: AppTheme.accentColor(context)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Using “${widget.medhaContext.articleTitle}” as context',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Explore this story',
          style: TextStyle(
            color: AppTheme.primaryTextColor(context),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickActions
              .map(
                (label) => ActionChip(
                  avatar: Icon(Icons.auto_awesome_rounded,
                      size: 15, color: AppTheme.accentColor(context)),
                  label: Text(label),
                  onPressed: () => _ask(label),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _composer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border:
            Border(top: BorderSide(color: AppTheme.cardBorderColor(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autoFocus,
              enabled: !_asking,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _ask,
              decoration: InputDecoration(
                hintText: 'Ask anything about this story…',
                filled: true,
                fillColor: AppTheme.backgroundColor(context),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send question',
            onPressed: _asking ? null : () => _ask(_controller.text),
            style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard({required this.companion});

  final MedhaCompanionType companion;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorderColor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accentColor(context),
              ),
            ),
            const SizedBox(width: 9),
            Text('${companion.profile.name} is looking through the story…'),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onSpeak});

  final _MedhaUiMessage message;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message.text,
              style: const TextStyle(color: Colors.white, height: 1.35)),
        ),
      );
    }
    final answer = message.answer!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...answer.sections.map(
          (section) => Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.label,
                  style: TextStyle(
                    color: AppTheme.accentColor(context),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  section.text,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton.outlined(
            tooltip: 'Listen to this answer',
            onPressed: onSpeak,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.volume_up_outlined, size: 18),
          ),
        ),
        if (answer.usedFallback && !answer.isOutOfScope)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Offline story answer',
              style: TextStyle(
                  color: AppTheme.secondaryTextColor(context), fontSize: 10),
            ),
          ),
      ],
    );
  }
}

class _MedhaUiMessage {
  const _MedhaUiMessage._({
    required this.isUser,
    required this.text,
    this.answer,
  });

  factory _MedhaUiMessage.user(String text) =>
      _MedhaUiMessage._(isUser: true, text: text);

  factory _MedhaUiMessage.answer(MedhaAnswer answer) => _MedhaUiMessage._(
        isUser: false,
        text: answer.spokenText,
        answer: answer,
      );

  final bool isUser;
  final String text;
  final MedhaAnswer? answer;
}
