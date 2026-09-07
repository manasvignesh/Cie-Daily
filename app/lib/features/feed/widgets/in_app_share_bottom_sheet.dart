import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/data/chat_repository.dart';
import '../../../core/widgets/data_display/app_avatar.dart';

class InAppShareBottomSheet extends ConsumerStatefulWidget {
  final PostModel post;

  const InAppShareBottomSheet({super.key, required this.post});

  static Future<void> show(BuildContext context, PostModel post) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => InAppShareBottomSheet(post: post),
    );
  }

  @override
  ConsumerState<InAppShareBottomSheet> createState() =>
      _InAppShareBottomSheetState();
}

class _InAppShareBottomSheetState extends ConsumerState<InAppShareBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _sentConversationIds = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isReel = widget.post.category.toLowerCase() == 'reel' ||
        widget.post.videoUrl != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with In-App Only Notice
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isReel
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReel ? Icons.movie_outlined : Icons.article_outlined,
                  color: isReel ? Colors.orange : Colors.blueAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share ${isReel ? "Reel" : "Article"} In-App',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Only with your CIE Connect connections',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                if (widget.post.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image,
                            color: Colors.white54, size: 20),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isReel
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isReel ? Icons.play_arrow : Icons.article,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${widget.post.authorName}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Inter', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search connections...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1C1C28),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFFF5A1F), width: 1.5),
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
          ),

          const SizedBox(height: 16),

          // Connections List
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (currentUser == null) return const SizedBox.shrink();

                final filteredList = conversations.where((conv) {
                  final partnerId = conv.participants.firstWhere(
                    (id) => id != currentUser.uid,
                    orElse: () => '',
                  );
                  final details = conv.participantDetails[partnerId]
                      as Map<String, dynamic>?;
                  final name =
                      (details?['name'] as String? ?? 'Student').toLowerCase();
                  return partnerId.isNotEmpty && name.contains(_searchQuery);
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          conversations.isEmpty
                              ? 'No connected friends yet.\nConnect with peers in CIE Chat to share!'
                              : 'No connection matching "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final conv = filteredList[index];
                    final partnerId = conv.participants.firstWhere(
                      (id) => id != currentUser.uid,
                      orElse: () => '',
                    );
                    final details = conv.participantDetails[partnerId]
                        as Map<String, dynamic>?;
                    final partnerName =
                        details?['name'] as String? ?? 'Student';
                    final partnerAvatar = details?['photoUrl'] as String?;
                    final isSent = _sentConversationIds.contains(conv.id);

                    return GestureDetector(
                      onTap: isSent
                          ? null
                          : () async {
                              final category = isReel ? "Reel" : "Article";
                              final img = widget.post.imageUrl ?? '';
                              final vid = widget.post.videoUrl ?? '';
                              final author =
                                  widget.post.authorName.replaceAll('|', ' ');
                              final avatar = widget.post.authorAvatar ?? '';
                              final title =
                                  widget.post.title.replaceAll('|', ' ');
                              final shareMessage =
                                  '[SHARED_POST|${widget.post.id}|$category|$title|$img|$vid|$author|$avatar]';
                              try {
                                await ref
                                    .read(chatRepositoryProvider)
                                    .sendMessage(
                                      conv.id,
                                      partnerId,
                                      shareMessage,
                                    );
                                setState(() {
                                  _sentConversationIds.add(conv.id);
                                });
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Shared with $partnerName!'),
                                      backgroundColor: const Color(0xFFFF5A1F),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "We couldn't share this item. Please try again."),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSent
                                    ? const Color(0xFFFF5A1F)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: AppAvatar(
                              imageUrl: partnerAvatar,
                              fallbackText: partnerName,
                              radius: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Inter'),
                          ),
                          Text(
                            isSent ? 'Sent' : 'Send',
                            style: TextStyle(
                              color: isSent
                                  ? const Color(0xFFFF5A1F)
                                  : Colors.white54,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight:
                                  isSent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const Center(
                child: Text(
                    "We couldn't load your connections. Please try again.",
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
