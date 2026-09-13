import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import 'device_narration_player.dart';

class RemoteNarrationUnavailable extends StatelessWidget {
  const RemoteNarrationUnavailable({
    super.key,
    required this.language,
    required this.audioStatus,
    required this.fallbackText,
    this.compact = false,
  });

  final String language;
  final String audioStatus;
  final String fallbackText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 0 : 8),
      child: DeviceNarrationPlayer(
        text: fallbackText,
        language: language,
        compact: compact,
      ),
    );
  }
}

class PremiumAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String language;
  final String audioStatus;
  final String fallbackText;
  final bool compact;

  const PremiumAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.language,
    required this.audioStatus,
    required this.fallbackText,
    this.compact = false,
  });

  @override
  State<PremiumAudioPlayer> createState() => _PremiumAudioPlayerState();
}

class _PremiumAudioPlayerState extends State<PremiumAudioPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _useDeviceFallback = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(PremiumAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _controller.dispose();
      _initPlayer();
    }
  }

  void _initPlayer() {
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    _useDeviceFallback = false;
    debugPrint('[AUDIO] language=${widget.language}');
    debugPrint('[AUDIO] status=${widget.audioStatus}');
    debugPrint('[AUDIO] source=remote');
    debugPrint('[AUDIO] urlPresent=${widget.audioUrl.isNotEmpty}');
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.audioUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _duration = _controller.value.duration;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _useDeviceFallback = true);
      });

    _controller.addListener(() {
      if (!mounted) return;
      if (_controller.value.hasError) {
        setState(() => _useDeviceFallback = true);
        return;
      }
      setState(() {
        _position = _controller.value.position;
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_useDeviceFallback) {
      return DeviceNarrationPlayer(
        text: widget.fallbackText,
        language: widget.language,
        compact: widget.compact,
        autoStart: true,
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 16,
        vertical: widget.compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMutedColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headphones_rounded,
                    color: AppTheme.primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Listen',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppTheme.primaryOrange)),
                    Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_formatDuration(_position),
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor(context))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppTheme.primaryOrange,
                    inactiveTrackColor:
                        AppTheme.primaryOrange.withValues(alpha: 0.2),
                    thumbColor: AppTheme.primaryOrange,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: (val) {
                      final newPosition = Duration(
                          milliseconds:
                              (val * _duration.inMilliseconds).round());
                      _controller.seekTo(newPosition);
                    },
                  ),
                ),
              ),
              Text(_formatDuration(_duration),
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor(context))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopupMenuButton<double>(
                tooltip: 'Playback speed',
                onSelected: (rate) {
                  _controller.setPlaybackSpeed(rate);
                  setState(() => _playbackSpeed = rate);
                },
                itemBuilder: (_) => [0.8, 1.0, 1.25, 1.5, 2.0]
                    .map((rate) =>
                        PopupMenuItem(value: rate, child: Text('$rate×')))
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  ),
                  child: Text('$_playbackSpeed×',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange)),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                onPressed: () {
                  final newPos = _position - const Duration(seconds: 10);
                  _controller
                      .seekTo(newPos.isNegative ? Duration.zero : newPos);
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.primaryOrange),
                child: IconButton(
                  icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white),
                  onPressed: () {
                    _isPlaying ? _controller.pause() : _controller.play();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                onPressed: () {
                  final newPos = _position + const Duration(seconds: 10);
                  _controller.seekTo(newPos > _duration ? _duration : newPos);
                },
              ),
              const SizedBox(width: 48), // balance flex
            ],
          ),
        ],
      ),
    );
  }
}
