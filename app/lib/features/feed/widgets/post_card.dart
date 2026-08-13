import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';
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

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  late int _likesCount;
  VideoPlayerController? _videoController;

  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartOpacityAnim;

  late AnimationController _vinylController;
  bool _captionExpanded = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.upvotes;
    _isLiked = widget.post.isLikedByCurrentUser;
    _isBookmarked = widget.post.isBookmarkedByCurrentUser;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_heartAnimController);
    _heartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimController);

    _vinylController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

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
    _vinylController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id || oldWidget.post.isLikedByCurrentUser != widget.post.isLikedByCurrentUser) {
      _isLiked = widget.post.isLikedByCurrentUser;
      _likesCount = widget.post.upvotes;
    }
    if (oldWidget.post.id != widget.post.id || oldWidget.post.isBookmarkedByCurrentUser != widget.post.isBookmarkedByCurrentUser) {
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
    if (!_isLiked) _handleLike();
    setState(() => _showHeartAnimation = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showHeartAnimation = false);
    });
  }

  void _handleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    widget.onBookmark(_isBookmarked);
  }

  double? _parseAspectRatio(String? r) {
    switch (r) {
      case '1:1': return 1.0;
      case '4:5': return 4 / 5;
      case '16:9': return 16 / 9;
      case '9:16': return 9 / 16;
      default: return null;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final ratioDouble = _parseAspectRatio(post.aspectRatio);
    final isFullScreen = ratioDouble == null || post.aspectRatio == '9:16';

    return GestureDetector(
      onDoubleTap: _triggerDoubleTapHeart,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(post, isFullScreen, ratioDouble),
            _buildGradientScrim(),
            if (_showHeartAnimation) _buildHeartBurst(),
            SafeArea(
              child: Stack(
                children: [
                  _buildTopBar(post),
                  _buildRightActions(context, post),
                  _buildBottomInfo(context, post),
                ],
              ),
            ),
            if (_videoController != null && _videoController!.value.isInitialized)
              _buildVideoProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(PostModel post, bool isFullScreen, double? ratio) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (isFullScreen) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        );
      }
      return _buildNonFullscreenWrapper(
        child: AspectRatio(aspectRatio: ratio!, child: VideoPlayer(_videoController!)),
        post: post,
      );
    }

    if (post.imageUrl != null) {
      if (isFullScreen) {
        return Image.network(post.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
      return _buildNonFullscreenWrapper(
        child: AspectRatio(aspectRatio: ratio!, child: Image.network(post.imageUrl!, fit: BoxFit.cover)),
        post: post,
      );
    }

    final hue = (post.id.hashCode % 360).abs().toDouble();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.5, 0.25).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, 0.15).toColor(),
          ],
        ),
      ),
    );
  }

  Widget _buildNonFullscreenWrapper({required Widget child, required PostModel post}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (post.imageUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Image.network(post.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          ),
        Container(color: Colors.black.withOpacity(0.58)),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80, bottom: 200, left: 12, right: 72),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 28, spreadRadius: 4)],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientScrim() {
    return Positioned(
      bottom: 0, left: 0, right: 0, height: 500,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.25, 0.6, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.65),
                Colors.black.withOpacity(0.95),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartBurst() {
    return Center(
      child: AnimatedBuilder(
        animation: _heartAnimController,
        builder: (_, __) => Opacity(
          opacity: _heartOpacityAnim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _heartScaleAnim.value.clamp(0.0, 2.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 60, spreadRadius: 20)],
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(PostModel post) {
    return Positioned(
      top: 12, left: 16, right: 16,
      child: Row(
        children: [
          _StoryRingAvatar(imageUrl: post.authorAvatar, fallback: post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A', radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.authorName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1))]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFF5A1F), borderRadius: BorderRadius.circular(8)),
                      child: Text(post.category, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    ),
                  ],
                ),
                Text(
                  _timeAgo(post.createdAt),
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, shadows: const [Shadow(color: Colors.black45, blurRadius: 4)]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isFollowing = !_isFollowing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: _isFollowing ? Colors.white.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: _isFollowing ? Border.all(color: Colors.white60, width: 1) : null,
              ),
              child: Text(
                _isFollowing ? 'Following' : 'Follow',
                style: TextStyle(color: _isFollowing ? Colors.white : Colors.black, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightActions(BuildContext context, PostModel post) {
    return Positioned(
      right: 10, bottom: 110,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionBtn(icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, iconColor: _isLiked ? const Color(0xFFFF3B5C) : Colors.white, label: _formatCount(_likesCount), onTap: _handleLike, isActive: _isLiked),
          const SizedBox(height: 22),
          _ActionBtn(icon: Icons.chat_bubble_rounded, label: _formatCount(post.commentCount), onTap: widget.onComment),
          const SizedBox(height: 22),
          _ActionBtn(icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, iconColor: _isBookmarked ? const Color(0xFFFFD700) : Colors.white, label: 'Save', onTap: _handleBookmark, isActive: _isBookmarked),
          const SizedBox(height: 22),
          _ActionBtn(icon: Icons.reply_rounded, label: 'Share', onTap: widget.onShare, mirrorIcon: true),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => _showMoreSheet(context),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.32), border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8)),
              child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context, PostModel post) {
    return Positioned(
      left: 16, right: 72, bottom: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            post.title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2, shadows: [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2))]),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (post.blocks.isNotEmpty) _buildCaption(post.blocks.first),
          const SizedBox(height: 12),
          _buildAudioTicker(post),
        ],
      ),
    );
  }

  Widget _buildCaption(dynamic block) {
    String text = '';
    if (block is Map<String, dynamic> && block['type'] == 'text' && block['content'] != null) {
      text = block['content'].toString();
    }
    if (text.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _captionExpanded = !_captionExpanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Text(
          text,
          maxLines: _captionExpanded ? null : 2,
          overflow: _captionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 13.5, height: 1.45, shadows: const [Shadow(color: Colors.black87, blurRadius: 4)]),
        ),
      ),
    );
  }

  Widget _buildAudioTicker(PostModel post) {
    final audioText = 'Original audio · ${post.authorName}   •   Original audio · ${post.authorName}   •   ';
    return Row(
      children: [
        AnimatedBuilder(
          animation: _vinylController,
          builder: (_, child) => Transform.rotate(angle: _vinylController.value * 2 * math.pi, child: child),
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFF444444), Color(0xFF111111)], stops: [0.3, 1.0]),
              border: Border.all(color: Colors.white30, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6)],
            ),
            child: const Center(child: Icon(Icons.music_note_rounded, color: Colors.white, size: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRect(
            child: _MarqueeText(
              text: audioText,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, fontWeight: FontWeight.w500, shadows: const [Shadow(color: Colors.black87, blurRadius: 3)]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoProgress() {
    return Positioned(
      top: 0, left: 0, right: 0, height: 2,
      child: ValueListenableBuilder(
        valueListenable: _videoController!,
        builder: (_, value, __) {
          final pos = value.position.inMilliseconds.toDouble();
          final dur = value.duration.inMilliseconds.toDouble();
          final pct = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
          return LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 2,
          );
        },
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              _BottomSheetTile(icon: Icons.flag_rounded, label: 'Report', color: Colors.redAccent),
              _BottomSheetTile(icon: Icons.not_interested_rounded, label: 'Not Interested'),
              _BottomSheetTile(icon: Icons.link_rounded, label: 'Copy Link'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StoryRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallback;
  final double radius;
  const _StoryRingAvatar({required this.imageUrl, required this.fallback, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFFBAA3B), Color(0xFFE1306C), Color(0xFF833AB4)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
        child: AppAvatar(imageUrl: imageUrl, radius: radius, fallbackText: fallback),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final bool isActive;
  final bool mirrorIcon;

  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.iconColor = Colors.white, this.isActive = false, this.mirrorIcon = false});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.82).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
                boxShadow: widget.isActive ? [BoxShadow(color: widget.iconColor.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)] : [],
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: widget.mirrorIcon ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(widget.icon, key: ValueKey(widget.isActive), color: widget.iconColor, size: 26),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black87, blurRadius: 4)])),
          ],
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final span = TextSpan(text: widget.text, style: widget.style);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      final textWidth = tp.width;
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final offset = -_ctrl.value * textWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: Text(widget.text + widget.text, style: widget.style, maxLines: 1),
            ),
          );
        },
      );
    });
  }
}

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _BottomSheetTile({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(label, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w500)),
      onTap: () => Navigator.pop(context),
    );
  }
}
