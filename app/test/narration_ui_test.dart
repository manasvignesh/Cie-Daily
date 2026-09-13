import 'package:cie_connect/features/discover/widgets/premium_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('narration fallback hides implementation details', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RemoteNarrationUnavailable(
            language: 'te',
            audioStatus: 'failed',
            fallbackText: 'తెలుగు కథనం',
            compact: true,
          ),
        ),
      ),
    );

    expect(find.text('Listen'), findsOneWidget);
    expect(find.textContaining('device voice'), findsNothing);
    expect(find.textContaining('server'), findsNothing);
    expect(find.textContaining('Sarvam'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
  });
}
