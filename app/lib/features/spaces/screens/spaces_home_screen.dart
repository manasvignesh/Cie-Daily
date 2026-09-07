import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/breakpoint_logo.dart';
import '../../../core/theme/responsive.dart';
import '../models/live_stream_model.dart';
import '../providers/spaces_provider.dart';

const _playStoreListingUrl = String.fromEnvironment('CIE_DAILY_PLAY_STORE_URL');

class SpacesHomeScreen extends ConsumerStatefulWidget {
  const SpacesHomeScreen({super.key});

  @override
  ConsumerState<SpacesHomeScreen> createState() => _SpacesHomeScreenState();
}

class _SpacesHomeScreenState extends ConsumerState<SpacesHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _openSpace(LiveStreamModel stream) {
    context.push('/spaces/${stream.id}', extra: stream.roomName);
  }

  Future<void> _handlePlayStoreTap() async {
    final listingUri = Uri.tryParse(_playStoreListingUrl);
    if (listingUri != null &&
        (listingUri.scheme == 'https' || listingUri.scheme == 'http')) {
      final opened = await launchUrl(
        listingUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The Play Store review link will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streams = ref.watch(liveStreamsProvider);
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final compact = AppResponsive.isCompact(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 22,
            compact ? 14 : 18,
            compact ? 18 : 22,
            AppResponsive.totalBottomNavSpace(context) + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Spaces',
                    style: TextStyle(
                      color: primaryText,
                      fontFamily: 'Outfit',
                      fontSize: compact ? 29 : 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const BreakpointDotMarker(size: 8, isLive: true),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Live sessions for curious people.',
                style: TextStyle(
                  color: secondaryText,
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              SizedBox(height: compact ? 17 : 20),
              _buildLiveStatus(streams),
              const SizedBox(height: 22),
              const _SectionTitle('What happens here'),
              const SizedBox(height: 11),
              const _FeatureStrip(),
              const SizedBox(height: 22),
              const _SectionTitle('What we talk about'),
              const SizedBox(height: 10),
              const _TopicChips(),
              const SizedBox(height: 22),
              _FounderNote(onReviewTap: _handlePlayStoreTap),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Curiosity looks good on you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.tertiaryTextColor(context),
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatus(AsyncValue<List<LiveStreamModel>> streams) {
    return streams.when(
      data: (items) {
        final active = items.isEmpty ? null : items.first;
        return _LiveStatusPanel(
          controller: _waveController,
          stream: active,
          onJoin: active == null ? null : () => _openSpace(active),
        );
      },
      loading: () => _LiveStatusPanel(
        controller: _waveController,
        isLoading: true,
      ),
      error: (_, __) => _LiveStatusPanel(
        controller: _waveController,
        hasError: true,
        onRetry: () => ref.invalidate(liveStreamsProvider),
      ),
    );
  }
}

class _LiveStatusPanel extends StatelessWidget {
  const _LiveStatusPanel({
    required this.controller,
    this.stream,
    this.onJoin,
    this.onRetry,
    this.isLoading = false,
    this.hasError = false,
  });

  final Animation<double> controller;
  final LiveStreamModel? stream;
  final VoidCallback? onJoin;
  final VoidCallback? onRetry;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final isLive = stream != null;
    final isDark = AppTheme.isDark(context);
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final border = isLive
        ? AppTheme.primaryOrange.withValues(alpha: isDark ? 0.42 : 0.30)
        : AppTheme.cardBorderColor(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141418) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: isLoading
            ? const _StatusLoading()
            : hasError
                ? _StatusError(onRetry: onRetry)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(isLive: isLive),
                          if (isLive && stream!.participantCount != null) ...[
                            const Spacer(),
                            Icon(Icons.headphones_rounded,
                                size: 14, color: secondaryText),
                            const SizedBox(width: 5),
                            Text(
                              '${stream!.participantCount}',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLive ? stream!.title : 'Nothing live right now.',
                        maxLines: isLive ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontFamily: 'Outfit',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isLive
                            ? 'Live with ${stream!.hostName}'
                            : 'We go live whenever there’s something genuinely worth learning.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: _CompactWaveform(
                              controller: controller,
                              active: isLive,
                            ),
                          ),
                          if (isLive) ...[
                            const SizedBox(width: 14),
                            FilledButton.icon(
                              onPressed: onJoin,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.graphic_eq_rounded,
                                  size: 17),
                              label: const Text(
                                'Join live',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final secondaryText = AppTheme.secondaryTextColor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isLive
                ? AppTheme.primaryOrange
                : AppTheme.tertiaryTextColor(context),
            shape: BoxShape.circle,
            boxShadow: isLive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.30),
                      blurRadius: 7,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          isLive ? 'LIVE NOW' : 'NOT LIVE',
          style: TextStyle(
            color: isLive ? AppTheme.primaryOrange : secondaryText,
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: isLive ? 0.6 : 0.1,
          ),
        ),
      ],
    );
  }
}

class _CompactWaveform extends StatelessWidget {
  const _CompactWaveform({required this.controller, required this.active});

  final Animation<double> controller;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 29,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          const baseHeights = [
            8.0,
            14.0,
            21.0,
            12.0,
            25.0,
            16.0,
            10.0,
            20.0,
            13.0,
            24.0,
            15.0,
            9.0,
            18.0,
            11.0,
          ];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(baseHeights.length, (index) {
              final pulse = reduceMotion
                  ? 0.45
                  : (math.sin(controller.value * math.pi * 2 + index * 0.68) +
                          1) /
                      2;
              final movement = active ? 0.42 : 0.16;
              return Expanded(
                child: Align(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height:
                        baseHeights[index] * (1 - movement + pulse * movement),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(
                        alpha: active
                            ? (index.isEven ? 0.95 : 0.66)
                            : (index.isEven ? 0.52 : 0.30),
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _StatusLoading extends StatelessWidget {
  const _StatusLoading();

  @override
  Widget build(BuildContext context) {
    final fill = AppTheme.elevatedSurfaceColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 82, height: 12, color: fill),
        const SizedBox(height: 15),
        Container(width: 190, height: 20, color: fill),
        const SizedBox(height: 9),
        Container(width: double.infinity, height: 13, color: fill),
        const SizedBox(height: 15),
        Container(width: double.infinity, height: 28, color: fill),
      ],
    );
  }
}

class _StatusError extends StatelessWidget {
  const _StatusError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wifi_tethering_error_rounded,
              color: AppTheme.primaryOrange, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spaces are taking a moment',
                style: TextStyle(
                  color: primaryText,
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Check again for live sessions.',
                style: TextStyle(color: secondaryText, fontSize: 12.5),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.primaryTextColor(context),
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  static const _features = [
    (Icons.headphones_rounded, 'Listen live'),
    (Icons.help_outline_rounded, 'Ask questions'),
    (Icons.forum_outlined, 'Discuss together'),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 365 || textScale > 1.25;
    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _features
            .map((item) => _FeatureItem(icon: item.$1, title: item.$2))
            .toList(),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < _features.length; i++) ...[
          Expanded(
            child: _FeatureItem(
              icon: _features[i].$1,
              title: _features[i].$2,
              expanded: true,
            ),
          ),
          if (i != _features.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    this.expanded = false,
  });

  final IconData icon;
  final String title;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryOrange, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.primaryTextColor(context),
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChips extends StatelessWidget {
  const _TopicChips();

  static const _topics = [
    'AI',
    'ChatGPT',
    'Coding',
    'Editing',
    'Design',
    'New tools',
    'Tech',
    'Ideas',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: _topics
          .map(
            (topic) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF19191E) : const Color(0xFFF0EFEC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTheme.cardBorderColor(context)),
              ),
              child: Text(
                topic,
                style: TextStyle(
                  color: AppTheme.secondaryTextColor(context),
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FounderNote extends StatelessWidget {
  const _FounderNote({required this.onReviewTap});

  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151519) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: isDark ? 0.24 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'M',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'A note from Manas',
                  style: TextStyle(
                    color: primaryText,
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“I built Spaces for people who get curious enough to actually learn something instead of just scrolling past it.\n\nWhenever our team finds something worth sharing, we’ll go live here.”',
            style: TextStyle(
              color: secondaryText,
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onReviewTap,
            borderRadius: BorderRadius.circular(7),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Review Breakpoint on the Play Store →',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
