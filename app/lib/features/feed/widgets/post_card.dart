import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/data_display/app_tag.dart';
import '../../../core/widgets/data_display/app_avatar.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final ValueChanged<bool> onLike;
  final ValueChanged<bool> onBookmark;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
    required this.onShare,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  bool _isBookmarked = false;
  late int _likesCount;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.upvotes;
    _isLiked = widget.post.isLikedByCurrentUser;
    _isBookmarked = widget.post.isBookmarkedByCurrentUser;

    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
        ..initialize().then((_) {
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id || 
        oldWidget.post.isLikedByCurrentUser != widget.post.isLikedByCurrentUser) {
      _isLiked = widget.post.isLikedByCurrentUser;
      _likesCount = widget.post.upvotes;
    }
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.isBookmarkedByCurrentUser != widget.post.isBookmarkedByCurrentUser) {
      _isBookmarked = widget.post.isBookmarkedByCurrentUser;
    }
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    widget.onLike(_isLiked);
  }

  void _handleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    widget.onBookmark(_isBookmarked);
  }

  double? _parseAspectRatio(String? ratioStr) {
    if (ratioStr == null) return null;
    switch (ratioStr) {
      case '1:1':
        return 1.0;
      case '4:5':
        return 4 / 5;
      case '16:9':
        return 16 / 9;
      case '9:16':
        return 9 / 16;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorVal = post.id.hashCode;
    final color1 = Color((colorVal & 0xFFFFFF) | 0xFF000000).withOpacity(0.8);
    final color2 = Color(((colorVal >> 8) & 0xFFFFFF) | 0xFF000000).withOpacity(0.9);

    final ratioDouble = _parseAspectRatio(post.aspectRatio);
    final isFullScreen = ratioDouble == null || post.aspectRatio == '9:16';

    return GestureDetector(
      onDoubleTap: () {
        if (!_isLiked) {
          _handleLike();
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          image: isFullScreen && _videoController == null && post.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(post.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
        ),
        child: Stack(
          children: [
            // Media Layer
            if (_videoController != null && _videoController!.value.isInitialized)
              isFullScreen
                  ? Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: ratioDouble,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    ),
            if (!isFullScreen && _videoController == null && post.imageUrl != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: ratioDouble!,
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            Container(color: Colors.black.withOpacity(0.25)), // Darken overlay for text
            SafeArea(
              child: Stack(
                children: [
                  // Top Tags
                  Positioned(
              top: 24,
              left: 20,
              child: Row(
                children: [
                  if (post.isTodaysDrop)
                    const AppTag(
                      text: "TODAY'S DROP",
                      color: Color(0xFFFF5A1F),
                      textColor: Colors.white,
                    )
                  else
                    AppTag(
                      text: post.category,
                      color: Colors.white.withOpacity(0.2),
                      textColor: Colors.white,
                    ),
                ],
              ),
            ),
            
            // Right Interaction Bar
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildInteractionButton(
                    context,
                    icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: _isLiked ? Colors.redAccent : Colors.white,
                    label: _likesCount.toString(),
                    onTap: _handleLike,
                  ),
                  const SizedBox(height: 16),
                  _buildInteractionButton(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: post.commentCount.toString(),
                    onTap: widget.onComment,
                  ),
                  const SizedBox(height: 16),
                  _buildInteractionButton(
                    context,
                    icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    iconColor: _isBookmarked ? Theme.of(context).primaryColor : Colors.white,
                    label: 'Save',
                    onTap: _handleBookmark,
                  ),
                  const SizedBox(height: 16),
                  _buildInteractionButton(
                    context,
                    icon: Icons.ios_share_rounded,
                    label: 'Share',
                    onTap: () {
                      widget.onShare();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing this post...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              left: 20,
              right: 80, // Leave space for interaction bar
              bottom: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${post.estimatedReadTime} min read',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (post.blocks.isNotEmpty)
                    _buildTextSnippet(context, post.blocks.first),
                ],
              ),
            ),
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color iconColor = Colors.white}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextSnippet(BuildContext context, dynamic block) {
    if (block is Map<String, dynamic>) {
      final type = block['type'];
      final content = block['content'];
      
      if (type == 'text' && content != null) {
        return Text(
          content.toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            height: 1.4,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
