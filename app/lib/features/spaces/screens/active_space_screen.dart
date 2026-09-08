import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCVideoViewObjectFit;
import '../../../core/theme/app_theme.dart';
import '../providers/livekit_provider.dart';
import '../services/livekit_token_service.dart';
import '../services/live_stage_participants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';

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
  bool _isConnecting = false;
  String? _error;
  String? _spaceTitle;
  Participant? _pinnedParticipant;
  bool _showChat = false;
  bool _showControls = true;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    _listener = _room.createListener();

    _listener.on<RoomEvent>((event) {
      if (!mounted) return;
      if (event is ParticipantConnectedEvent) {
        developer.log(
          'REMOTE_PARTICIPANTS=${_room.remoteParticipants.length} identity=${event.participant.identity}',
          name: 'cie_daily.live_join',
        );
      }
      if (event is TrackSubscribedEvent) {
        final kind = event.publication.kind;
        developer.log(
          kind == TrackType.VIDEO ? 'VIDEO_SUBSCRIBED' : 'AUDIO_SUBSCRIBED',
          name: 'cie_daily.live_join',
        );
        if (mounted &&
            event.publication.source == TrackSource.screenShareVideo) {
          setState(() => _pinnedParticipant = event.participant);
        }
      }
      if (mounted &&
          event is ParticipantDisconnectedEvent &&
          _pinnedParticipant?.identity == event.participant.identity) {
        setState(() => _pinnedParticipant = null);
      }
      if (mounted && event is! RoomDisconnectedEvent) {
        setState(() {});
      }
    });

    _listener.on<RoomDisconnectedEvent>((event) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) return;
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          GoRouter.of(context).go('/spaces');
        }
      });
    });

    _connect();
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    var stage = 'refreshing Firestore record';
    try {
      if (_isConnected) {
        await _room.disconnect();
      }
      _isConnected = false;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw const AppException(
          code: AppErrorCode.unauthenticated,
          userMessage: 'Sign in again to join this space.',
        );
      }

      // Joining must use authoritative server state. A route argument or an
      // offline snapshot may describe an older room after an admin restarted it.
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('liveStreams')
            .doc(widget.spaceId)
            .get(const GetOptions(source: Source.server));
      } catch (_) {}

      if (doc == null || !doc.exists) {
        try {
          doc = await FirebaseFirestore.instance
              .collection('liveStreams')
              .doc(widget.spaceId)
              .get();
        } catch (_) {}
      }

      if (doc == null || !doc.exists) {
        try {
          doc = await FirebaseFirestore.instance
              .collection('live_spaces')
              .doc(widget.spaceId)
              .get();
        } catch (_) {}
      }

      if (doc == null || !doc.exists) {
        throw const AppException(
          code: AppErrorCode.notFound,
          userMessage: 'This live space is no longer available.',
        );
      }
      final data = doc.data() ?? const <String, dynamic>{};
      final status = (data['status'] as String?)?.trim().toLowerCase();
      final endedAt = data['endedAt'];
      final hostId = _firstNonEmptyString(data, const [
        'hostId',
        'presenterId',
        'createdBy',
        'authorId',
        'userId',
      ]);
      final roomName = _firstNonEmptyString(data, const [
        'roomName',
        'roomId',
        'room_id',
        'room',
        'live_room',
        'room_name',
      ]);

      developer.log(
        'LIVE_JOIN_SELECTED streamDocumentId=${widget.spaceId} status=$status title=${data['title']} hostId=$hostId roomName=$roomName',
        name: 'cie_daily.live_join',
      );

      _logJoin('fresh_record', {
        'spaceId': widget.spaceId,
        'status': status,
        'roomName': roomName,
        'liveKitUrl': LiveKitTokenService.liveKitUrl,
        'hostId': hostId,
        'startedAt': _logTimestamp(data['startedAt']),
        'endedAt': _logTimestamp(endedAt),
      });

      if (status == 'ended' || status == 'cancelled' || endedAt != null) {
        throw const AppException(
          code: AppErrorCode.notFound,
          userMessage: 'This live space is no longer available.',
        );
      }
      if (status != 'live') {
        throw const AppException(
          code: AppErrorCode.serviceUnavailable,
          userMessage: 'This live space has not started yet.',
          retryable: true,
        );
      }
      if (roomName == null ||
          roomName.isEmpty ||
          hostId == null ||
          hostId.isEmpty) {
        throw const AppException(
          code: AppErrorCode.validation,
          userMessage: 'Invalid live room configuration.',
        );
      }

      if (mounted) {
        setState(() {
          _spaceTitle = (data['title'] as String?)?.trim() ?? roomName;
        });
      }

      stage = 'requesting live access token';
      late final String token;
      try {
        token = await LiveKitTokenService.fetchToken(
          spaceId: widget.spaceId,
          roomName: roomName,
        );
        _logJoin('token_success', {
          'spaceId': widget.spaceId,
          'roomName': roomName,
          'participantId': user.uid,
          'tokenLength': token.length,
        });
      } catch (error) {
        _logJoin('token_error', {
          'spaceId': widget.spaceId,
          'roomName': roomName,
          'participantId': user.uid,
          'errorType': error.runtimeType.toString(),
          'errorCode': error is AppException ? error.code.name : 'unknown',
        });
        if (error is AppException) rethrow;
        throw AppException(
          code: AppErrorCode.serviceUnavailable,
          userMessage: 'Unable to get live access token. Please try again.',
          cause: error,
          retryable: true,
        );
      }

      stage = 'connecting to LiveKit room';
      try {
        await _room.connect(
          LiveKitTokenService.liveKitUrl,
          token,
        );
        _logJoin('connect_success', {
          'spaceId': widget.spaceId,
          'roomName': roomName,
          'liveKitUrl': LiveKitTokenService.liveKitUrl,
        });
      } catch (error) {
        _logJoin('connect_error', {
          'spaceId': widget.spaceId,
          'roomName': roomName,
          'liveKitUrl': LiveKitTokenService.liveKitUrl,
          'errorType': error.runtimeType.toString(),
        });
        throw AppException(
          code: AppErrorCode.network,
          userMessage: 'Unable to connect to live room. Please try again.',
          cause: error,
          retryable: true,
        );
      }

      if (mounted) {
        setState(() => _isConnected = true);
        developer.log(
          'REMOTE_PARTICIPANTS=${_room.remoteParticipants.length}',
          name: 'cie_daily.live_join',
        );
      }
    } catch (error, stackTrace) {
      _logJoin('join_error', {
        'spaceId': widget.spaceId,
        'stage': stage,
        'errorType': error.runtimeType.toString(),
        'errorCode': error is AppException ? error.code.name : 'unknown',
      });
      final appError = ErrorMapper.normalize(
        error,
        stackTrace: stackTrace,
        fallbackMessage:
            "We couldn't join this space right now. Please try again.",
      );
      if (mounted) {
        setState(() => _error = appError.userMessage);
      }
    } finally {
      _isConnecting = false;
    }
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _logTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    return value.toString();
  }

  static void _logJoin(String event, Map<String, Object?> details) {
    developer.log(
      '$event ${details.entries.map((entry) => '${entry.key}=${entry.value}').join(' ')}',
      name: 'cie_daily.live_spaces',
    );
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
          const SnackBar(
              content:
                  Text("We couldn't send that message. Please try again.")),
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
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_off_rounded,
                      color: Colors.white70, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _error = null);
                      _connect();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ))
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
                    key: ValueKey('pinned_${_pinnedParticipant!.identity}'),
                    participant: _pinnedParticipant!,
                    onTap: () => setState(() => _showControls = !_showControls),
                  )
                : (participants.isNotEmpty
                    ? _VideoRenderer(
                        key: ValueKey('main_${participants.first.identity}'),
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
            _buildTopBar(context, _room.remoteParticipants.length + 1),

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
                    key: ValueKey('thumb_${p.identity}'),
                    onTap: () => setState(() => _pinnedParticipant = p),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      child: _ThumbnailWidget(
                        key: ValueKey('thumb_widget_${p.identity}'),
                        participant: p,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom overlay: chat + controls
          if (_showControls)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 12,
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
              color: const Color(0xFF13131C).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        width: 0.5),
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
                    _spaceTitle ?? widget.roomName ?? 'Live Space',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded,
                          color: Colors.white70, size: 14),
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
                      color: Colors.redAccent.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
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
                          key: ValueKey(
                              'land_pinned_${_pinnedParticipant!.identity}'),
                          participant: _pinnedParticipant!,
                          onTap: () =>
                              setState(() => _showControls = !_showControls),
                        )
                      : (participants.isNotEmpty
                          ? _VideoRenderer(
                              key: ValueKey(
                                  'land_main_${participants.first.identity}'),
                              participant: participants.first,
                              onTap: () => setState(
                                  () => _showControls = !_showControls),
                            )
                          : const Center(
                              child: Text('Waiting for host...',
                                  style: TextStyle(color: Colors.white70)))),
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
                                key: ValueKey('land_thumb_${p.identity}'),
                                onTap: () =>
                                    setState(() => _pinnedParticipant = p),
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 6),
                                  child: _ThumbnailWidget(
                                    key: ValueKey(
                                        'land_thumb_widget_${p.identity}'),
                                    participant: p,
                                  ),
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
                              color:
                                  _showChat ? Colors.blueAccent : Colors.white,
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
    return liveStageParticipants<Participant>(
      remote: _room.remoteParticipants.values,
      local: _room.localParticipant,
      hasVideo: (p) => p.videoTrackPublications.any((t) => !t.muted),
      hasScreenShare: (p) => p.videoTrackPublications
          .any((t) => !t.muted && t.source == TrackSource.screenShareVideo),
      identity: (p) => p.identity,
    );
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Icon(icon, color: color, size: 22),
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
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12), width: 0.5),
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
              border:
                  Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
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
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("We couldn't load space messages.",
                style: TextStyle(color: Colors.red, fontSize: 12)),
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
                      text: '${data['authorName'] ?? 'User'}  ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                          fontSize: 13),
                    ),
                    TextSpan(
                      text: data['text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
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
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF13131C),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryOrange, width: 1),
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
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom bar for portrait mode
  Widget _buildBottomBar(bool isMuted) {
    final isCompact = MediaQuery.sizeOf(context).width < 430;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Row(
            children: [
              if (!isCompact) ...[
                _controlButton(
                  icon: Icons.chat_bubble_rounded,
                  color: _showChat ? AppTheme.primaryOrange : Colors.white70,
                  onTap: () => setState(() => _showChat = !_showChat),
                ),
                const SizedBox(width: 8),
              ],
              // Chat input (inline)
              Expanded(
                child: TextField(
                  controller: _chatController,
                  focusNode: _chatFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Say something...',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF13131C).withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryOrange, width: 1),
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
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 16),
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
                backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
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

  const _VideoRenderer({
    super.key,
    required this.participant,
    this.onTap,
  });

  @override
  State<_VideoRenderer> createState() => _VideoRendererState();
}

class _VideoRendererState extends State<_VideoRenderer> {
  EventsListener<ParticipantEvent>? _listener;

  @override
  void initState() {
    super.initState();
    _listenToParticipant();
  }

  void _listenToParticipant() {
    _listener?.dispose();
    _listener = widget.participant.createListener();
    _listener?.on<ParticipantEvent>((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _VideoRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      _listenToParticipant();
    }
  }

  @override
  void dispose() {
    _listener?.dispose();
    _listener = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoTrack = _getVideoTrack();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: videoTrack != null
              ? VideoTrackRenderer(
                  videoTrack,
                  key: ValueKey(videoTrack.sid ?? videoTrack.hashCode),
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
                          style: const TextStyle(
                              fontSize: 28, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.participant.name.isNotEmpty
                            ? widget.participant.name
                            : widget.participant.identity,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  VideoTrack? _getVideoTrack() {
    // Prioritize screen share
    final screenShare = widget.participant.videoTrackPublications
        .where((pub) =>
            pub.track != null && pub.source == TrackSource.screenShareVideo)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;
    if (screenShare != null) return screenShare;

    // Then camera
    final camera = widget.participant.videoTrackPublications
        .where((pub) => pub.track != null && pub.source == TrackSource.camera)
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

  const _ThumbnailWidget({
    super.key,
    required this.participant,
  });

  @override
  State<_ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<_ThumbnailWidget> {
  EventsListener<ParticipantEvent>? _listener;

  @override
  void initState() {
    super.initState();
    _listenToParticipant();
  }

  void _listenToParticipant() {
    _listener?.dispose();
    _listener = widget.participant.createListener();
    _listener?.on<ParticipantEvent>((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _ThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      _listenToParticipant();
    }
  }

  @override
  void dispose() {
    _listener?.dispose();
    _listener = null;
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
          color: isSpeaking
              ? AppTheme.primaryOrange
              : Colors.white.withValues(alpha: 0.15),
          width: isSpeaking ? 2 : 1,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: Colors.white.withValues(alpha: 0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (videoTrack != null)
                VideoTrackRenderer(
                  videoTrack,
                  key: ValueKey(videoTrack.sid ?? videoTrack.hashCode),
                )
              else
                Center(
                  child: Text(
                    widget.participant.identity.isNotEmpty
                        ? widget.participant.identity[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSpeaking)
                        const Icon(Icons.volume_up_rounded,
                            size: 11, color: AppTheme.primaryOrange)
                      else if (widget.participant.isMicrophoneEnabled())
                        const Icon(Icons.mic_rounded,
                            size: 11, color: Colors.white)
                      else
                        const Icon(Icons.mic_off_rounded,
                            size: 11, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.participant.name.isNotEmpty
                              ? widget.participant.name
                              : widget.participant.identity,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
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
