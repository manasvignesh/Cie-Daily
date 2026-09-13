import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/theme/app_theme.dart';

class DeviceNarrationPlayer extends StatefulWidget {
  const DeviceNarrationPlayer({
    super.key,
    required this.text,
    required this.language,
    this.compact = false,
    this.autoStart = false,
  });

  final String text;
  final String language;
  final bool compact;
  final bool autoStart;

  @override
  State<DeviceNarrationPlayer> createState() => _DeviceNarrationPlayerState();
}

class _DeviceNarrationPlayerState extends State<DeviceNarrationPlayer> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _unavailable = false;

  static const _localeByLanguage = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'te': 'te-IN',
  };

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _speaking = false);
      }
    });
    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() {
          _speaking = false;
          _unavailable = true;
        });
      }
    });
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toggle());
    }
  }

  @override
  void didUpdateWidget(DeviceNarrationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.language != widget.language) {
      _tts.stop();
      setState(() {
        _speaking = false;
        _unavailable = false;
      });
    }
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) {
        setState(() => _speaking = false);
      }
      return;
    }
    try {
      final locale = _localeByLanguage[widget.language] ?? 'en-IN';
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true || widget.text.trim().isEmpty) {
        if (mounted) {
          setState(() => _unavailable = true);
        }
        return;
      }
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.48);
      await _tts.awaitSpeakCompletion(false);
      debugPrint('[AUDIO] language=${widget.language}');
      debugPrint('[AUDIO] source=local_tts');
      final result = await _tts.speak(widget.text.trim());
      if (mounted) {
        setState(() {
          _speaking = result == 1;
          _unavailable = result != 1;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _speaking = false;
          _unavailable = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unavailable) {
      return Text("Narration isn't available right now.",
          style: TextStyle(
              color: AppTheme.secondaryTextColor(context), fontSize: 12));
    }
    return Row(
      mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        IconButton(
          tooltip: _speaking ? 'Stop narration' : 'Listen',
          onPressed: _toggle,
          icon: Icon(
              _speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
              color: AppTheme.primaryOrange),
        ),
        Text(_speaking ? 'Stop' : 'Listen',
            style: TextStyle(
                fontSize: widget.compact ? 11 : 12,
                color: AppTheme.secondaryTextColor(context))),
      ],
    );
  }
}
