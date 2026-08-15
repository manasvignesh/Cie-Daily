import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../feed/models/post_model.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../../../core/widgets/verified_badge.dart';

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
          authorAvatar: parts.length > 7 && parts[7].isNotEmpty ? parts[7] : null,
        );
      }
    }

    // Fallback: parse legacy text format
    // 📌 Shared Reel: "test-6"\n[Post ID: 8zMz7KPRH6CEcDQnn21y]
    if (content.contains('[Post ID:')) {
      final idMatch = RegExp(r'\[Post ID:\s*([a-zA-Z0-9_]+)\]').firstMatch(content);
      if (idMatch != null) {
        final id = idMatch.group(1)!;
        final isReel = content.contains('Reel');
        final titleMatch = RegExp(r'Shared (?:Reel|Article):\s*"([^"]+)"').firstMatch(content);
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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchFullPostIfNeeded();
  }

  Future<void> _fetchFullPostIfNeeded() async {
    if (widget.data.imageUrl != null) return;
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.data.postId).get();
      if (doc.exists && mounted) {
        final map = doc.data()!;
        setState(() {
          _fetchedPost = PostModel.fromJson({...map, 'id': doc.id});
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSharedContent(BuildContext context) async {
    final isReel = widget.data.category.toLowerCase() == 'reel' || widget.data.videoUrl != null;

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
      final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.data.postId).get();
      if (doc.exists && context.mounted) {
        final post = PostModel.fromJson({...doc.data()!, 'id': doc.id});
        if (isReel || post.category.toLowerCase() == 'reel' || post.videoUrl != null) {
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
          SnackBar(content: Text('Could not open post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReel = widget.data.category.toLowerCase() == 'reel' || widget.data.videoUrl != null;
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
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isReel ? Colors.orange.withOpacity(0.25) : Colors.blue.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReel ? Icons.play_arrow_rounded : Icons.article_rounded,
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
                          Colors.black.withOpacity(0.7),
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
                          color: Colors.black.withOpacity(0.55),
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
              color: Colors.white.withOpacity(0.04),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white54, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Tap to view in CIE Connect',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 10),
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
              ? [const Color(0xFF833AB4), const Color(0xFFFD1D1D), const Color(0xFFF56040)]
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
