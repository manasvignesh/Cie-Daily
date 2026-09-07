import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../feed/models/post_model.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../utils/shared_content_formatter.dart';

class SharedPostData {
  final String postId;
  final String category; // 'Reel' or 'Article'
  final String title;
  final String? imageUrl;
  final String? videoUrl;
  final String authorName;
  final String? authorAvatar;

  SharedPostData({
    required this.postId,
    required this.category,
    required this.title,
    this.imageUrl,
    this.videoUrl,
    required this.authorName,
    this.authorAvatar,
  });

  static SharedPostData? tryParse(String content) {
    if (content.startsWith('[SHARED_POST|')) {
      final parts = content.split('|');
      if (parts.length >= 7) {
        return SharedPostData(
          postId: parts[1],
          category: parts[2],
          title: parts[3],
          imageUrl: parts[4].isNotEmpty ? parts[4] : null,
          videoUrl: parts[5].isNotEmpty ? parts[5] : null,
          authorName: parts[6],
          authorAvatar:
              parts.length > 7 && parts[7].isNotEmpty ? parts[7] : null,
        );
      }
    }

    if (content.startsWith('[SHARED_POST]')) {
      final payload = content.substring('[SHARED_POST]'.length).trim();
      final isReel = payload.toLowerCase().contains('reel');
      return SharedPostData(
        postId: payload,
        category: isReel ? 'Reel' : 'Article',
        title: sharedContentPreview(content),
        authorName: 'Creator',
      );
    }

    // Fallback: parse legacy text format
    // 📌 Shared Reel: "test-6"\n[Post ID: 8zMz7KPRH6CEcDQnn21y]
    if (content.contains('[Post ID:')) {
      final idMatch =
          RegExp(r'\[Post ID:\s*([a-zA-Z0-9_]+)\]').firstMatch(content);
      if (idMatch != null) {
        final id = idMatch.group(1)!;
        final isReel = content.contains('Reel');
        final titleMatch =
            RegExp(r'Shared (?:Reel|Article):\s*"([^"]+)"').firstMatch(content);
        final title = titleMatch?.group(1) ?? 'Shared Drop';
        return SharedPostData(
          postId: id,
          category: isReel ? 'Reel' : 'Article',
          title: title,
          authorName: 'Creator',
        );
      }
    }

    return null;
  }
}

class SharedPostChatCard extends StatefulWidget {
  final SharedPostData data;
  final bool isMe;

  const SharedPostChatCard({
    super.key,
    required this.data,
    required this.isMe,
  });

  @override
  State<SharedPostChatCard> createState() => _SharedPostChatCardState();
}

class _SharedPostChatCardState extends State<SharedPostChatCard> {
  PostModel? _fetchedPost;

  @override
  void initState() {
    super.initState();
    _fetchFullPostIfNeeded();
  }

  Future<void> _fetchFullPostIfNeeded() async {
    if (widget.data.imageUrl != null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.data.postId)
          .get();
      if (doc.exists && mounted) {
        final map = doc.data()!;
        setState(() {
          _fetchedPost = PostModel.fromJson({...map, 'id': doc.id});
        });
      }
    } catch (_) {}
  }

  void _openSharedContent(BuildContext context) async {
    final isReel = widget.data.category.toLowerCase() == 'reel' ||
        widget.data.videoUrl != null;

    if (_fetchedPost != null) {
      if (isReel) {
        context.push('/reel/${_fetchedPost!.id}', extra: _fetchedPost);
      } else {
        context.push('/discover/article', extra: _fetchedPost);
      }
      return;
    }

    // Fetch and open
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.data.postId)
          .get();
      if (doc.exists && context.mounted) {
        final post = PostModel.fromJson({...doc.data()!, 'id': doc.id});
        if (isReel ||
            post.category.toLowerCase() == 'reel' ||
            post.videoUrl != null) {
          context.push('/reel/${post.id}', extra: post);
        } else {
          context.push('/discover/article', extra: post);
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post unavailable or removed.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'This post could not be opened. It may have been removed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReel = widget.data.category.toLowerCase() == 'reel' ||
        widget.data.videoUrl != null;
    final imageUrl = _fetchedPost?.imageUrl ?? widget.data.imageUrl;
    final authorName = _fetchedPost?.authorName ?? widget.data.authorName;
    final authorAvatar = _fetchedPost?.authorAvatar ?? widget.data.authorAvatar;
    final title = _fetchedPost?.title ?? widget.data.title;

    return GestureDetector(
      onTap: () => _openSharedContent(context),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: widget.isMe
              ? AppTheme.primaryOrange.withValues(alpha: 0.1)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 20),
          ),
          border: Border.all(
            color: widget.isMe
                ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                : AppTheme.cardBorderColor(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar with Author Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: authorAvatar,
                    fallbackText: authorName,
                    radius: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.primaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isReel
                          ? Colors.orange.withValues(alpha: 0.25)
                          : Colors.blue.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReel
                              ? Icons.play_arrow_rounded
                              : Icons.article_rounded,
                          color: isReel ? Colors.orange : Colors.blueAccent,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isReel ? 'Reel' : 'Article',
                          style: TextStyle(
                            color: isReel ? Colors.orange : Colors.blueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Thumbnail / Poster Container with Play Icon
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(isReel),
                    )
                  else
                    _buildPlaceholder(isReel),

                  // Overlay Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),

                  // Big Glowing Play Button for Reels
                  if (isReel)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                  // Title text overlay on media
                  Positioned(
                    bottom: 8,
                    left: 10,
                    right: 10,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: AppTheme.surfaceMutedColor(context),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: AppTheme.secondaryTextColor(context), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view in Breakpoint',
                    style: TextStyle(
                        color: AppTheme.secondaryTextColor(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.tertiaryTextColor(context), size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isReel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReel
              ? [
                  const Color(0xFF833AB4),
                  const Color(0xFFFD1D1D),
                  const Color(0xFFF56040)
                ]
              : [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isReel ? Icons.movie_outlined : Icons.article_outlined,
          color: Colors.white54,
          size: 40,
        ),
      ),
    );
  }
}
