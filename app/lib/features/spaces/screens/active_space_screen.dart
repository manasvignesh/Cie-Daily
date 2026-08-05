import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../providers/livekit_provider.dart';

class ActiveSpaceScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const ActiveSpaceScreen({super.key, required this.spaceId});

  @override
  ConsumerState<ActiveSpaceScreen> createState() => _ActiveSpaceScreenState();
}

class _ActiveSpaceScreenState extends ConsumerState<ActiveSpaceScreen> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    // In a real app, fetch token from backend using widget.spaceId
    // Then connect the room:
    // final room = ref.read(liveKitRoomProvider);
    // await room.connect(url, token);
    
    // Simulating connection success for UI
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isConnected = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = ref.watch(isAudioMutedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Space'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isConnected 
          ? _buildRoom(context, isMuted) 
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRoom(BuildContext context, bool isMuted) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 5, // Mock participants
            itemBuilder: (context, index) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text('Speaker ${index + 1}', overflow: TextOverflow.ellipsis),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.back_hand_rounded),
                  tooltip: 'Raise Hand',
                ),
                FloatingActionButton(
                  backgroundColor: isMuted ? Colors.red : Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    ref.read(isAudioMutedProvider.notifier).state = !isMuted;
                  },
                  child: Icon(isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.call_end_rounded, color: Colors.red),
                  tooltip: 'Leave Space',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
