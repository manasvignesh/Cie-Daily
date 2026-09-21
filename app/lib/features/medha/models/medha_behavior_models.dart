import 'package:flutter/material.dart';

import 'medha_models.dart';

enum MedhaEmotion {
  neutral,
  happy,
  curious,
  excited,
  surprised,
  focused,
  sleepy,
  bored,
  annoyed,
}

enum MedhaAnchor {
  edgeTopLeft,
  edgeMiddleLeft,
  edgeLowerLeft,
  edgeTopRight,
  edgeMiddleRight,
  edgeLowerRight,
  bottomLeft,
  bottomMiddle,
  bottomRight,
  contentInterestLeft,
  contentInterestRight,
}

enum MedhaInterestType { image, headline, keyNumber, briefCard, illustration }

class MedhaInterestTarget {
  const MedhaInterestTarget({
    required this.bounds,
    required this.type,
    this.priority = 0.5,
  });

  final Rect bounds;
  final MedhaInterestType type;
  final double priority;
}

class MedhaEnvironment {
  const MedhaEnvironment({
    required this.screenType,
    required this.viewportSize,
    required this.spriteSize,
    required this.bottomInset,
    required this.safeAnchors,
    this.safePadding = EdgeInsets.zero,
    this.bottomNavigationMargin = 12,
    this.exclusionZones = const [],
    this.interestTargets = const [],
    this.allowRoaming = false,
    this.reducedMotion = false,
  });

  factory MedhaEnvironment.initial() => const MedhaEnvironment(
        screenType: 'unknown',
        viewportSize: Size(360, 720),
        spriteSize: 76,
        bottomInset: 84,
        safeAnchors: [MedhaAnchor.edgeLowerRight],
      );

  final String screenType;
  final Size viewportSize;
  final double spriteSize;
  final double bottomInset;
  final EdgeInsets safePadding;
  final double bottomNavigationMargin;
  final List<MedhaAnchor> safeAnchors;
  final List<Rect> exclusionZones;
  final List<MedhaInterestTarget> interestTargets;
  final bool allowRoaming;
  final bool reducedMotion;

  bool isAnchorValid(MedhaAnchor anchor) {
    if (!safeAnchors.contains(anchor)) return false;
    final bounds = anchorBounds(anchor);
    return !exclusionZones.any((zone) => zone.overlaps(bounds));
  }

  Rect anchorBounds(MedhaAnchor anchor) {
    final point = anchorPoint(anchor);
    return Rect.fromLTWH(point.dx, point.dy, spriteSize, spriteSize);
  }

  Offset anchorPoint(MedhaAnchor anchor) {
    final width = viewportSize.width;
    final height = viewportSize.height;
    final safeTop = safePadding.top + 8;
    final navigationTop = height - bottomInset - bottomNavigationMargin;
    final safeBottom = navigationTop - spriteSize;
    final top = (height * 0.14).clamp(safeTop, safeBottom);
    final middle = (height * 0.42).clamp(safeTop, safeBottom);
    final lower = (height * 0.64).clamp(safeTop, safeBottom);
    final normalOutside = spriteSize * 0.05;
    final peekOutside = spriteSize * 0.20;
    final edgeLeft = safePadding.left - normalOutside;
    final edgeRight = width - safePadding.right - spriteSize + normalOutside;
    final peekLeft = safePadding.left - peekOutside;
    final peekRight = width - safePadding.right - spriteSize + peekOutside;
    final fullLeft = safePadding.left + 8;
    final fullRight = width - safePadding.right - spriteSize - 8;

    final raw = switch (anchor) {
      MedhaAnchor.edgeTopLeft => Offset(edgeLeft, top),
      MedhaAnchor.edgeMiddleLeft => Offset(edgeLeft, middle),
      MedhaAnchor.edgeLowerLeft => Offset(edgeLeft, lower),
      MedhaAnchor.edgeTopRight => Offset(edgeRight, top),
      MedhaAnchor.edgeMiddleRight => Offset(edgeRight, middle),
      MedhaAnchor.edgeLowerRight => Offset(edgeRight, lower),
      MedhaAnchor.bottomLeft => Offset(fullLeft, safeBottom),
      MedhaAnchor.bottomMiddle => Offset((width - spriteSize) / 2, safeBottom),
      MedhaAnchor.bottomRight => Offset(fullRight, safeBottom),
      MedhaAnchor.contentInterestLeft => Offset(peekLeft, _interestY()),
      MedhaAnchor.contentInterestRight => Offset(peekRight, _interestY()),
    };
    final intentionalPeek = anchor == MedhaAnchor.contentInterestLeft ||
        anchor == MedhaAnchor.contentInterestRight;
    final allowedOutside = intentionalPeek ? peekOutside : normalOutside;
    return Offset(
      raw.dx.clamp(
        safePadding.left - allowedOutside,
        width - safePadding.right - spriteSize + allowedOutside,
      ),
      raw.dy.clamp(safeTop, safeBottom),
    );
  }

  double _interestY() {
    if (interestTargets.isEmpty) return viewportSize.height * 0.36;
    final sorted = [...interestTargets]
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return (sorted.first.bounds.center.dy - spriteSize / 2).clamp(
      safePadding.top + 8,
      viewportSize.height - bottomInset - bottomNavigationMargin - spriteSize,
    );
  }
}

class MedhaPersonalityTuning {
  const MedhaPersonalityTuning({
    required this.activity,
    required this.idleDecisionDelay,
    required this.movementDuration,
    required this.restDelay,
  });

  final double activity;
  final Duration idleDecisionDelay;
  final Duration movementDuration;
  final Duration restDelay;
}

extension MedhaBehaviorTuning on MedhaCompanionType {
  MedhaPersonalityTuning get behaviorTuning => switch (this) {
        MedhaCompanionType.kiro => const MedhaPersonalityTuning(
            activity: 0.75,
            idleDecisionDelay: Duration(seconds: 9),
            movementDuration: Duration(milliseconds: 720),
            restDelay: Duration(seconds: 48),
          ),
        MedhaCompanionType.lumi => const MedhaPersonalityTuning(
            activity: 0.35,
            idleDecisionDelay: Duration(seconds: 17),
            movementDuration: Duration(milliseconds: 1450),
            restDelay: Duration(seconds: 42),
          ),
        MedhaCompanionType.momo => const MedhaPersonalityTuning(
            activity: 0.65,
            idleDecisionDelay: Duration(seconds: 11),
            movementDuration: Duration(milliseconds: 920),
            restDelay: Duration(seconds: 46),
          ),
        MedhaCompanionType.zuzu => const MedhaPersonalityTuning(
            activity: 0.85,
            idleDecisionDelay: Duration(seconds: 8),
            movementDuration: Duration(milliseconds: 520),
            restDelay: Duration(seconds: 54),
          ),
        MedhaCompanionType.nishi => const MedhaPersonalityTuning(
            activity: 0.20,
            idleDecisionDelay: Duration(seconds: 23),
            movementDuration: Duration(milliseconds: 1800),
            restDelay: Duration(seconds: 34),
          ),
      };
}

class MedhaBehaviorSnapshot {
  MedhaBehaviorSnapshot({
    this.currentBehavior = MedhaBehaviorState.idle,
    this.currentEmotion = MedhaEmotion.neutral,
    this.energy = 0.7,
    this.attention = 0.25,
    this.interactionCooldown = Duration.zero,
    DateTime? lastUserInteraction,
    DateTime? lastMovementTime,
    this.currentAnchor = MedhaAnchor.edgeLowerRight,
    this.targetAnchor = MedhaAnchor.edgeLowerRight,
    this.verticalLook = 0,
    this.horizontalLook = 0,
    this.movementDuration = const Duration(milliseconds: 720),
    this.isDragging = false,
    this.revision = 0,
  })  : lastUserInteraction = lastUserInteraction ?? DateTime.now(),
        lastMovementTime = lastMovementTime ?? DateTime.now();

  final MedhaBehaviorState currentBehavior;
  final MedhaEmotion currentEmotion;
  final double energy;
  final double attention;
  final Duration interactionCooldown;
  final DateTime lastUserInteraction;
  final DateTime lastMovementTime;
  final MedhaAnchor currentAnchor;
  final MedhaAnchor targetAnchor;
  final double verticalLook;
  final double horizontalLook;
  final Duration movementDuration;
  final bool isDragging;
  final int revision;

  MedhaBehaviorSnapshot copyWith({
    MedhaBehaviorState? currentBehavior,
    MedhaEmotion? currentEmotion,
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
    int? revision,
  }) {
    return MedhaBehaviorSnapshot(
      currentBehavior: currentBehavior ?? this.currentBehavior,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      energy: energy ?? this.energy,
      attention: attention ?? this.attention,
      interactionCooldown: interactionCooldown ?? this.interactionCooldown,
      lastUserInteraction: lastUserInteraction ?? this.lastUserInteraction,
      lastMovementTime: lastMovementTime ?? this.lastMovementTime,
      currentAnchor: currentAnchor ?? this.currentAnchor,
      targetAnchor: targetAnchor ?? this.targetAnchor,
      verticalLook: verticalLook ?? this.verticalLook,
      horizontalLook: horizontalLook ?? this.horizontalLook,
      movementDuration: movementDuration ?? this.movementDuration,
      isDragging: isDragging ?? this.isDragging,
      revision: revision ?? this.revision,
    );
  }
}

enum MedhaTapDisposition { openMenu, playful }
