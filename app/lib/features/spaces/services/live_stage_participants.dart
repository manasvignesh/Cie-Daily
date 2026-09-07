/// Prefer remote broadcasts over a viewer's local, camera-less participant.
List<T> liveStageParticipants<T>({
  required Iterable<T> remote,
  required T? local,
  required bool Function(T) hasVideo,
  required bool Function(T) hasScreenShare,
  required String Function(T) identity,
}) {
  int priority(T participant) => hasScreenShare(participant)
      ? 0
      : hasVideo(participant)
          ? 1
          : 2;
  final result = remote.toList()
    ..sort((a, b) {
      final rank = priority(a).compareTo(priority(b));
      return rank != 0 ? rank : identity(a).compareTo(identity(b));
    });
  if (local != null && hasVideo(local)) result.add(local);
  return result;
}
