import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/medha_behavior_models.dart';
import '../models/medha_models.dart';

class MedhaCompanionSprite extends StatefulWidget {
  const MedhaCompanionSprite({
    super.key,
    required this.companion,
    this.state = MedhaBehaviorState.idle,
    this.emotion = MedhaEmotion.neutral,
    this.size = 82,
    this.verticalLook = 0,
    this.horizontalLook = 0,
  });

  final MedhaCompanionType companion;
  final MedhaBehaviorState state;
  final MedhaEmotion emotion;
  final double size;
  final double verticalLook;
  final double horizontalLook;

  @override
  State<MedhaCompanionSprite> createState() => _MedhaCompanionSpriteState();
}

class _MedhaCompanionSpriteState extends State<MedhaCompanionSprite>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  Timer? _blinkTimer;
  bool _eyesClosed = false;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.companion),
    )..repeat();
    _scheduleBlink();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
      _scheduleBlink();
    } else {
      _controller.stop();
      _blinkTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant MedhaCompanionSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companion != widget.companion) {
      _controller.duration = _durationFor(widget.companion);
      _controller
        ..reset()
        ..repeat();
      _eyesClosed = false;
      _scheduleBlink();
    }
  }

  Duration _durationFor(MedhaCompanionType type) => switch (type) {
        MedhaCompanionType.zuzu => const Duration(milliseconds: 1900),
        MedhaCompanionType.momo => const Duration(milliseconds: 2400),
        MedhaCompanionType.kiro => const Duration(milliseconds: 3100),
        MedhaCompanionType.lumi => const Duration(milliseconds: 3900),
        MedhaCompanionType.nishi => const Duration(milliseconds: 4700),
      };

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final base = widget.companion == MedhaCompanionType.nishi ? 3400 : 2800;
    final delay = Duration(milliseconds: base + _random.nextInt(5501 - base));
    _blinkTimer = Timer(delay, () async {
      if (!mounted) return;
      await _blinkOnce();
      if (_random.nextInt(7) == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (mounted) await _blinkOnce();
      }
      _scheduleBlink();
    });
  }

  Future<void> _blinkOnce() async {
    if (!mounted) return;
    setState(() => _eyesClosed = true);
    await Future<void>.delayed(
      Duration(milliseconds: 85 + _random.nextInt(55)),
    );
    if (mounted) setState(() => _eyesClosed = false);
  }

  Color get _glowColor => switch (widget.companion) {
        MedhaCompanionType.kiro => const Color(0xFF79A9FF),
        MedhaCompanionType.lumi => const Color(0xFFFFD77A),
        MedhaCompanionType.momo => const Color(0xFF8CB9FF),
        MedhaCompanionType.zuzu => const Color(0xFFA78BFA),
        MedhaCompanionType.nishi => const Color(0xFFA8C97F),
      };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final profile = widget.companion.profile;
    final restingWithEyesClosed = widget.state == MedhaBehaviorState.resting &&
        widget.emotion == MedhaEmotion.sleepy;
    final nishiThinking = widget.state == MedhaBehaviorState.thinking &&
        widget.companion == MedhaCompanionType.nishi;
    final showClosedEyes =
        _eyesClosed || restingWithEyesClosed || nishiThinking;
    return Semantics(
      image: true,
      label: 'MEDHA companion ${widget.companion.profile.name}',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 45),
            child: Image.asset(
              showClosedEyes
                  ? profile.closedEyeAssetPath
                  : profile.openEyeAssetPath,
              key: ValueKey(showClosedEyes),
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          builder: (context, child) {
            final wave = math.sin(_controller.value * math.pi * 2);
            final amplitude = switch (widget.state) {
              MedhaBehaviorState.thinking => 2.8,
              MedhaBehaviorState.speaking => 2.1,
              MedhaBehaviorState.scrollFollowing => 1.5,
              MedhaBehaviorState.attention => 2.4,
              MedhaBehaviorState.playing => 3.2,
              MedhaBehaviorState.resting => 0.35,
              _ => switch (widget.companion) {
                  MedhaCompanionType.lumi => 1.25,
                  MedhaCompanionType.momo => 1.45,
                  MedhaCompanionType.zuzu => 1.15,
                  MedhaCompanionType.kiro => 1.05,
                  MedhaCompanionType.nishi => 0.55,
                },
            };
            final personalityTilt = switch (widget.companion) {
              MedhaCompanionType.zuzu => 0.018,
              MedhaCompanionType.momo => 0.013,
              MedhaCompanionType.kiro => 0.010,
              MedhaCompanionType.lumi => 0.006,
              MedhaCompanionType.nishi => 0.004,
            };
            final stateTilt = switch (widget.state) {
              MedhaBehaviorState.scrollFollowing => 0.018,
              MedhaBehaviorState.curious => -0.026,
              MedhaBehaviorState.thinking => 0.013,
              MedhaBehaviorState.attention => -0.022,
              MedhaBehaviorState.playing => 0.035,
              _ => 0.0,
            };
            final isAttentive = widget.state == MedhaBehaviorState.curious ||
                widget.state == MedhaBehaviorState.thinking ||
                widget.state == MedhaBehaviorState.attention ||
                widget.state == MedhaBehaviorState.playing ||
                widget.state == MedhaBehaviorState.speaking;
            final emotionGlow = switch (widget.emotion) {
              MedhaEmotion.happy || MedhaEmotion.excited => 0.12,
              MedhaEmotion.focused => 0.07,
              MedhaEmotion.sleepy => -0.05,
              _ => 0.0,
            };
            final glow = (isAttentive
                    ? 0.28 + (wave + 1) * 0.08 + emotionGlow
                    : 0.12 + emotionGlow)
                .clamp(0.06, 0.52);
            final animatedChild = DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _glowColor.withValues(alpha: glow),
                    _glowColor.withValues(alpha: 0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withValues(alpha: glow * 0.55),
                    blurRadius: isAttentive ? 20 : 11,
                    spreadRadius: isAttentive ? 1.5 : 0,
                  ),
                ],
              ),
              child: child,
            );
            if (reducedMotion) {
              return Transform.scale(
                scale: 0.998 + ((wave + 1) * 0.002),
                child: animatedChild,
              );
            }
            final emotionTilt = switch (widget.emotion) {
              MedhaEmotion.curious => -0.025,
              MedhaEmotion.surprised => 0.018,
              MedhaEmotion.annoyed => 0.03,
              MedhaEmotion.sleepy => -0.012,
              _ => 0.0,
            };
            final emotionScale = switch (widget.emotion) {
              MedhaEmotion.excited => 1.04,
              MedhaEmotion.surprised => 1.03,
              MedhaEmotion.happy => 1.018,
              MedhaEmotion.sleepy => 0.975,
              _ => 1.0,
            };
            final characterReactionX =
                switch ((widget.state, widget.companion)) {
              (MedhaBehaviorState.attention, MedhaCompanionType.zuzu) =>
                wave * 3.2,
              (MedhaBehaviorState.playing, MedhaCompanionType.zuzu) =>
                wave * 4.2,
              (MedhaBehaviorState.playing, MedhaCompanionType.momo) =>
                wave * 1.8,
              (MedhaBehaviorState.thinking, MedhaCompanionType.zuzu) =>
                wave * 2.4,
              _ => 0.0,
            };
            final characterReactionY =
                switch ((widget.state, widget.companion)) {
              (MedhaBehaviorState.attention, MedhaCompanionType.kiro) =>
                -wave.abs() * 3.0,
              (MedhaBehaviorState.attention, MedhaCompanionType.lumi) =>
                -1.8 + wave * 0.7,
              (MedhaBehaviorState.attention, MedhaCompanionType.momo) =>
                -wave.abs() * 4.0,
              (MedhaBehaviorState.attention, MedhaCompanionType.nishi) =>
                wave * 0.7,
              (MedhaBehaviorState.thinking, MedhaCompanionType.kiro) =>
                -wave.abs() * 1.4,
              (MedhaBehaviorState.thinking, MedhaCompanionType.lumi) =>
                -1.3 + wave * 0.8,
              (MedhaBehaviorState.thinking, MedhaCompanionType.momo) =>
                wave * 1.2,
              _ => 0.0,
            };
            final characterReactionTilt =
                switch ((widget.state, widget.companion)) {
              (MedhaBehaviorState.attention, MedhaCompanionType.kiro) => -0.022,
              (MedhaBehaviorState.attention, MedhaCompanionType.momo) =>
                wave * 0.032,
              (MedhaBehaviorState.attention, MedhaCompanionType.zuzu) =>
                wave * 0.065,
              (MedhaBehaviorState.attention, MedhaCompanionType.nishi) =>
                wave * 0.006,
              (MedhaBehaviorState.playing, MedhaCompanionType.zuzu) =>
                wave * 0.085,
              _ => 0.0,
            };
            return Transform.translate(
              offset: Offset(
                widget.horizontalLook * 2.4 + characterReactionX,
                wave * amplitude +
                    widget.verticalLook * 1.7 +
                    characterReactionY,
              ),
              child: Transform.rotate(
                angle: stateTilt +
                    emotionTilt +
                    characterReactionTilt +
                    wave * personalityTilt +
                    widget.horizontalLook * 0.022,
                child: Transform.scale(
                  scale: emotionScale *
                      (widget.state == MedhaBehaviorState.attention
                          ? 1.035
                          : 0.996 + ((wave + 1) * 0.004)),
                  child: animatedChild,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
