import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../user/data/firebase_user_repository.dart';
import '../models/post_model.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/utils/role_utils.dart';
import '../../../core/theme/responsive.dart';

/// Supports exactly two display formats:
///  - 9:16  → TRUE FULLSCREEN  (video/image fills entire screen; UI overlays on top)
///  - 4:5   → PORTRAIT CARD    (media fills top of screen at 4:5 ratio; metadata below)
/// All other aspect ratios are displayed in 4:5 mode (cropped via BoxFit.cover).
class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final bool isVisible;
  final ValueChanged<bool> onLike;
  final ValueChanged<bool> onBookmark;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    this.isVisible = true,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
    required this.onShare,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with TickerProviderStateMixin {
  bool _isLiked = false;
  bool _isBookmarked = false;
  late int _likesCount;
  VideoPlayerController? _videoController;
  bool _showPlayPauseOverlay = false;

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

    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInQuad)),
          weight: 40),
    ]).animate(_heartCtrl);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartCtrl);

    _vinylCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();

    _initVideo();
  }

  void _initVideo() {
    final url = widget.post.videoUrl;
    if (url != null && url.isNotEmpty) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )..initialize().then((_) {
          if (mounted) {
            _videoController?.setLooping(true);
            _videoController?.setVolume(1.0);
            if (widget.isVisible) {
              _videoController?.play();
            }
            setState(() {});
          }
        }).catchError((err) {
          debugPrint('Video init error for post ${widget.post.id}: $err');
          if (mounted) {
            setState(() {});
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
    if (old.post.id != widget.post.id ||
        old.post.videoUrl != widget.post.videoUrl) {
      _videoController?.dispose();
      _videoController = null;
      _initVideo();
    }
    if (old.post.id != widget.post.id ||
        old.post.isLikedByCurrentUser != widget.post.isLikedByCurrentUser) {
      _isLiked = widget.post.isLikedByCurrentUser;
      _likesCount = widget.post.upvotes;
    }
    if (old.post.id != widget.post.id ||
        old.post.isBookmarkedByCurrentUser !=
            widget.post.isBookmarkedByCurrentUser) {
      _isBookmarked = widget.post.isBookmarkedByCurrentUser;
    }
    if (old.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        if (_videoController != null && _videoController!.value.isInitialized) {
          _videoController?.play();
        }
      } else {
        _videoController?.pause();
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {
      _showPlayPauseOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showPlayPauseOverlay = false);
    });
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

  bool get _isFullscreen =>
      widget.post.aspectRatio == '9:16' || widget.post.aspectRatio == null;

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
    final url = widget.post.videoUrl;

    if (url == null || url.isEmpty) {
      if (widget.post.imageUrl != null) {
        return Image.network(widget.post.imageUrl!,
            fit: fit, width: double.infinity, height: double.infinity);
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

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child:
              CircularProgressIndicator(color: Colors.orange, strokeWidth: 2.5),
        ),
      );
    }

    final size = _videoController!.value.size;
    final videoWidth = (size.width > 0) ? size.width : 1080.0;
    final videoHeight = (size.height > 0) ? size.height : 1920.0;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _triggerDoubleTapHeart,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: fit,
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _videoController!,
            builder: (context, VideoPlayerValue value, child) {
              if (!value.isPlaying || _showPlayPauseOverlay) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ROOT BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return _isFullscreen ? _buildFullscreen(context) : _build45(context);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FORMAT 1: 9:16 FULLSCREEN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFullscreen(BuildContext context) {
    final metaBottomOffset = AppResponsive.reelMetadataBottomOffset(context);
    final actionBottomOffset = AppResponsive.reelActionsBottomOffset(context);

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
            bottom: 0,
            left: 0,
            right: 0,
            height: 420,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top scrim gradient for subtle header shadow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right action column — positioned lower alongside caption
          Positioned(
            right: 10,
            bottom: actionBottomOffset,
            child: _buildActionColumn(context),
          ),

          // Bottom info overlay — 70-80px breathing room above bottom navigation
          Positioned(
            left: 16,
            right: 68,
            bottom: metaBottomOffset,
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
                    if (_videoController != null &&
                        _videoController!.value.isInitialized)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final followingSet = ref.watch(userFollowingProvider).value ?? {};
    final isFollowing =
        post.authorId != null && followingSet.contains(post.authorId);
    final isSelf = currentUserId != null &&
        post.authorId != null &&
        currentUserId == post.authorId;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Story-ring avatar
          GestureDetector(
            onTap: () {
              if (post.authorId != null && post.authorId!.isNotEmpty) {
                context.push('/profile/${post.authorId}');
              }
            },
            child: _StoryRingAvatar(
                imageUrl: post.authorAvatar,
                fallback: post.authorName.isNotEmpty ? post.authorName[0] : 'A',
                radius: topBar ? 18 : 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (post.authorId != null && post.authorId!.isNotEmpty) {
                  context.push('/profile/${post.authorId}');
                }
              },
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
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                      if (post.isAuthorVerified ||
                          isVerifiedUser(post.authorEmail))
                        const VerifiedBadge(size: 15),
                      if (topBar) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${_timeAgo(post.createdAt)}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 4)
                              ]),
                        ),
                      ],
                    ],
                  ),
                  if (!topBar)
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: 'Inter'),
                    ),
                ],
              ),
            ),
          ),
          if (!isSelf &&
              post.authorId != null &&
              post.authorId!.isNotEmpty) ...[
            const SizedBox(width: 10),
            // Follow button
            GestureDetector(
              onTap: () {
                if (currentUserId != null && post.authorId != null) {
                  ref.read(userRepositoryProvider).toggleFollowUser(
                        currentUserId: currentUserId,
                        targetUserId: post.authorId!,
                        follow: !isFollowing,
                      );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isFollowing
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isFollowing
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: isFollowing ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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
        const SizedBox(height: 6),
        Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            height: 1.2,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 4),
        if (post.blocks.isNotEmpty) _buildCaptionSnippet(),
        const SizedBox(height: 6),
        _buildMusicTicker(),
      ],
    );
  }

  Widget _buildCaptionSnippet() {
    final blocks = widget.post.blocks;
    String text = '';
    for (final b in blocks) {
      if (b is Map<String, dynamic> &&
          b['type'] == 'text' &&
          b['content'] != null) {
        text = b['content'].toString();
        break;
      }
    }
    if (text.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _captionExpanded = !_captionExpanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: RichText(
          maxLines: _captionExpanded ? null : 1,
          overflow:
              _captionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontFamily: 'Inter',
                  height: 1.35,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
              if (!_captionExpanded)
                TextSpan(
                  text: ' more',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMusicTicker() {
    final post = widget.post;
    final audioText =
        '♪  Original audio · ${post.authorName}   •   ♪  Original audio · ${post.authorName}   •   ';
    return Row(
      children: [
        // Spinning vinyl
        AnimatedBuilder(
          animation: _vinylCtrl,
          builder: (_, child) => Transform.rotate(
              angle: _vinylCtrl.value * 2 * math.pi, child: child),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF242430), Color(0xFF13131C)],
                stops: [0.35, 1.0],
              ),
              border: Border.all(color: Colors.white12, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5), blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.music_note_rounded,
                color: Colors.white70, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRect(
            child: _MarqueeText(
              text: audioText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
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
          icon:
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _isLiked ? const Color(0xFFFF5A1F) : Colors.white,
          label: _fmt(_likesCount),
          onTap: _handleLike,
          isActive: _isLiked,
        ),
        const SizedBox(height: 18),
        _ActionBtn(
          icon: Icons.chat_bubble_rounded,
          label: _fmt(post.commentCount),
          onTap: widget.onComment,
        ),
        const SizedBox(height: 18),
        _ActionBtn(
          icon: Icons.reply_rounded,
          label: _fmt(0),
          onTap: widget.onShare,
          mirrorIcon: true,
        ),
        const SizedBox(height: 18),
        _ActionBtn(
          icon: _isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          iconColor: _isBookmarked ? const Color(0xFFFF5A1F) : Colors.white,
          label: 'Save',
          onTap: _handleBookmark,
          isActive: _isBookmarked,
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => _showMoreSheet(context),
          child: Column(
            children: [
              const Icon(Icons.more_horiz_rounded,
                  color: Colors.white,
                  size: 24,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
              const SizedBox(height: 4),
              Text('More',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 3)
                      ])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 2,
      child: ValueListenableBuilder(
        valueListenable: _videoController!,
        builder: (_, v, __) {
          final pos = v.position.inMilliseconds.toDouble();
          final dur = v.duration.inMilliseconds.toDouble();
          return LinearProgressIndicator(
            value: dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
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
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x88FF3B5C),
                              blurRadius: 70,
                              spreadRadius: 20)
                        ],
                      ),
                    ),
                    const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 105),
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
        decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const _SheetTile(
                  icon: Icons.flag_rounded,
                  label: 'Report',
                  color: Colors.redAccent),
              const _SheetTile(
                  icon: Icons.not_interested_rounded, label: 'Not Interested'),
              const _SheetTile(icon: Icons.link_rounded, label: 'Copy Link'),
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

  const _StoryRingAvatar(
      {required this.imageUrl, required this.fallback, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFFBAA3B),
            Color(0xFFE1306C),
            Color(0xFF833AB4),
            Color(0xFF405DE6),
            Color(0xFFFBAA3B)
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFF080808)),
        child: AppAvatar(
            imageUrl: imageUrl, radius: radius, fallbackText: fallback),
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

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.78)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      selected: widget.isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: widget.mirrorIcon
                      ? Matrix4.rotationY(math.pi)
                      : Matrix4.identity(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      widget.icon,
                      key: ValueKey(widget.isActive),
                      color: widget.iconColor,
                      size: 24,
                      shadows: [
                        if (widget.isActive)
                          Shadow(
                              color: widget.iconColor.withValues(alpha: 0.6),
                              blurRadius: 12),
                        const Shadow(color: Colors.black87, blurRadius: 4),
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
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
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

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr)
        ..layout();
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Transform.translate(
            offset: Offset(-_ctrl.value * tp.width, 0),
            child: Text(widget.text + widget.text,
                style: widget.style, maxLines: 1),
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
      title: Text(label,
          style:
              TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: color == null
          ? const Icon(Icons.chevron_right_rounded, color: Color(0xFF444444))
          : null,
      onTap: () => Navigator.pop(context),
    );
  }
}
