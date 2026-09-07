import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/overlays/app_bottom_sheet.dart';
import '../providers/comments_provider.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      child: CommentsBottomSheet(postId: postId),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
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
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final surface = AppTheme.cardColor(context);
    final inputFill = AppTheme.inputFillColor(context);
    final border = AppTheme.cardBorderColor(context);

    // AppBottomSheet owns the rounded surface, handle, keyboard and safe-area
    // padding. This child only owns the comments content, preventing the
    // double-sheet band that previously appeared above the header.
    final availableHeight = screenHeight - keyboardHeight - 120;
    final targetHeight = screenHeight * 0.68;
    final actualHeight =
        targetHeight > availableHeight ? availableHeight : targetHeight;

    return SizedBox(
      height: actualHeight.clamp(260.0, screenHeight * 0.78),
      child: Column(
        children: [
          Text(
            'Comments',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 15),
          Divider(color: border, height: 1),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'Be the first to comment!',
                      style: TextStyle(color: secondaryText),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: comments.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (_, __) =>
                      Divider(color: border, height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: inputFill,
                            backgroundImage: comment.authorAvatar != null
                                ? NetworkImage(comment.authorAvatar!)
                                : null,
                            child: comment.authorAvatar == null
                                ? Text(
                                    comment.authorName.isEmpty
                                        ? '?'
                                        : comment.authorName[0].toUpperCase(),
                                    style: TextStyle(
                                        color: primaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.authorName,
                                  style: TextStyle(
                                      color: primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'Inter'),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  "We couldn't load comments. Please try again.",
                  style: TextStyle(color: secondaryText),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: border)),
            ),
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: primaryText, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(
                  color: secondaryText.withValues(alpha: 0.72),
                ),
                filled: true,
                fillColor: inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF5A1F), width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Color(0xFFFF5A1F), size: 20),
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
