import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_preferences.dart';
import 'splash_scene.dart';

enum SplashCue { point, stretch, fracture, lock, opening }

/// Optional local, silent-mode-aware adapter. No sound is enabled by default.
typedef SplashSoundHook = void Function(SplashCue cue);

/// Mounted once above the Navigator, never pushed onto its back stack.
class SplashExperience extends StatefulWidget {
  const SplashExperience(
      {super.key,
      required this.child,
      required this.destinationReady,
      this.preferences,
      this.onSoundCue});
  final Widget child;
  final bool destinationReady;
  final SplashPreferences? preferences;
  final SplashSoundHook? onSoundCue;
  @override
  State<SplashExperience> createState() => _SplashExperienceState();
}

class _SplashExperienceState extends State<SplashExperience>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _story;
  late final AnimationController _doors;
  late final SplashPreferences _preferences;
  final Set<SplashCue> _played = {};
  bool _full = true, _reduced = false, _configured = false;
  bool _finished = false, _opening = false, _foreground = true;
  bool _storyWasAnimating = false, _doorsWereAnimating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preferences = widget.preferences ?? SplashPreferences();
    _story = AnimationController(vsync: this)
      ..addListener(_cues)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _openWhenReady();
      });
    _doors = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          if (mounted) setState(() => _finished = true);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!_configured) {
      _configured = true;
      _reduced = reduce;
      _start();
    } else if (reduce && !_reduced && !_finished) {
      _reduced = true;
      _story.duration = const Duration(milliseconds: 500);
      _doors.duration = const Duration(milliseconds: 300);
      _story.forward();
    }
  }

  void _start() {
    final full = _preferences.needsCinematic;
    if (!mounted) return;
    setState(() => _full = full);
    // Full cinematic: ~5.8s story + ~1.2s door = ~7s total
    // Quick access: ~0.9s story + ~0.4s door = ~1.3s total
    _story.duration =
        Duration(milliseconds: _reduced ? 500 : (_full ? 4800 : 900));
    _doors.duration =
        Duration(milliseconds: _reduced ? 300 : (_full ? 1200 : 400));
    if (_foreground) _story.forward();
  }

  @override
  void didUpdateWidget(covariant SplashExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationReady && !oldWidget.destinationReady) {
      _openWhenReady();
    }
  }

  void _openWhenReady() {
    if (!mounted ||
        _opening ||
        !_foreground ||
        !_story.isCompleted ||
        !widget.destinationReady) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opening || !_foreground || !widget.destinationReady) {
        return;
      }
      _opening = true;
      _emit(SplashCue.opening);
      _doors.forward();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _emit(SplashCue cue) {
    if (_reduced || !_foreground || !_played.add(cue)) return;
    try {
      widget.onSoundCue?.call(cue);
    } catch (_) {/* Audio is optional. */}
  }

  void _cues() {
    if (_story.value >= (_full ? 0.02 : 0.05)) _emit(SplashCue.point);
    if (_story.value >= (_full ? 0.11 : 0.42)) _emit(SplashCue.stretch);
    if (_story.value >= (_full ? 0.25 : 0.69)) _emit(SplashCue.fracture);
    if (_story.value >= (_full ? 0.53 : 0.95)) _emit(SplashCue.lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_storyWasAnimating ||
          (_story.duration != null && _story.value == 0)) {
        _story.forward();
      }
      if (_doorsWereAnimating) _doors.forward();
      _openWhenReady();
    } else if (_foreground) {
      _foreground = false;
      _storyWasAnimating = _story.isAnimating;
      _doorsWereAnimating = _doors.isAnimating;
      _story.stop();
      _doors.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _story.dispose();
    _doors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        ExcludeSemantics(
            excluding: !_finished,
            child: IgnorePointer(ignoring: !_finished, child: widget.child)),
        if (!_finished)
          Positioned.fill(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                      systemNavigationBarColor: Color(0xFF080808),
                      systemNavigationBarIconBrightness: Brightness.light),
                  child: Semantics(
                    label: 'Breakpoint by Manas',
                    child: AbsorbPointer(
                        child: RepaintBoundary(
                      child: AnimatedBuilder(
                          animation: Listenable.merge([_story, _doors]),
                          builder: (context, _) => CustomPaint(
                              key: const ValueKey('breakpoint-splash'),
                              painter: SplashScene(
                                  progress: _story.value,
                                  opening: _doors.value,
                                  full: _full,
                                  reducedMotion: _reduced))),
                    )),
                  ))),
      ]);
}
