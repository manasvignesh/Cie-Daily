import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/data_display/app_tag.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../providers/spaces_provider.dart';

class SpacesHomeScreen extends ConsumerWidget {
  const SpacesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStreamsAsync = ref.watch(liveStreamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Spaces'),
      ),
      body: liveStreamsAsync.when(
        data: (streams) {
          if (streams.isEmpty) {
            return const Center(
              child: Text('No active live streams right now.\nStart one from the website!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppTag(text: 'LIVE', color: Colors.redAccent),
                          Text('Started just now', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(stream.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AppAvatar(imageUrl: stream.hostAvatar, radius: 16, fallbackText: stream.hostName.isNotEmpty ? stream.hostName[0].toUpperCase() : '?'),
                          const SizedBox(width: 8),
                          Text(stream.hostName, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Join Stream',
                        onPressed: () {
                          context.push('/spaces/${stream.id}', extra: stream.roomName);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
