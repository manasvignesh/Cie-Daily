import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class SingleReelScreen extends StatefulWidget {
  final String reelId;
  final PostModel? post;

  const SingleReelScreen({
    super.key,
    required this.reelId,
    this.post,
  });

  @override
  State<SingleReelScreen> createState() => _SingleReelScreenState();
}

class _SingleReelScreenState extends State<SingleReelScreen> {
  PostModel? _loadedPost;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _loadedPost = widget.post;
    } else {
      _fetchReel();
    }
  }

  Future<void> _fetchReel() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.reelId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _loadedPost = PostModel.fromJson({...doc.data()!, 'id': doc.id});
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = 'Reel not found or has been removed.';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "We couldn't load this reel. It may have been removed.";
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(),
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
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchReel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadedPost == null) {
      return const Center(
        child:
            Text('Reel unavailable', style: TextStyle(color: Colors.white70)),
      );
    }

    return PostCard(
      post: _loadedPost!,
      isVisible: true,
      onLike: (_) {},
      onBookmark: (_) {},
      onComment: () {},
      onShare: () {},
    );
  }
}
