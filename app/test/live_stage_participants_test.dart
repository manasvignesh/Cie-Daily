import 'package:flutter_test/flutter_test.dart';
import 'package:cie_connect/features/spaces/services/live_stage_participants.dart';

void main() {
  List<String> stage(List<String> remote, {String local = 'viewer'}) =>
      liveStageParticipants<String>(
        remote: remote,
        local: local,
        hasVideo: (p) => p == 'camera' || p == 'share',
        hasScreenShare: (p) => p == 'share',
        identity: (p) => p,
      );

  test('empty room shows waiting instead of local viewer avatar', () {
    expect(stage([]), isEmpty);
  });
  test('remote camera precedes other listeners and local viewer', () {
    expect(stage(['listener', 'camera']), ['camera', 'listener']);
  });
  test('remote screen share takes priority over camera', () {
    expect(stage(['camera', 'share']), ['share', 'camera']);
  });
  test('local publishing camera remains available after remote broadcaster',
      () {
    expect(stage(['share'], local: 'camera'), ['share', 'camera']);
  });
  test('participant departure recomputes stage', () {
    expect(stage(['camera']), ['camera']);
    expect(stage([]), isEmpty);
  });
}
