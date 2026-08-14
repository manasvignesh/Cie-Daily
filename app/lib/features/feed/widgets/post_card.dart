import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../../../core/theme/responsive.dart';

/// Supports exactly two display formats:
///  - 9:16  → TRUE FULLSCREEN  (video/image fills entire screen; UI overlays on top)
///  - 4:5   → PORTRAIT CARD    (media fills top of screen at 4:5 ratio; metadata below)
/// All other aspect ratios are displayed in 4:5 mode (cropped via BoxFit.cover).
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

  // Heart animation
  bool _showHeartAnimation = false;
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  // Vinyl spin
  late AnimationController _vinylCtrl;

  // Caption expand
  bool _captionExpanded = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.upvotes;
    _isLiked = widget.post.isLikedByCurrentUser;
    _isBookmarked = widget.post.isBookmarkedByCurrentUser;

    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_heartCtrl);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartCtrl);

    _vinylCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

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
    _heartCtrl.dispose();
    _vinylCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    if (old.post.id != widget.post.id || old.post.isLikedByCurrentUser != widget.post.isLikedByCurrentUser) {
      _isLiked = widget.post.isLikedByCurrentUser;
      _likesCount = widget.post.upvotes;
    }
    if (old.post.id != widget.post.id || old.post.isBookmarkedByCurrentUser != widget.post.isBookmarkedByCurrentUser) {
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
    _heartCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showHeartAnimation = false);
    });
  }

  void _handleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    widget.onBookmark(_isBookmarked);
  }

  bool get _isFullscreen => widget.post.aspectRatio == '9:16' || widget.post.aspectRatio == null;

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 365) return '${(d.inDays / 365).floor()}y';
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildMedia({required BoxFit fit}) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return FittedBox(
        fit: fit,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    if (widget.post.imageUrl != null) {
      return Image.network(widget.post.imageUrl!, fit: fit, width: double.infinity, height: double.infinity);
    }
    final hue = (widget.post.id.hashCode % 360).abs().toDouble();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue, 0.55, 0.2).toColor(),
            HSLColor.fromAHSL(1, (hue + 50) % 360, 0.65, 0.12).toColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ROOT BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _triggerDoubleTapHeart,
      child: _isFullscreen ? _buildFullscreen(context) : _build45(context),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FORMAT 1: 9:16 FULLSCREEN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFullscreen(BuildContext context) {
    final bottomOffset = AppResponsive.overlayBottomOffset(context);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media — full screen cover
          _buildMedia(fit: BoxFit.cover),

          // Video progress bar
          if (_videoController != null && _videoController!.value.isInitialized)
            _buildVideoProgressBar(),

          // Bottom scrim gradient
          Positioned(
            bottom: 0, left: 0, right: 0, height: 420,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                ),
              ),
            ),
          ),

          // Top scrim gradient for subtle header shadow
          Positioned(
            top: 0, left: 0, right: 0, height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Right action column — positioned dynamically above navigation bar
          Positioned(
            right: 10,
            bottom: bottomOffset,
            child: _buildActionColumn(context),
          ),

          // Bottom info overlay — positioned dynamically above navigation bar
          Positioned(
            left: 16,
            right: 68,
            bottom: bottomOffset,
            child: _buildBottomInfo(context),
          ),

          // Heart burst animation
          if (_showHeartAnimation) _buildHeartBurst(),
        ],
      ),
    );
  }

  Widget _build45(BuildContext context) {
    final safeTop = AppResponsive.systemTopInset(context);
    final bottomOffset = AppResponsive.overlayBottomOffset(context);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top status bar space
              SizedBox(height: safeTop),

              // 4:5 Media Container aligned at top
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMedia(fit: BoxFit.cover),
                    if (_videoController != null && _videoController!.value.isInitialized)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: _buildVideoProgressBar(),
                      ),
                  ],
                ),
              ),

              // Author info, title, caption, and music ticker aligned at the BOTTOM above nav bar
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 68, bottomOffset),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildBottomInfo(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Right action column pinned on the right
          Positioned(
            right: 10,
            bottom: bottomOffset,
            child: _buildActionColumn(context),
          ),

          // Heart burst animation
          if (_showHeartAnimation) _buildHeartBurst(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SHARED COMPONENTS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildAuthorRow(BuildContext context, {required bool topBar}) {
    final post = widget.post;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Story-ring avatar
          _StoryRingAvatar(imageUrl: post.authorAvatar, fallback: post.authorName.isNotEmpty ? post.authorName[0] : 'A', radius: topBar ? 18 : 17),
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
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                        ),
                      ),
                    ),
                    if (topBar) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${_timeAgo(post.createdAt)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]),
                      ),
                    ],
                  ],
                ),
                if (!topBar)
                  Text(
                    _timeAgo(post.createdAt),
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Follow button
          GestureDetector(
            onTap: () => setState(() => _isFollowing = !_isFollowing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: _isFollowing ? Colors.white.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isFollowing ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.9),
                  width: 1.2,
                ),
              ),
              child: Text(
                _isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: _isFollowing ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author details row (avatar, username, and Follow button)
        _buildAuthorRow(context, topBar: false),
        const SizedBox(height: 12),
        Text(
          post.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.25,
            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 8),
        if (post.blocks.isNotEmpty) _buildCaptionSnippet(),
        const SizedBox(height: 14),
        _buildMusicTicker(),
      ],
    );
  }

  Widget _buildCaptionSnippet() {
    final blocks = widget.post.blocks;
    String text = '';
    for (final b in blocks) {
      if (b is Map<String, dynamic> && b['type'] == 'text' && b['content'] != null) {
        text = b['content'].toString();
        break;
      }
    }
    if (text.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _captionExpanded = !_captionExpanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: RichText(
          maxLines: _captionExpanded ? null : 2,
          overflow: _captionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13.5,
                  height: 1.45,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
              if (!_captionExpanded)
                TextSpan(
                  text: ' more',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMusicTicker() {
    final post = widget.post;
    final audioText = '♪  Original audio · ${post.authorName}   •   ♪  Original audio · ${post.authorName}   •   ';
    return Row(
      children: [
        // Spinning vinyl
        AnimatedBuilder(
          animation: _vinylCtrl,
          builder: (_, child) => Transform.rotate(angle: _vinylCtrl.value * 2 * math.pi, child: child),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF3A3A3A), Color(0xFF101010)],
                stops: [0.35, 1.0],
              ),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 15),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRect(
            child: _MarqueeText(
              text: audioText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionColumn(BuildContext context) {
    final post = widget.post;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(
          icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _isLiked ? const Color(0xFFFF3B5C) : Colors.white,
          label: _fmt(_likesCount),
          onTap: _handleLike,
          isActive: _isLiked,
        ),
        const SizedBox(height: 24),
        _ActionBtn(
          icon: Icons.chat_bubble_rounded,
          label: _fmt(post.commentCount),
          onTap: widget.onComment,
        ),
        const SizedBox(height: 24),
        _ActionBtn(
          icon: Icons.reply_rounded,
          label: _fmt(0),
          onTap: widget.onShare,
          mirrorIcon: true,
        ),
        const SizedBox(height: 24),
        _ActionBtn(
          icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          iconColor: _isBookmarked ? const Color(0xFFFFD700) : Colors.white,
          label: 'Save',
          onTap: _handleBookmark,
          isActive: _isBookmarked,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => _showMoreSheet(context),
          child: Column(
            children: [
              const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24, shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
              const SizedBox(height: 4),
              Text('More', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w500, shadows: const [Shadow(color: Colors.black, blurRadius: 4)])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoProgressBar() {
    return Positioned(
      top: 0, left: 0, right: 0, height: 2,
      child: ValueListenableBuilder(
        valueListenable: _videoController!,
        builder: (_, v, __) {
          final pos = v.position.inMilliseconds.toDouble();
          final dur = v.duration.inMilliseconds.toDouble();
          return LinearProgressIndicator(
            value: dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 2,
          );
        },
      ),
    );
  }

  Widget _buildHeartBurst() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _heartCtrl,
            builder: (_, __) => Opacity(
              opacity: _heartOpacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _heartScale.value.clamp(0.0, 2.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150, height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x88FF3B5C), blurRadius: 70, spreadRadius: 20)],
                      ),
                    ),
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 105),
                  ],
                ),
              ),
            ),
          ),
        ),
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
              _SheetTile(icon: Icons.flag_rounded, label: 'Report', color: Colors.redAccent),
              _SheetTile(icon: Icons.not_interested_rounded, label: 'Not Interested'),
              _SheetTile(icon: Icons.link_rounded, label: 'Copy Link'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS
// =============================================================================

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
        gradient: SweepGradient(
          colors: [Color(0xFFFBAA3B), Color(0xFFE1306C), Color(0xFF833AB4), Color(0xFF405DE6), Color(0xFFFBAA3B)],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF080808)),
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

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
    this.isActive = false,
    this.mirrorIcon = false,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.78).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: widget.mirrorIcon ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.isActive),
                  color: widget.iconColor,
                  size: 30,
                  shadows: [
                    if (widget.isActive) Shadow(color: widget.iconColor.withOpacity(0.6), blurRadius: 12),
                    const Shadow(color: Colors.black87, blurRadius: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
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
      final tp = TextPainter(text: TextSpan(text: widget.text, style: widget.style), textDirection: TextDirection.ltr)..layout();
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Transform.translate(
            offset: Offset(-_ctrl.value * tp.width, 0),
            child: Text(widget.text + widget.text, style: widget.style, maxLines: 1),
          ),
        ),
      );
    });
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _SheetTile({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: color == null ? const Icon(Icons.chevron_right_rounded, color: Color(0xFF444444)) : null,
      onTap: () => Navigator.pop(context),
    );
  }
}
