import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cie_connect/features/auth/splash/routed_splash.dart';
import 'package:cie_connect/features/auth/splash/splash_experience.dart';
import 'package:cie_connect/features/auth/splash/splash_preferences.dart';
import 'package:cie_connect/features/auth/splash/splash_scene.dart';

SplashPreferences _makePrefs(LaunchExperience experience) {
  final prefs = SplashPreferences();
  prefs.configure(experience);
  return prefs;
}

void main() {
  test('SplashPreferences defaults to cinematic and can be configured', () {
    final prefs = SplashPreferences();
    expect(prefs.needsCinematic, isTrue);
    expect(prefs.experience, LaunchExperience.cinematic);

    prefs.configure(LaunchExperience.quickAccess);
    expect(prefs.needsCinematic, isFalse);
    expect(prefs.experience, LaunchExperience.quickAccess);

    prefs.configure(LaunchExperience.cinematic);
    expect(prefs.needsCinematic, isTrue);
  });

  Future<void> mount(WidgetTester tester, SplashPreferences prefs,
      {bool ready = true, bool reduce = false}) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: SplashExperience(
                preferences: prefs,
                destinationReady: ready,
                child: const Scaffold(body: Text('Actual destination'))))));
    await tester.pump();
    await tester.pump();
  }

  final splash = find.byKey(const ValueKey('breakpoint-splash'));
  Future<void> advance(WidgetTester tester, int milliseconds) async {
    for (var elapsed = 0; elapsed < milliseconds; elapsed += 10) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  testWidgets('full cinematic holds the world before a deliberate opening',
      (tester) async {
    final prefs = _makePrefs(LaunchExperience.cinematic);
    await mount(tester, prefs);
    expect(find.text('Actual destination'), findsOneWidget);
    await advance(tester, 3800);
    final worldFrame =
        tester.widget<CustomPaint>(splash).painter! as SplashScene;
    expect(worldFrame.progress, closeTo(3800 / 4800, 0.02));
    expect(worldFrame.opening, 0);
    await advance(tester, 999);
    await tester.pump();
    expect(splash, findsOneWidget);
    final heldFrame =
        tester.widget<CustomPaint>(splash).painter! as SplashScene;
    expect(heldFrame.opening, 0);
    await advance(tester, 1100);
    expect(splash, findsOneWidget);
    await advance(tester, 200);
    await tester.pump();
    expect(splash, findsNothing);
  });

  testWidgets('quick access completes rapidly', (tester) async {
    final prefs = _makePrefs(LaunchExperience.quickAccess);
    await mount(tester, prefs);
    await advance(tester, 900);
    await tester.pump();
    await advance(tester, 500);
    await tester.pump();
    expect(splash, findsNothing);
  });

  testWidgets(
      'late initialization holds without replay then reveals real child',
      (tester) async {
    final prefs = _makePrefs(LaunchExperience.cinematic);
    await mount(tester, prefs, ready: false);
    await advance(tester, 10000);
    expect(splash, findsOneWidget);
    expect(
        (tester.widget<CustomPaint>(splash).painter! as SplashScene).progress,
        1);
    await mount(tester, prefs);
    await tester.pump();
    await advance(tester, 1300);
    await tester.pump();
    expect(splash, findsNothing);
    expect(find.text('Actual destination'), findsOneWidget);
  });

  testWidgets('reduced motion is an 800ms opacity reveal', (tester) async {
    final prefs = _makePrefs(LaunchExperience.cinematic);
    await mount(tester, prefs, reduce: true);
    expect(
        (tester.widget<CustomPaint>(splash).painter! as SplashScene)
            .reducedMotion,
        isTrue);
    await advance(tester, 500);
    await tester.pump();
    await advance(tester, 350);
    await tester.pump();
    expect(splash, findsNothing);
  });

  testWidgets('pausing suspends the intro and resumes at the same frame',
      (tester) async {
    await mount(tester, _makePrefs(LaunchExperience.cinematic));
    await tester.pump(const Duration(milliseconds: 700));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final before =
        (tester.widget<CustomPaint>(splash).painter! as SplashScene).progress;
    await tester.pump(const Duration(seconds: 5));
    expect(
        (tester.widget<CustomPaint>(splash).painter! as SplashScene).progress,
        before);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(splash, findsNothing);
  });

  testWidgets('actual router child survives doors, theme changes and back',
      (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', builder: (_, __) => const Scaffold(body: Text('Gate'))),
      GoRoute(
          path: '/destination',
          builder: (_, __) => const Scaffold(body: Text('Routed content'))),
    ]);
    final prefs = _makePrefs(LaunchExperience.quickAccess);
    final theme = ValueNotifier(ThemeMode.dark);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
        valueListenable: theme,
        builder: (_, mode, __) => MaterialApp.router(
            themeMode: mode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            routerConfig: router,
            builder: (_, child) => RoutedSplash(
                router: router, preferences: prefs, child: child!))));
    router.go('/destination');
    await advance(tester, 1400);
    expect(find.text('Routed content'), findsOneWidget);
    expect(splash, findsNothing);
    expect(router.canPop(), isFalse);
    theme.value = ThemeMode.light;
    await tester.pumpAndSettle();
    expect(splash, findsNothing);
    expect(Theme.of(tester.element(find.text('Routed content'))).brightness,
        Brightness.light);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(splash, findsNothing);
    router.dispose();
    theme.dispose();
  });

  testWidgets('scene frames render at narrow, tall and tablet dimensions',
      (tester) async {
    final loader = FontLoader('BreakpointSplashOutfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit-Variable.ttf'));
    await loader.load();
    for (final size in [
      const Size(320, 568),
      const Size(430, 932),
      const Size(768, 1024)
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final seconds in [0.25, 0.8, 1.2, 1.9, 2.7, 3.35, 4.05, 4.7]) {
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            home: RepaintBoundary(
                key: key,
                child: Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xFF191919)),
                  CustomPaint(
                      painter: SplashScene(
                          progress: (seconds / 4.80).clamp(0, 1),
                          opening: ((seconds - 4.80) / 1.2).clamp(0, 1),
                          full: true,
                          reducedMotion: false)),
                ]))));
        expect(tester.takeException(), isNull);
        if (Platform.environment['SPLASH_CAPTURE'] == '1' &&
            size.width == 430) {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('build/splash-review').create(recursive: true);
            await File('build/splash-review/frame-$seconds.png')
                .writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
