import 'package:cie_connect/core/theme/app_theme.dart';
import 'package:cie_connect/features/spaces/models/live_stream_model.dart';
import 'package:cie_connect/features/spaces/providers/spaces_provider.dart';
import 'package:cie_connect/features/spaces/screens/spaces_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _subject({
  required List<LiveStreamModel> streams,
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      liveStreamsProvider.overrideWith((ref) => Stream.value(streams)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const SpacesHomeScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setPhoneSize(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  testWidgets('compact empty state scrolls completely in dark mode',
      (tester) async {
    await setPhoneSize(tester, size: const Size(320, 568));
    await tester.pumpWidget(_subject(streams: const [], textScale: 1.25));
    await tester.pump();

    expect(find.text('Nothing live right now.'), findsOneWidget);
    expect(find.text('What we talk about'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Curiosity looks good on you.'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Curiosity looks good on you.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light mode remains readable on a tall phone', (tester) async {
    await setPhoneSize(tester, size: const Size(430, 932));
    await tester.pumpWidget(
      _subject(streams: const [], themeMode: ThemeMode.light),
    );
    await tester.pump();

    expect(find.text('Spaces'), findsOneWidget);
    expect(find.text('A note from Manas'), findsOneWidget);
    expect(find.textContaining('Review CIE Daily'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active stream becomes the primary join action', (tester) async {
    await setPhoneSize(tester, size: const Size(390, 844));
    final live = LiveStreamModel(
      id: 'space-1',
      title: 'Learning the newest AI tools',
      hostId: 'host-1',
      hostName: 'Manas Vignesh Varma',
      status: 'live',
      createdAt: DateTime(2026, 9, 7),
      roomName: 'room-1',
      participantCount: 12,
    );

    await tester.pumpWidget(_subject(streams: [live]));
    await tester.pump();

    expect(find.text('LIVE NOW'), findsOneWidget);
    expect(find.text('Learning the newest AI tools'), findsOneWidget);
    expect(find.text('Live with Manas Vignesh Varma'), findsOneWidget);
    expect(find.text('Join live'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
