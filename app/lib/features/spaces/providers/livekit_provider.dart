import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

// In a real app, you would fetch tokens from the backend.
// For this architecture phase, we are establishing the connection provider.

final liveKitRoomProvider = Provider<Room>((ref) {
  final room = Room();
  
  ref.onDispose(() {
    room.disconnect();
  });
  
  return room;
});

final isAudioMutedProvider = StateProvider<bool>((ref) => true);
final isVideoMutedProvider = StateProvider<bool>((ref) => true);
final isScreenSharingProvider = StateProvider<bool>((ref) => false);
