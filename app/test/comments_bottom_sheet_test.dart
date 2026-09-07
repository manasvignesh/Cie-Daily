import 'package:cie_connect/core/theme/app_theme.dart';
import 'package:cie_connect/features/feed/models/comment_model.dart';
import 'package:cie_connect/features/feed/providers/comments_provider.dart';
import 'package:cie_connect/features/feed/widgets/comments_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _subject({required ThemeMode themeMode}) {
  final comment = CommentModel(
    id: 'comment-1',
    parentId: 'post-1',
    authorId: 'user-1',
    content: 'A useful comment',
    likesCount: 0,
    createdAt: DateTime(2026, 9, 7),
    authorName: 'Manas Vignesh Varma',
  );

  return ProviderScope(
    overrides: [
      commentsProvider('post-1').overrideWith((ref) => Stream.value([comment])),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => CommentsBottomSheet.show(context, 'post-1'),
              child: const Text('Open comments'),
            ),
          ),
          bottomNavigationBar: const SizedBox(
            height: 72,
            child: Center(child: Text('Navigation')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('comments use one modal surface without overflow in $mode',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_subject(themeMode: mode));
      await tester.tap(find.text('Open comments'));
      await tester.pumpAndSettle();

      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Manas Vignesh Varma'), findsOneWidget);
      expect(find.text('A useful comment'), findsOneWidget);
      expect(find.byType(ModalBarrier), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
