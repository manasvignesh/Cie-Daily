import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../services/article_narration_service.dart';

class NarrationButton extends ConsumerWidget {
  const NarrationButton({
    super.key,
    required this.articleId,
    required this.label,
    required this.onPlay,
    this.compact = false,
  });

  final String articleId;
  final String label;
  final Future<void> Function() onPlay;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(articleNarrationProvider);
    final own = state.articleId == articleId;
    final playing = own && state.status == NarrationStatus.playing;
    final paused = own && state.status == NarrationStatus.paused;
    return Semantics(
      button: true,
      label: playing
          ? 'Pause narration'
          : paused
              ? 'Resume narration'
              : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final controller = ref.read(articleNarrationProvider.notifier);
          if (playing) {
            await controller.pause();
          } else if (paused) {
            await controller.resume();
          } else {
            await onPlay();
          }
          final latest = ref.read(articleNarrationProvider);
          if (context.mounted && latest.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(latest.message!)),
            );
          }
        },
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(playing ? Icons.pause_rounded : Icons.volume_up_rounded,
                  size: compact ? 16 : 19, color: AppTheme.primaryOrange),
              const SizedBox(width: 5),
              Text(
                  playing
                      ? 'PAUSE'
                      : paused
                          ? 'RESUME'
                          : label,
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: compact ? .5 : 0,
                    fontFamily: 'Inter',
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactNarrationPlayer extends ConsumerWidget {
  const CompactNarrationPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(articleNarrationProvider);
    if (!state.isActive) return const SizedBox.shrink();
    final controller = ref.read(articleNarrationProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMutedColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
      ),
      child: Row(children: [
        Expanded(
            child: Text(state.title ?? 'Article narration',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTheme.primaryTextColor(context), fontSize: 12))),
        IconButton(
            onPressed: controller.previous,
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 20),
        IconButton(
          onPressed: state.status == NarrationStatus.playing
              ? controller.pause
              : controller.resume,
          icon: Icon(state.status == NarrationStatus.playing
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded),
          iconSize: 20,
        ),
        IconButton(
            onPressed: controller.next,
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 20),
        PopupMenuButton<double>(
          tooltip: 'Playback speed',
          onSelected: controller.setRate,
          itemBuilder: (_) => const [0.8, 1.0, 1.25, 1.5]
              .map(
                  (rate) => PopupMenuItem(value: rate, child: Text('$rate×')))
              .toList(),
          child: Text('${state.rate}×',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        IconButton(
            onPressed: controller.stop,
            icon: const Icon(Icons.close_rounded),
            iconSize: 19),
      ]),
    );
  }
}
