import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/medha_behavior_models.dart';
import '../models/medha_models.dart';
import '../providers/medha_behavior_controller.dart';
import '../providers/medha_preferences_provider.dart';
import 'medha_assistant_sheet.dart';
import 'medha_companion_selector.dart';
import 'medha_companion_sprite.dart';
import 'medha_quick_response_sheet.dart';

class MedhaCompanionOverlay extends ConsumerStatefulWidget {
  const MedhaCompanionOverlay({
    super.key,
    this.onOpenConversation,
    this.onQuickAction,
    this.bottomInset = 12,
    this.minimal = false,
    this.allowRoaming = false,
    this.screenType = 'unknown',
  });

  final VoidCallback? onOpenConversation;
  final ValueChanged<String>? onQuickAction;
  final double bottomInset;
  final bool minimal;
  final bool allowRoaming;
  final String screenType;

  @override
  ConsumerState<MedhaCompanionOverlay> createState() =>
      _MedhaCompanionOverlayState();
}

class _MedhaCompanionOverlayState extends ConsumerState<MedhaCompanionOverlay> {
  Offset _dragOffset = Offset.zero;
  bool _menuOpen = false;
  bool _dragging = false;
  int _tapGeneration = 0;
  String _lastEnvironmentSignature = '';
  bool _configureScheduled = false;

  BuildContext get _effectiveNavContext =>
      rootNavigatorKey.currentContext ?? context;

  @override
  void initState() {
    super.initState();
    // Listen to providers that affect the environment configuration.
    // When they change, schedule a lifecycle-safe configure call rather
    // than writing to providers from inside build().
    ref.listenManual(medhaPreferencesProvider, (_, __) {
      _scheduleConfigureIfNeeded();
    });
    ref.listenManual(medhaActiveContextProvider, (_, __) {
      _scheduleConfigureIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant MedhaCompanionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottomInset != widget.bottomInset ||
        oldWidget.screenType != widget.screenType ||
        oldWidget.allowRoaming != widget.allowRoaming ||
        oldWidget.minimal != widget.minimal) {
      _scheduleConfigureIfNeeded();
    }
  }

  void _scheduleConfigureIfNeeded() {
    if (_configureScheduled) return;
    _configureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureScheduled = false;
      if (!mounted) return;
      final preferences = ref.read(medhaPreferencesProvider);
      final activeContext = ref.read(medhaActiveContextProvider);
      final mediaQuery = MediaQuery.of(context);
      final screenSize = mediaQuery.size;
      final spriteSize = widget.minimal ? 64.0 : 76.0;
      const spriteHitPadding = 8.0;
      final renderedPetSize = spriteSize + spriteHitPadding * 2;
      final environment = _environmentFor(
        screenSize,
        renderedPetSize,
        mediaQuery.disableAnimations,
        mediaQuery.padding,
        activeContext,
      );
      final environmentSignature = <Object>[
        preferences.companion,
        widget.screenType,
        screenSize,
        renderedPetSize,
        widget.bottomInset,
        mediaQuery.padding,
        mediaQuery.disableAnimations,
        activeContext?.articleId ?? '',
        activeContext?.currentDeckCardIndex ?? -1,
      ].join('|');
      if (_lastEnvironmentSignature == environmentSignature) return;
      _lastEnvironmentSignature = environmentSignature;
      ref.read(medhaBehaviorControllerProvider.notifier).configure(
            companion: preferences.companion,
            environment: environment,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(medhaPreferencesProvider);
    final hidden = ref.watch(medhaHiddenForSessionProvider);
    final modalOpen = ref.watch(medhaModalOpenProvider);
    final behavior = ref.watch(medhaBehaviorControllerProvider);
    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    if (!preferences.enabled || hidden || modalOpen || keyboardOpen) {
      return const SizedBox.shrink();
    }

    final screenSize = mediaQuery.size;
    final spriteSize = widget.minimal ? 64.0 : 76.0;
    const spriteHitPadding = 8.0;
    final renderedPetSize = spriteSize + spriteHitPadding * 2;
    final activeContext = ref.watch(medhaActiveContextProvider);
    final environment = _environmentFor(
      screenSize,
      renderedPetSize,
      mediaQuery.disableAnimations,
      mediaQuery.padding,
      activeContext,
    );
    final anchor = behavior.targetAnchor;
    final anchorPoint = environment.anchorPoint(anchor);
    final petLeft = anchorPoint.dx + _dragOffset.dx;
    final petTop = anchorPoint.dy + _dragOffset.dy;
    final petRect = Rect.fromLTWH(
      petLeft,
      petTop,
      renderedPetSize,
      renderedPetSize,
    );
    final hasArticle = widget.onQuickAction != null || activeContext != null;
    final menuHeight = hasArticle
        ? math.max(174.0, 4 * (mediaQuery.textScaler.scale(13) + 28) + 16)
        : math.max(78.0, mediaQuery.textScaler.scale(12) * 2.7 + 30);
    final menuSize = Size(hasArticle ? 190 : 205, menuHeight);
    final protectedBottomInset = widget.bottomInset + mediaQuery.padding.bottom;
    // Account for box-shadow bleed (blurRadius 18 + offset 6) so the menu
    // shadow never visually overlaps the bottom navigation bar.
    const menuShadowBleed = 24.0;
    final bottomNavigationTop =
        screenSize.height - protectedBottomInset - 12 - menuShadowBleed;
    final keyboardTop = mediaQuery.viewInsets.bottom > 0
        ? screenSize.height - mediaQuery.viewInsets.bottom
        : screenSize.height;
    final menuRect = _menuRectFor(
      petRect: petRect,
      menuSize: menuSize,
      viewport: screenSize,
      safePadding: mediaQuery.padding,
      maximumBottom: math.min(bottomNavigationTop, keyboardTop),
    );

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        if (_menuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (mounted && _menuOpen) {
                  setState(() => _menuOpen = false);
                }
              },
            ),
          ),
        if (_menuOpen)
          AnimatedPositioned(
            duration: mediaQuery.disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            left: menuRect.left,
            top: menuRect.top,
            child: _buildMenu(context, hasArticle),
          ),
        AnimatedPositioned(
          duration: _dragging || mediaQuery.disableAnimations
              ? Duration.zero
              : behavior.movementDuration,
          curve: Curves.easeOutCubic,
          left: petLeft,
          top: petTop,
          child: _buildSprite(
            preferences.companion,
            behavior.currentBehavior,
            behavior.currentEmotion,
            spriteSize,
            behavior.verticalLook,
            behavior.horizontalLook,
          ),
        ),
      ],
    );
  }

  Rect _menuRectFor({
    required Rect petRect,
    required Size menuSize,
    required Size viewport,
    required EdgeInsets safePadding,
    required double maximumBottom,
  }) {
    const margin = 12.0;
    const gap = 8.0;
    final usable = Rect.fromLTRB(
      safePadding.left + margin,
      safePadding.top + margin,
      viewport.width - safePadding.right - margin,
      maximumBottom - margin,
    );
    final maxLeft = usable.right - menuSize.width;
    final centeredLeft =
        (petRect.center.dx - menuSize.width / 2).clamp(usable.left, maxLeft);
    final above = Rect.fromLTWH(
      centeredLeft,
      petRect.top - gap - menuSize.height,
      menuSize.width,
      menuSize.height,
    );
    final below = Rect.fromLTWH(
      centeredLeft,
      petRect.bottom + gap,
      menuSize.width,
      menuSize.height,
    );

    bool fits(Rect rect) =>
        rect.left >= usable.left &&
        rect.right <= usable.right &&
        rect.top >= usable.top &&
        rect.bottom <= usable.bottom;

    final petIsLower = petRect.center.dy >= usable.center.dy;
    final preferred = petIsLower ? above : below;
    final alternate = petIsLower ? below : above;
    if (fits(preferred)) return preferred;
    if (fits(alternate)) return alternate;

    final roomOnRight = usable.right - petRect.right;
    final roomOnLeft = petRect.left - usable.left;
    final openRight = roomOnRight >= roomOnLeft;
    final sideLeft =
        openRight ? petRect.right + gap : petRect.left - gap - menuSize.width;
    final side = Rect.fromLTWH(
      sideLeft,
      (petRect.center.dy - menuSize.height / 2)
          .clamp(usable.top, usable.bottom - menuSize.height),
      menuSize.width,
      menuSize.height,
    );
    if (fits(side)) return side;

    return Rect.fromLTWH(
      centeredLeft,
      (petIsLower ? above.top : below.top)
          .clamp(usable.top, usable.bottom - menuSize.height),
      menuSize.width,
      menuSize.height,
    );
  }

  Widget _buildSprite(
    MedhaCompanionType companion,
    MedhaBehaviorState behavior,
    MedhaEmotion emotion,
    double size,
    double verticalLook,
    double horizontalLook,
  ) {
    return Semantics(
      button: true,
      label:
          '${companion.profile.name}, your MEDHA companion. Tap for options.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (_dragging) return;
          final generation = ++_tapGeneration;
          final disposition =
              ref.read(medhaBehaviorControllerProvider.notifier).onTap();
          await Future<void>.delayed(_tapReactionDuration(companion));
          if (!mounted ||
              _dragging ||
              generation != _tapGeneration ||
              disposition == MedhaTapDisposition.playful) {
            return;
          }
          setState(() => _menuOpen = !_menuOpen);
        },
        onLongPress: () => _showOptions(context),
        onPanStart: (_) => setState(() {
          _dragging = true;
          _menuOpen = false;
          ref.read(medhaBehaviorControllerProvider.notifier).onDragStart();
        }),
        onPanUpdate: (details) => setState(() {
          _dragOffset += details.delta;
        }),
        onPanEnd: (_) => _snapToAnchor(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: MedhaCompanionSprite(
            companion: companion,
            state: behavior,
            emotion: emotion,
            size: size,
            verticalLook: verticalLook,
            horizontalLook: horizontalLook,
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool hasArticle) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: hasArticle ? 190 : 205,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: hasArticle
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuButton(
                    context,
                    Icons.notes_rounded,
                    'Summarize',
                    () => _quickAction('Summarize this article'),
                  ),
                  _menuButton(
                    context,
                    Icons.lightbulb_outline_rounded,
                    'Explain simply',
                    () => _quickAction('Explain simply'),
                  ),
                  _menuButton(
                    context,
                    Icons.travel_explore_rounded,
                    'Why it matters',
                    () => _quickAction('Why does this matter?'),
                  ),
                  _menuButton(
                    context,
                    Icons.chat_bubble_outline_rounded,
                    'Ask something',
                    _openConversation,
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Text(
                  'Open a story and I’ll explore it with you.',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.accentColor(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAction(String question) async {
    final actionLabel = switch (question) {
      'Summarize this article' => 'summarize',
      'Explain simply' => 'explain',
      'Why does this matter?' => 'whyItMatters',
      _ => 'quickAction',
    };
    debugPrint('MEDHA_ACTION $actionLabel tapped');

    final activeContext = ref.read(medhaActiveContextProvider);
    if (activeContext == null) {
      debugPrint(
          'MEDHA_ACTION $actionLabel aborted: medhaActiveContextProvider is null');
      return;
    }
    setState(() => _menuOpen = false);

    if (widget.onQuickAction != null) {
      widget.onQuickAction!.call(question);
      return;
    }

    try {
      final navContext = _effectiveNavContext;
      final askMore = await showMedhaQuickResponseSheet(
        navContext,
        ref: ref,
        medhaContext: activeContext,
        question: question,
      );
      if (askMore && mounted) {
        await _showConversation(activeContext);
      }
    } catch (e, st) {
      debugPrint('MEDHA_ACTION $actionLabel error: $e\n$st');
    }
  }

  Future<void> _openConversation() async {
    debugPrint('MEDHA_ACTION askSomething tapped');
    final activeContext = ref.read(medhaActiveContextProvider);
    if (activeContext == null) {
      debugPrint(
          'MEDHA_ACTION askSomething aborted: medhaActiveContextProvider is null');
      return;
    }
    setState(() => _menuOpen = false);

    if (widget.onOpenConversation != null) {
      widget.onOpenConversation!.call();
      return;
    }

    try {
      await _showConversation(activeContext, autoFocus: true);
    } catch (e, st) {
      debugPrint('MEDHA_ACTION askSomething error: $e\n$st');
    }
  }

  Future<void> _showConversation(
    MedhaContext activeContext, {
    bool autoFocus = false,
  }) async {
    ref.read(medhaModalOpenProvider.notifier).state = true;
    try {
      final navContext = _effectiveNavContext;
      await showMedhaAssistantSheet(
        navContext,
        medhaContext: activeContext,
        autoFocus: autoFocus,
      );
    } catch (e, st) {
      debugPrint('MEDHA_ACTION conversation error: $e\n$st');
    } finally {
      ref.read(medhaModalOpenProvider.notifier).state = false;
    }
  }

  void _snapToAnchor() {
    final screen = MediaQuery.sizeOf(context);
    final behavior = ref.read(medhaBehaviorControllerProvider);
    final environment =
        ref.read(medhaBehaviorControllerProvider.notifier).environment;
    final current = environment.anchorPoint(behavior.targetAnchor);
    final halfPet = environment.spriteSize / 2;
    final approximatedX = current.dx + _dragOffset.dx + halfPet;
    final currentY = current.dy + _dragOffset.dy + halfPet;
    final right = approximatedX >= screen.width / 2;
    final verticalBand = currentY < screen.height * 0.34
        ? 0
        : currentY < screen.height * 0.67
            ? 1
            : 2;
    final anchor = switch ((right, verticalBand)) {
      (true, 0) => MedhaAnchor.edgeTopRight,
      (true, 1) => MedhaAnchor.edgeMiddleRight,
      (true, _) => MedhaAnchor.edgeLowerRight,
      (false, 0) => MedhaAnchor.edgeTopLeft,
      (false, 1) => MedhaAnchor.edgeMiddleLeft,
      (false, _) => MedhaAnchor.edgeLowerLeft,
    };
    setState(() {
      _dragOffset = Offset.zero;
      _dragging = false;
    });
    ref.read(medhaBehaviorControllerProvider.notifier).onDragEnd(anchor);
  }

  MedhaEnvironment _environmentFor(
    Size screenSize,
    double renderedPetSize,
    bool reducedMotion,
    EdgeInsets safePadding,
    MedhaContext? activeContext,
  ) {
    const edgeAnchors = <MedhaAnchor>[
      MedhaAnchor.edgeTopLeft,
      MedhaAnchor.edgeMiddleLeft,
      MedhaAnchor.edgeLowerLeft,
      MedhaAnchor.edgeTopRight,
      MedhaAnchor.edgeMiddleRight,
      MedhaAnchor.edgeLowerRight,
    ];
    final interests = <MedhaInterestTarget>[];
    if (activeContext != null) {
      final isBrief =
          activeContext.contentMode == MedhaContentMode.quickBrief ||
              activeContext.contentMode == MedhaContentMode.swipeDeck;
      interests.add(
        MedhaInterestTarget(
          bounds: Rect.fromLTWH(
            screenSize.width * 0.12,
            screenSize.height * (isBrief ? 0.22 : 0.16),
            screenSize.width * 0.76,
            screenSize.height * (isBrief ? 0.48 : 0.22),
          ),
          type: isBrief
              ? MedhaInterestType.briefCard
              : MedhaInterestType.headline,
          priority: 0.9,
        ),
      );
      if (activeContext.keyNumbers.isNotEmpty) {
        interests.add(
          MedhaInterestTarget(
            bounds: Rect.fromLTWH(
              screenSize.width * 0.12,
              screenSize.height * 0.52,
              screenSize.width * 0.76,
              screenSize.height * 0.16,
            ),
            type: MedhaInterestType.keyNumber,
            priority: 0.72,
          ),
        );
      }
    } else if (widget.screenType.contains('discover')) {
      interests.add(
        MedhaInterestTarget(
          bounds: Rect.fromLTWH(
            screenSize.width * 0.08,
            screenSize.height * 0.18,
            screenSize.width * 0.84,
            screenSize.height * 0.3,
          ),
          type: MedhaInterestType.image,
          priority: 0.65,
        ),
      );
    }

    const navigationMargin = 12.0;
    final protectedBottomInset = widget.bottomInset + safePadding.bottom;
    final bottomControls = Rect.fromLTWH(
      0,
      screenSize.height - protectedBottomInset - navigationMargin,
      screenSize.width,
      protectedBottomInset + navigationMargin,
    );
    return MedhaEnvironment(
      screenType: widget.screenType,
      viewportSize: screenSize,
      spriteSize: renderedPetSize,
      bottomInset: protectedBottomInset,
      safePadding: safePadding,
      bottomNavigationMargin: navigationMargin,
      safeAnchors: [
        ...edgeAnchors,
        if (interests.isNotEmpty) ...const [
          MedhaAnchor.contentInterestLeft,
          MedhaAnchor.contentInterestRight,
        ],
      ],
      exclusionZones: [bottomControls],
      interestTargets: interests,
      allowRoaming: widget.allowRoaming && !widget.minimal,
      reducedMotion: reducedMotion,
    );
  }

  Duration _tapReactionDuration(MedhaCompanionType companion) =>
      switch (companion) {
        MedhaCompanionType.zuzu => const Duration(milliseconds: 270),
        MedhaCompanionType.kiro => const Duration(milliseconds: 340),
        MedhaCompanionType.momo => const Duration(milliseconds: 440),
        MedhaCompanionType.lumi => const Duration(milliseconds: 520),
        MedhaCompanionType.nishi => const Duration(milliseconds: 620),
      };

  Future<void> _showOptions(BuildContext context) async {
    final navContext = _effectiveNavContext;
    final action = await showModalBottomSheet<String>(
      context: navContext,
      backgroundColor: AppTheme.cardColor(navContext),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Change companion'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide for this session'),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'hide') {
      ref.read(medhaHiddenForSessionProvider.notifier).state = true;
    }
    if (action == 'change') await _changeCompanion();
  }

  Future<void> _changeCompanion() async {
    final navContext = _effectiveNavContext;
    var selected = ref.read(medhaPreferencesProvider).companion;
    final result = await showModalBottomSheet<MedhaCompanionType>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose your companion',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                MedhaCompanionSelector(
                  selected: selected,
                  compact: true,
                  onSelected: (value) => setModalState(() => selected = value),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                  ),
                  child: Text('Choose ${selected.profile.name}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      await ref.read(medhaPreferencesProvider.notifier).selectCompanion(result);
    }
  }
}
