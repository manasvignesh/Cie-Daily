import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/overlays/app_bottom_sheet.dart';
import '../providers/comments_provider.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    AppBottomSheet.show(
      context: context,
      child: CommentsBottomSheet(postId: postId),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _commentController = TextEditingController();

  void _submitComment() async {
    final text = _commentController.text;
    if (text.trim().isEmpty) return;
    
    _commentController.clear();
    await ref.read(addCommentProvider).addComment(widget.postId, text);
    
    // Unfocus keyboard
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final availableHeight = screenHeight - keyboardHeight - 100; // Leave some space at top
    final targetHeight = screenHeight * 0.6;
    final actualHeight = targetHeight > availableHeight ? availableHeight : targetHeight;

    return SizedBox(
      height: actualHeight > 200 ? actualHeight : 200, // Ensure a minimum height
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Comments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Be the first to comment!'),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.authorAvatar != null
                            ? NetworkImage(comment.authorAvatar!)
                            : null,
                        child: comment.authorAvatar == null
                            ? Text(comment.authorName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(comment.authorName),
                      subtitle: Text(comment.content),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _submitComment,
                ),
              ),
              onSubmitted: (_) => _submitComment(),
            ),
          ),
        ],
      ),
    );
  }
}
