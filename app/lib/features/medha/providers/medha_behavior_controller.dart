import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medha_behavior_models.dart';
import '../models/medha_models.dart';

final medhaBehaviorControllerProvider =
    StateNotifierProvider<MedhaBehaviorController, MedhaBehaviorSnapshot>(
  (ref) => MedhaBehaviorController(),
);

class MedhaBehaviorController extends StateNotifier<MedhaBehaviorSnapshot> {
  MedhaBehaviorController({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(MedhaBehaviorSnapshot());

  final DateTime Function() _clock;
  MedhaCompanionType _companion = MedhaCompanionType.kiro;
  MedhaEnvironment _environment = MedhaEnvironment.initial();
  Timer? _decisionTimer;
  Timer? _settleTimer;
  Timer? _movementTimer;
  final List<DateTime> _recentTaps = [];
  int _decisionIndex = 0;
  bool _paused = false;
  DateTime _lastScrollEvent = DateTime.fromMillisecondsSinceEpoch(0);

  MedhaEnvironment get environment => _environment;

  void configure({
    required MedhaCompanionType companion,
    required MedhaEnvironment environment,
  }) {
    final companionChanged = companion != _companion;
    final screenChanged = environment.screenType != _environment.screenType;
    _companion = companion;
    _environment = environment;

    var anchor = state.targetAnchor;
    if (!environment.isAnchorValid(anchor)) {
      anchor = _nearestValidAnchor(anchor);
    }
    state = state.copyWith(
      currentAnchor: anchor,
      targetAnchor: anchor,
      movementDuration: companion.behaviorTuning.movementDuration,
      revision: state.revision + 1,
    );
    if (screenChanged) {
      onNavigation();
    } else if (companionChanged) {
      _emit(
        behavior: MedhaBehaviorState.attention,
        emotion: MedhaEmotion.happy,
        attention: 0.8,
      );
      _settleAfter(const Duration(milliseconds: 900));
    } else {
      _scheduleDecision();
    }
  }

  void onNavigation() {
    _wake(
      behavior: MedhaBehaviorState.curious,
      emotion: MedhaEmotion.curious,
      attention: 0.9,
    );
    _lookTowardBestInterest();
    _settleAfter(const Duration(milliseconds: 1100));
  }

  void onArticleChanged() => onNavigation();

  void onCardChanged(double direction) {
    _wake(
      behavior: MedhaBehaviorState.curious,
      emotion: MedhaEmotion.curious,
      attention: 0.85,
    );
    _emit(horizontalLook: direction.sign, verticalLook: 0);
    _settleAfter(const Duration(milliseconds: 850), inspectContent: true);
  }

  void onScroll({required double delta, required double velocity}) {
    final now = _clock();
    if (now.difference(_lastScrollEvent) < const Duration(milliseconds: 90)) {
      _settleAfter(
        Duration(
          milliseconds: (700 + (velocity.abs().clamp(0, 1400) / 2)).round(),
        ),
        inspectContent: true,
      );
      return;
    }
    _lastScrollEvent = now;
    final fast = velocity.abs() >= 900 || delta.abs() >= 20;
    _wake(
      behavior: MedhaBehaviorState.scrollFollowing,
      emotion: fast ? MedhaEmotion.surprised : MedhaEmotion.focused,
      attention: fast ? 1 : 0.72,
    );
    _emit(
      verticalLook: delta >= 0 ? 1 : -1,
      horizontalLook: 0,
      energy: (state.energy + (fast ? 0.07 : 0.025)).clamp(0, 1),
    );
    final settleMs = (700 + (velocity.abs().clamp(0, 1400) / 2)).round();
    _settleAfter(
      Duration(milliseconds: settleMs.clamp(700, 1400)),
      inspectContent: true,
    );
  }

  MedhaTapDisposition onTap() {
    final now = _clock();
    _recentTaps.removeWhere(
      (tap) => now.difference(tap) > const Duration(milliseconds: 1250),
    );
    _recentTaps.add(now);
    final rapid = _recentTaps.length >= 3;

    _wake(
      behavior:
          rapid ? MedhaBehaviorState.playing : MedhaBehaviorState.attention,
      emotion: rapid ? _rapidTapEmotion : MedhaEmotion.curious,
      attention: 1,
    );
    _emit(
      energy: (state.energy + (rapid ? 0.16 : 0.07)).clamp(0, 1),
      interactionCooldown: Duration(milliseconds: rapid ? 1200 : 500),
    );
    _settleAfter(Duration(milliseconds: rapid ? 1100 : 760));
    return rapid ? MedhaTapDisposition.playful : MedhaTapDisposition.openMenu;
  }

  MedhaEmotion get _rapidTapEmotion => switch (_companion) {
        MedhaCompanionType.kiro => MedhaEmotion.annoyed,
        MedhaCompanionType.lumi => MedhaEmotion.surprised,
        MedhaCompanionType.momo => MedhaEmotion.excited,
        MedhaCompanionType.zuzu => MedhaEmotion.excited,
        MedhaCompanionType.nishi => MedhaEmotion.annoyed,
      };

  void onDragStart() {
    _cancelTransientTimers();
    _wake(
      behavior: MedhaBehaviorState.attention,
      emotion: MedhaEmotion.focused,
      attention: 1,
    );
    _emit(isDragging: true);
  }

  void onDragEnd(MedhaAnchor requestedAnchor) {
    final anchor = _environment.isAnchorValid(requestedAnchor)
        ? requestedAnchor
        : _nearestValidAnchor(requestedAnchor);
    _emit(
      isDragging: false,
      currentAnchor: anchor,
      targetAnchor: anchor,
      behavior: MedhaBehaviorState.looking,
      emotion: MedhaEmotion.curious,
      lastMovementTime: _clock(),
    );
    _settleAfter(const Duration(milliseconds: 850), inspectContent: true);
  }

  void onThinking() {
    _wake(
      behavior: MedhaBehaviorState.thinking,
      emotion: MedhaEmotion.focused,
      attention: 1,
    );
  }

  void onAnswer({required bool usedFallback, bool outOfScope = false}) {
    _wake(
      behavior: outOfScope
          ? MedhaBehaviorState.looking
          : (usedFallback
              ? MedhaBehaviorState.looking
              : MedhaBehaviorState.celebrating),
      emotion: outOfScope
          ? MedhaEmotion.curious
          : (usedFallback ? MedhaEmotion.curious : MedhaEmotion.happy),
      attention: outOfScope ? 0.7 : (usedFallback ? 0.65 : 0.9),
    );
    _settleAfter(Duration(milliseconds: usedFallback ? 700 : 950));
  }

  void onSpeaking() {
    _wake(
      behavior: MedhaBehaviorState.speaking,
      emotion: MedhaEmotion.focused,
      attention: 0.9,
    );
  }

  void onReading() {
    _wake(
      behavior: MedhaBehaviorState.reading,
      emotion: MedhaEmotion.focused,
      attention: 0.7,
    );
    _scheduleDecision();
  }

  void onAppPaused() {
    _paused = true;
    _cancelTransientTimers();
    _decisionTimer?.cancel();
    _emit(
      behavior: MedhaBehaviorState.resting,
      emotion: MedhaEmotion.sleepy,
      energy: 0.2,
      attention: 0,
      verticalLook: 0,
      horizontalLook: 0,
    );
  }

  void onAppResumed() {
    final slept = _clock().difference(state.lastUserInteraction) >
        const Duration(seconds: 20);
    _paused = false;
    _wake(
      behavior: MedhaBehaviorState.attention,
      emotion: slept ? MedhaEmotion.happy : MedhaEmotion.curious,
      attention: 0.9,
    );
    _settleAfter(const Duration(milliseconds: 950));
  }

  void _wake({
    required MedhaBehaviorState behavior,
    required MedhaEmotion emotion,
    required double attention,
  }) {
    _decisionTimer?.cancel();
    _settleTimer?.cancel();
    _movementTimer?.cancel();
    _emit(
      behavior: behavior,
      emotion: emotion,
      energy: (state.energy + 0.12).clamp(0, 1),
      attention: attention,
      lastUserInteraction: _clock(),
    );
  }

  void _settleAfter(Duration delay, {bool inspectContent = false}) {
    _settleTimer?.cancel();
    _settleTimer = Timer(delay, () {
      if (_paused || state.isDragging) return;
      if (inspectContent) _lookTowardBestInterest();
      _emit(
        behavior: inspectContent && _environment.interestTargets.isNotEmpty
            ? MedhaBehaviorState.looking
            : MedhaBehaviorState.idle,
        emotion: inspectContent && _environment.interestTargets.isNotEmpty
            ? MedhaEmotion.curious
            : MedhaEmotion.neutral,
        attention: inspectContent ? 0.55 : 0.3,
        verticalLook: 0,
      );
      _scheduleDecision();
    });
  }

  void _scheduleDecision() {
    _decisionTimer?.cancel();
    if (_paused) return;
    final tuning = _companion.behaviorTuning;
    _decisionTimer = Timer(tuning.idleDecisionDelay, _decideIdleBehavior);
  }

  void _decideIdleBehavior() {
    if (_paused || state.isDragging) return;
    final tuning = _companion.behaviorTuning;
    final idleFor = _clock().difference(state.lastUserInteraction);
    if (idleFor < state.interactionCooldown) {
      _decisionTimer = Timer(
        state.interactionCooldown - idleFor,
        _decideIdleBehavior,
      );
      return;
    }
    if (idleFor >= tuning.restDelay + const Duration(seconds: 38)) {
      _emit(
        behavior: MedhaBehaviorState.resting,
        emotion: MedhaEmotion.sleepy,
        energy: 0.08,
        attention: 0,
        verticalLook: 0,
        horizontalLook: 0,
      );
      _decisionTimer = Timer(const Duration(seconds: 28), _decideIdleBehavior);
      return;
    }
    if (idleFor >= tuning.restDelay) {
      _emit(
        behavior: MedhaBehaviorState.resting,
        emotion: MedhaEmotion.sleepy,
        energy: (state.energy - 0.12).clamp(0, 1),
        attention: 0.08,
      );
      _scheduleDecision();
      return;
    }

    final phase = _decisionIndex++ % 5;
    if (_environment.reducedMotion) {
      _emit(
        behavior:
            phase.isEven ? MedhaBehaviorState.looking : MedhaBehaviorState.idle,
        emotion: phase.isEven ? MedhaEmotion.curious : MedhaEmotion.neutral,
        horizontalLook: phase.isEven ? (phase == 0 ? -0.45 : 0.45) : 0,
        attention: 0.35,
      );
    } else if (phase == 1 &&
        _environment.allowRoaming &&
        tuning.activity >= 0.3) {
      _moveToNearbyAnchor();
    } else if (phase == 3 && tuning.activity >= 0.6) {
      _emit(
        behavior: MedhaBehaviorState.playing,
        emotion: MedhaEmotion.happy,
        attention: 0.55,
      );
      _settleAfter(const Duration(milliseconds: 800));
      return;
    } else if (_environment.interestTargets.isNotEmpty && phase.isEven) {
      _lookTowardBestInterest();
      _emit(
        behavior: MedhaBehaviorState.looking,
        emotion: MedhaEmotion.curious,
        attention: 0.52,
      );
    } else {
      _emit(
        behavior:
            phase == 4 ? MedhaBehaviorState.resting : MedhaBehaviorState.idle,
        emotion: phase == 4 ? MedhaEmotion.bored : MedhaEmotion.neutral,
        energy: (state.energy - 0.035).clamp(0, 1),
        attention: 0.2,
        horizontalLook: 0,
        verticalLook: 0,
      );
    }
    _scheduleDecision();
  }

  void _moveToNearbyAnchor() {
    final valid = _environment.safeAnchors
        .where(_environment.isAnchorValid)
        .where((anchor) => anchor != state.targetAnchor)
        .toList();
    if (valid.isEmpty) {
      _scheduleDecision();
      return;
    }
    valid.sort((a, b) {
      final current = _environment.anchorPoint(state.targetAnchor);
      return (current - _environment.anchorPoint(a))
          .distanceSquared
          .compareTo((current - _environment.anchorPoint(b)).distanceSquared);
    });
    final target = valid[_decisionIndex % valid.length.clamp(1, 2)];
    final from = _environment.anchorPoint(state.targetAnchor);
    final to = _environment.anchorPoint(target);
    final distanceFactor = ((to - from).distance / 220).clamp(0.75, 1.7);
    final base = _companion.behaviorTuning.movementDuration.inMilliseconds;
    final duration = Duration(milliseconds: (base * distanceFactor).round());
    _emit(
      behavior: MedhaBehaviorState.playing,
      emotion: MedhaEmotion.curious,
      targetAnchor: target,
      movementDuration: duration,
      horizontalLook: to.dx >= from.dx ? 1 : -1,
      attention: 0.62,
      lastMovementTime: _clock(),
    );
    _movementTimer?.cancel();
    _movementTimer = Timer(duration, () {
      _emit(
        currentAnchor: target,
        behavior: MedhaBehaviorState.looking,
        emotion: MedhaEmotion.curious,
        horizontalLook: 0,
      );
      _scheduleDecision();
    });
  }

  void _lookTowardBestInterest() {
    if (_environment.interestTargets.isEmpty) return;
    final targets = [..._environment.interestTargets]
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final target = targets.first.bounds.center;
    final pet = _environment.anchorPoint(state.targetAnchor) +
        Offset(_environment.spriteSize / 2, _environment.spriteSize / 2);
    _emit(
      horizontalLook: (target.dx - pet.dx).sign,
      verticalLook: ((target.dy - pet.dy) / 180).clamp(-1, 1),
    );
  }

  MedhaAnchor _nearestValidAnchor(MedhaAnchor requested) {
    final valid =
        _environment.safeAnchors.where(_environment.isAnchorValid).toList();
    if (valid.isEmpty) return MedhaAnchor.edgeLowerRight;
    final requestedPoint = _environment.anchorPoint(requested);
    valid.sort(
      (a, b) => (requestedPoint - _environment.anchorPoint(a))
          .distanceSquared
          .compareTo(
            (requestedPoint - _environment.anchorPoint(b)).distanceSquared,
          ),
    );
    return valid.first;
  }

  void _emit({
    MedhaBehaviorState? behavior,
    MedhaEmotion? emotion,
    double? energy,
    double? attention,
    Duration? interactionCooldown,
    DateTime? lastUserInteraction,
    DateTime? lastMovementTime,
    MedhaAnchor? currentAnchor,
    MedhaAnchor? targetAnchor,
    double? verticalLook,
    double? horizontalLook,
    Duration? movementDuration,
    bool? isDragging,
  }) {
    state = state.copyWith(
      currentBehavior: behavior,
      currentEmotion: emotion,
      energy: energy,
      attention: attention,
      interactionCooldown: interactionCooldown,
      lastUserInteraction: lastUserInteraction,
      lastMovementTime: lastMovementTime,
      currentAnchor: currentAnchor,
      targetAnchor: targetAnchor,
      verticalLook: verticalLook,
      horizontalLook: horizontalLook,
      movementDuration: movementDuration,
      isDragging: isDragging,
      revision: state.revision + 1,
    );
  }

  void _cancelTransientTimers() {
    _settleTimer?.cancel();
    _movementTimer?.cancel();
  }

  @override
  void dispose() {
    _decisionTimer?.cancel();
    _settleTimer?.cancel();
    _movementTimer?.cancel();
    super.dispose();
  }
}
