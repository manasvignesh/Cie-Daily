import 'dart:ui';
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

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isBookmarked = false;
  late int _likesCount;
  VideoPlayerController? _videoController;

  // Animation controllers for double-tap heart
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.upvotes;
    _isLiked = widget.post.isLikedByCurrentUser;
    _isBookmarked = widget.post.isBookmarkedByCurrentUser;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_heartAnimController);

    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.setLooping(true);
            _videoController?.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
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

  void _triggerDoubleTapHeart() {
    if (!_isLiked) {
      _handleLike();
    }
    setState(() {
      _showHeartAnimation = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showHeartAnimation = false;
          });
        }
      });
    });
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
      onDoubleTap: _triggerDoubleTapHeart,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          image: isFullScreen && _videoController == null && post.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(post.imageUrl!),
                  fit: BoxFit.cover,
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
            // Ambient Blurred Background for non-fullscreen posts
            if (!isFullScreen && post.imageUrl != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(post.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ),
              ),

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
                  : Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 70, bottom: 220, left: 16, right: 76),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: AspectRatio(
                                aspectRatio: ratioDouble!,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            if (!isFullScreen && _videoController == null && post.imageUrl != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 70, bottom: 220, left: 16, right: 76),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
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
                ),
              ),
            
            // Modern Smooth Gradient Overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 380,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Double Tap Massive Heart Animation
            if (_showHeartAnimation)
              Center(
                child: ScaleTransition(
                  scale: _heartScaleAnim,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 120,
                  ),
                ),
              ),

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
                          _buildGlassTag(
                            text: "TODAY'S DROP",
                            color: const Color(0xFFFF5A1F).withOpacity(0.8),
                          )
                        else
                          _buildGlassTag(
                            text: post.category,
                            color: Colors.white.withOpacity(0.2),
                          ),
                      ],
                    ),
                  ),
                  
                  // Right Interaction Bar
                  Positioned(
                    right: 14,
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
                          isAnimatedIcon: true,
                          isActive: _isLiked,
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
                          isAnimatedIcon: true,
                          isActive: _isBookmarked,
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
                            AppAvatar(
                              imageUrl: post.authorAvatar,
                              radius: 14,
                              fallbackText: post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A',
                            ),
                            const SizedBox(width: 8),
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildGlassTag(
                              text: '${post.estimatedReadTime} min read',
                              color: Colors.white.withOpacity(0.15),
                              fontSize: 10,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          post.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
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

  Widget _buildGlassTag({required String text, required Color color, double fontSize = 12, EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onTap, 
    Color iconColor = Colors.white,
    bool isAnimatedIcon = false,
    bool isActive = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                ),
                child: isAnimatedIcon
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(icon, key: ValueKey(isActive), color: iconColor, size: 28),
                      )
                    : Icon(icon, color: iconColor, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black87,
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
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.4,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))],
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

