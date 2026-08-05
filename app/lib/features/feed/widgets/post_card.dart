import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/data_display/app_tag.dart';
import '../../../core/widgets/data_display/app_avatar.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (post.isTodaysDrop)
                    const AppTag(
                      text: "TODAY'S DROP",
                      color: Color(0xFFFF5A1F),
                      textColor: Colors.white,
                    )
                  else
                    AppTag(text: post.category),
                  const Spacer(),
                  Text(
                    '${post.estimatedReadTime} min read',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                post.title,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              
              // Content (Blocks)
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: post.blocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final block = post.blocks[index];
                    return _buildBlock(context, block);
                  },
                ),
              ),
              
              // Interaction Bar
              const SizedBox(height: 16),
              Row(
                children: [
                  AppAvatar(
                    imageUrl: post.authorAvatar,
                    fallbackText: post.authorName,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    post.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  AppIconButton(
                    icon: Icons.favorite_border_rounded,
                    onPressed: onLike,
                    backgroundColor: Colors.transparent,
                  ),
                  AppIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: onComment,
                    backgroundColor: Colors.transparent,
                  ),
                  AppIconButton(
                    icon: Icons.ios_share_rounded,
                    onPressed: onShare,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, dynamic block) {
    // Simplified block renderer for Milestone 4
    if (block is Map<String, dynamic>) {
      final type = block['type'];
      final content = block['content'];
      
      if (type == 'text' && content != null) {
        return Text(
          content.toString(),
          style: Theme.of(context).textTheme.bodyLarge,
        );
      } else if (type == 'heading' && content != null) {
        return Text(
          content.toString(),
          style: Theme.of(context).textTheme.titleLarge,
        );
      }
    }
    return const SizedBox.shrink();
  }
}
