import 'package:cie_connect/features/medha/models/medha_behavior_models.dart';
import 'package:cie_connect/features/medha/models/medha_models.dart';
import 'package:cie_connect/features/medha/providers/medha_behavior_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MedhaEnvironment environment({bool reducedMotion = false}) {
    return MedhaEnvironment(
      screenType: '/discover',
      viewportSize: const Size(400, 800),
      spriteSize: 76,
      bottomInset: 84,
      safeAnchors: const [
        MedhaAnchor.edgeTopLeft,
        MedhaAnchor.edgeMiddleLeft,
        MedhaAnchor.edgeLowerRight,
      ],
      exclusionZones: const [Rect.fromLTWH(0, 716, 400, 84)],
      interestTargets: const [
        MedhaInterestTarget(
          bounds: Rect.fromLTWH(48, 180, 304, 220),
          type: MedhaInterestType.image,
          priority: 0.9,
        ),
      ],
      allowRoaming: true,
      reducedMotion: reducedMotion,
    );
  }

  test('rapid Kiro taps produce one playful mildly-annoyed reaction', () {
    var now = DateTime(2026, 9, 20, 12);
    final controller = MedhaBehaviorController(clock: () => now);
    addTearDown(controller.dispose);
    controller.configure(
      companion: MedhaCompanionType.kiro,
      environment: environment(),
    );

    expect(controller.onTap(), MedhaTapDisposition.openMenu);
    now = now.add(const Duration(milliseconds: 180));
    expect(controller.onTap(), MedhaTapDisposition.openMenu);
    now = now.add(const Duration(milliseconds: 180));
    expect(controller.onTap(), MedhaTapDisposition.playful);
    expect(controller.state.currentBehavior, MedhaBehaviorState.playing);
    expect(controller.state.currentEmotion, MedhaEmotion.annoyed);
  });

  test('fast scroll is surprised and follows the actual direction', () {
    final controller = MedhaBehaviorController();
    addTearDown(controller.dispose);
    controller.configure(
      companion: MedhaCompanionType.kiro,
      environment: environment(),
    );

    controller.onScroll(delta: -24, velocity: 1440);

    expect(
        controller.state.currentBehavior, MedhaBehaviorState.scrollFollowing);
    expect(controller.state.currentEmotion, MedhaEmotion.surprised);
    expect(controller.state.verticalLook, -1);
  });

  test('invalid drag target is recalculated to a published safe anchor', () {
    final controller = MedhaBehaviorController();
    addTearDown(controller.dispose);
    final currentEnvironment = environment();
    controller.configure(
      companion: MedhaCompanionType.kiro,
      environment: currentEnvironment,
    );

    controller.onDragEnd(MedhaAnchor.bottomMiddle);

    expect(
      currentEnvironment.isAnchorValid(controller.state.targetAnchor),
      isTrue,
    );
  });

  test('reduced-motion environment is retained and disables roaming input', () {
    final controller = MedhaBehaviorController();
    addTearDown(controller.dispose);
    controller.configure(
      companion: MedhaCompanionType.kiro,
      environment: environment(reducedMotion: true),
    );

    expect(controller.environment.reducedMotion, isTrue);
    expect(controller.state.targetAnchor, controller.state.currentAnchor);
  });

  test('companion activity and movement tuning remain distinct', () {
    expect(
      MedhaCompanionType.zuzu.behaviorTuning.activity,
      greaterThan(MedhaCompanionType.lumi.behaviorTuning.activity),
    );
    expect(
      MedhaCompanionType.nishi.behaviorTuning.movementDuration,
      greaterThan(MedhaCompanionType.kiro.behaviorTuning.movementDuration),
    );
  });
}
