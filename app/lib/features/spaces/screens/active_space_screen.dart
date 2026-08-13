import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCVideoViewObjectFit;
import '../../../core/theme/app_theme.dart';
import '../providers/livekit_provider.dart';
import '../services/livekit_token_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveSpaceScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String? roomName;

  const ActiveSpaceScreen({super.key, required this.spaceId, this.roomName});

  @override
  ConsumerState<ActiveSpaceScreen> createState() => _ActiveSpaceScreenState();
}

class _ActiveSpaceScreenState extends ConsumerState<ActiveSpaceScreen> {
  late final Room _room;
  late final EventsListener<RoomEvent> _listener;
  bool _isConnected = false;
  String? _error;
  Participant? _pinnedParticipant;
  bool _showChat = false;
  bool _showControls = true;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _room = Room();
    _listener = _room.createListener();

    _listener.on<RoomEvent>((event) {
      if (mounted) setState(() {});
      if (event is TrackSubscribedEvent) {
        if (event.publication.source == TrackSource.screenShareVideo) {
          setState(() => _pinnedParticipant = event.participant);
        }
      }
    });

    _listener.on<RoomDisconnectedEvent>((event) {
      if (mounted) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          GoRouter.of(context).go('/spaces');
        }
      }
    });

    _connect();
  }

  Future<void> _connect() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      var roomName = widget.roomName;
      if (roomName == null) {
        final doc = await FirebaseFirestore.instance
            .collection('liveStreams')
            .doc(widget.spaceId)
            .get();
        if (doc.exists) {
          roomName = doc.data()?['roomName'] as String?;
        }
      }
      roomName ??= 'live_${widget.spaceId}';

      final token = LiveKitTokenService.generateToken(
        roomName: roomName,
        participantIdentity: user.uid,
        participantName: user.displayName ?? 'User',
      );

      await _room.connect(LiveKitTokenService.liveKitUrl, token);

      if (mounted) {
        setState(() => _isConnected = true);
        final isMuted = ref.read(isAudioMutedProvider);
        if (!isMuted) {
          _room.localParticipant?.setMicrophoneEnabled(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('liveStreams')
          .doc(widget.spaceId)
          .collection('messages')
          .add({
        'text': text,
        'authorName': user.displayName ?? 'User',
        'authorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _chatController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    _room.disconnect();
    _room.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = ref.watch(isAudioMutedProvider);

    ref.listen(isAudioMutedProvider, (previous, next) {
      if (_isConnected) {
        _room.localParticipant?.setMicrophoneEnabled(!next);
      }
    });

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? Center(
              child: Text('Error: $_error',
                  style: const TextStyle(color: Colors.red)))
          : !_isConnected
              ? const Center(child: CircularProgressIndicator())
              : isLandscape
                  ? _buildLandscapeLayout(context, isMuted)
                  : _buildPortraitLayout(context, isMuted),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // PORTRAIT LAYOUT
  // ──────────────────────────────────────────────────────────────
  Widget _buildPortraitLayout(BuildContext context, bool isMuted) {
    final participants = _getAllParticipants();

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          // Main video area
          Positioned.fill(
            child: _pinnedParticipant != null
                ? _VideoRenderer(
                    participant: _pinnedParticipant!,
                    onTap: () =>
                        setState(() => _showControls = !_showControls),
                  )
                : (participants.isNotEmpty
                    ? _VideoRenderer(
                        participant: participants.first,
                        onTap: () =>
                            setState(() => _showControls = !_showControls),
                      )
                    : const Center(
                        child: Text('Waiting for host...',
                            style: TextStyle(color: Colors.white70)))),
          ),

          // Top Header Bar
          if (_showControls)
            _buildTopBar(context, participants.length),

          // Thumbnails row at top (below top bar)
          if (participants.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 12,
              right: 12,
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  if (p == _pinnedParticipant) return const SizedBox();
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _pinnedParticipant = p),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      child: _ThumbnailWidget(participant: p),
                    ),
                  );
                },
              ),
            ),

          // Bottom overlay: chat + controls
          if (_showControls)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chat messages overlay
                  if (_showChat) _buildChatOverlay(height: 220),
                  if (_showChat) const SizedBox(height: 10),
                  // Chat input + controls bar
                  _buildBottomBar(isMuted),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int participantCount) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.redAccent, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.roomName ?? 'Live Space',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$participantCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _room.disconnect(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // LANDSCAPE LAYOUT (YouTube-style)
  // ──────────────────────────────────────────────────────────────
  Widget _buildLandscapeLayout(BuildContext context, bool isMuted) {
    final participants = _getAllParticipants();

    return Row(
      children: [
        // Main video takes up most of the width
        Expanded(
          flex: _showChat ? 7 : 1,
          child: GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              children: [
                // Main pinned/first video
                Positioned.fill(
                  child: _pinnedParticipant != null
                      ? _VideoRenderer(
                          participant: _pinnedParticipant!,
                          onTap: () => setState(
                              () => _showControls = !_showControls),
                        )
                      : (participants.isNotEmpty
                          ? _VideoRenderer(
                              participant: participants.first,
                              onTap: () => setState(
                                  () => _showControls = !_showControls),
                            )
                          : const Center(
                              child: Text('Waiting for host...',
                                  style:
                                      TextStyle(color: Colors.white70)))),
                ),

                // Thumbnails row at top-left
                if (participants.length > 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    height: 64,
                    child: Row(
                      children: participants
                          .where((p) => p != _pinnedParticipant)
                          .take(4)
                          .map((p) => GestureDetector(
                                onTap: () => setState(
                                    () => _pinnedParticipant = p),
                                child: Container(
                                  width: 80,
                                  margin:
                                      const EdgeInsets.only(right: 6),
                                  child:
                                      _ThumbnailWidget(participant: p),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                // Controls overlay at bottom
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _controlButton(
                              icon: isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              color: isMuted ? Colors.red : Colors.white,
                              onTap: () => ref
                                  .read(isAudioMutedProvider.notifier)
                                  .state = !isMuted,
                            ),
                            const SizedBox(width: 24),
                            _controlButton(
                              icon: Icons.chat_rounded,
                              color: _showChat
                                  ? Colors.blueAccent
                                  : Colors.white,
                              onTap: () =>
                                  setState(() => _showChat = !_showChat),
                            ),
                            const SizedBox(width: 24),
                            _controlButton(
                              icon: Icons.call_end_rounded,
                              color: Colors.red,
                              onTap: () => _room.disconnect(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Chat side panel (toggleable)
        if (_showChat)
          Expanded(
            flex: 3,
            child: _buildChatPanel(),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────
  List<Participant> _getAllParticipants() {
    return [
      if (_room.localParticipant != null) _room.localParticipant!,
      ..._room.remoteParticipants.values,
    ];
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Chat overlay for portrait mode (semi-transparent over video)
  Widget _buildChatOverlay({double height = 220}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
          ),
          child: _buildMessagesList(),
        ),
      ),
    );
  }

  // Full chat panel for landscape mode
  Widget _buildChatPanel() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Row(
              children: [
                const Text('Live Chat',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showChat = false),
                  child:
                      const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(child: _buildMessagesList()),
          // Input
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('liveStreams')
          .doc(widget.spaceId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          );
        }
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text('No messages yet',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${data['authorName'] ?? 'User'}: ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          fontSize: 13),
                    ),
                    TextSpan(
                      text: data['text'] ?? '',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border:
            Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              focusNode: _chatFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Say something...',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom bar for portrait mode
  Widget _buildBottomBar(bool isMuted) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
          ),
          child: Row(
            children: [
              // Chat toggle
              _controlButton(
                icon: Icons.chat_bubble_rounded,
                color: _showChat ? AppTheme.primaryOrange : Colors.white70,
                onTap: () => setState(() => _showChat = !_showChat),
              ),
              const SizedBox(width: 8),
              // Chat input (inline)
              Expanded(
                child: TextField(
                  controller: _chatController,
                  focusNode: _chatFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Say something...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  onTap: () {
                    if (!_showChat) setState(() => _showChat = true);
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              _controlButton(
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: isMuted ? Colors.redAccent : Colors.white,
                onTap: () =>
                    ref.read(isAudioMutedProvider.notifier).state = !isMuted,
              ),
              const SizedBox(width: 8),
              _controlButton(
                icon: Icons.call_end_rounded,
                color: Colors.redAccent,
                backgroundColor: Colors.redAccent.withOpacity(0.25),
                onTap: () => _room.disconnect(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// VIDEO RENDERER - Renders a participant's video full-size
// ──────────────────────────────────────────────────────────────
class _VideoRenderer extends StatefulWidget {
  final Participant participant;
  final VoidCallback? onTap;

  const _VideoRenderer({required this.participant, this.onTap});

  @override
  State<_VideoRenderer> createState() => _VideoRendererState();
}

class _VideoRendererState extends State<_VideoRenderer> {
  late final EventsListener<ParticipantEvent> _listener;

  @override
  void initState() {
    super.initState();
    _listener = widget.participant.createListener();
    _listener.on<ParticipantEvent>((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoTrack = _getVideoTrack();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Colors.black,
        child: videoTrack != null
            ? VideoTrackRenderer(
                videoTrack,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white12,
                      child: Text(
                        widget.participant.identity.isNotEmpty
                            ? widget.participant.identity[0].toUpperCase()
                            : '?',
                        style:
                            const TextStyle(fontSize: 28, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.participant.name.isNotEmpty
                          ? widget.participant.name
                          : widget.participant.identity,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  VideoTrack? _getVideoTrack() {
    // Prioritize screen share
    final screenShare = widget.participant.videoTrackPublications
        .where((pub) =>
            pub.track != null &&
            pub.source == TrackSource.screenShareVideo)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;
    if (screenShare != null) return screenShare;

    // Then camera
    final camera = widget.participant.videoTrackPublications
        .where((pub) =>
            pub.track != null && pub.source == TrackSource.camera)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;
    if (camera != null) return camera;

    // Fallback to any video
    return widget.participant.videoTrackPublications
        .where((pub) => pub.track != null)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;
  }
}

// ──────────────────────────────────────────────────────────────
// THUMBNAIL WIDGET - Small participant view for the row
// ──────────────────────────────────────────────────────────────
class _ThumbnailWidget extends StatefulWidget {
  final Participant participant;

  const _ThumbnailWidget({required this.participant});

  @override
  State<_ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<_ThumbnailWidget> {
  late final EventsListener<ParticipantEvent> _listener;

  @override
  void initState() {
    super.initState();
    _listener = widget.participant.createListener();
    _listener.on<ParticipantEvent>((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoTrack = widget.participant.videoTrackPublications
        .where((pub) => pub.track != null && pub.source == TrackSource.camera)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;

    final isSpeaking = widget.participant.isSpeaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? AppTheme.primaryOrange : Colors.white.withOpacity(0.15),
          width: isSpeaking ? 2 : 1,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: Colors.white.withOpacity(0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (videoTrack != null)
                VideoTrackRenderer(videoTrack)
              else
                Center(
                  child: Text(
                    widget.participant.identity.isNotEmpty
                        ? widget.participant.identity[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSpeaking)
                        const Icon(Icons.volume_up_rounded, size: 11, color: AppTheme.primaryOrange)
                      else if (widget.participant.isMicrophoneEnabled())
                        const Icon(Icons.mic_rounded, size: 11, color: Colors.white)
                      else
                        const Icon(Icons.mic_off_rounded, size: 11, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.participant.name.isNotEmpty
                              ? widget.participant.name
                              : widget.participant.identity,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
