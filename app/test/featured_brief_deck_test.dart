import 'package:cie_connect/features/discover/models/published_article_model.dart';
import 'package:cie_connect/features/discover/widgets/featured_brief_deck.dart';
import 'package:cie_connect/features/feed/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<PostModel> posts([int count = 3]) => List.generate(
        count,
        (index) => PostModel(
          id: 'story-$index',
          title: 'Story $index',
          blocks: const [],
          estimatedReadTime: index + 1,
          category: 'Technology',
          likesCount: 0,
          commentsCount: 0,
          isTodaysDrop: false,
          createdAt: DateTime(2026, 8, index + 1),
          authorName: 'CIE Daily',
          publishedArticle: PublishedArticle(
            id: 'story-$index',
            schemaVersion: 2,
            quickBrief: QuickBriefContent(
              category: 'Technology',
              headline: 'A useful student story $index',
              quickSummary: 'A concise reason this story matters to students.',
              threeThingsToKnow: const ['One', 'Two', 'Three'],
            ),
            fullArticle: const FullArticleContent(
              headline: 'Full story',
              hook: 'Hook',
              in20Seconds: 'Summary',
              whatHappened: 'What happened',
              whyThisMatters: 'Why it matters',
              biggerPicture: 'Bigger picture',
              keyStats: [],
              exploreSections: [],
              takeaways: ['Takeaway'],
            ),
            metadata: const {},
          ),
        ),
      );

  Widget subject({
    required List<PostModel> items,
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: FeaturedBriefDeck(
                posts: items,
                onCardTap: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget reactiveSubject(ValueNotifier<List<PostModel>> items) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: ValueListenableBuilder<List<PostModel>>(
                valueListenable: items,
                builder: (_, value, __) => FeaturedBriefDeck(
                  posts: value,
                  onCardTap: (_, __) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> swipe(WidgetTester tester, Offset offset) async {
    await tester.fling(find.byType(PageView), offset, 1300);
    await tester.pumpAndSettle();
  }

  testWidgets('initializes at the first story and exposes compact progress',
      (tester) async {
    await tester.pumpWidget(subject(items: posts()));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('featured-brief-position')), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('A useful student story 0'), findsOneWidget);
  });

  testWidgets('forward and backward swipes settle on the expected story',
      (tester) async {
    await tester.pumpWidget(subject(items: posts()));
    await tester.pump();

    await swipe(tester, const Offset(-320, 0));
    expect(find.text('2 / 3'), findsOneWidget);
    await swipe(tester, const Offset(-320, 0));
    expect(find.text('3 / 3'), findsOneWidget);
    await swipe(tester, const Offset(320, 0));
    expect(find.text('2 / 3'), findsOneWidget);
    await swipe(tester, const Offset(320, 0));
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('a slow partial swipe returns cleanly to the current page',
      (tester) async {
    await tester.pumpWidget(subject(items: posts()));
    await tester.pump();

    final center = tester.getCenter(find.byType(PageView));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(-35, 0));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('rapid direction changes settle without corrupting page state',
      (tester) async {
    await tester.pumpWidget(subject(items: posts()));
    await tester.pump();

    await tester.fling(find.byType(PageView), const Offset(-320, 0), 1500);
    await tester.pump(const Duration(milliseconds: 70));
    await tester.fling(find.byType(PageView), const Offset(320, 0), 1500);
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves the active story across equivalent feed updates',
      (tester) async {
    final source = ValueNotifier<List<PostModel>>(posts());
    addTearDown(source.dispose);
    await tester.pumpWidget(reactiveSubject(source));
    await tester.pump();

    await swipe(tester, const Offset(-320, 0));
    expect(find.text('2 / 3'), findsOneWidget);

    source.value = source.value
        .map((post) => post.copyWith(likesCount: post.likesCount + 1))
        .toList(growable: false);
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty deck is safe and both themes render without overflow',
      (tester) async {
    await tester.pumpWidget(subject(items: const []));
    expect(find.byType(PageView), findsNothing);

    await tester.pumpWidget(
      subject(items: posts(), themeMode: ThemeMode.dark),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('large accessibility text does not overflow the deck',
      (tester) async {
    await tester.pumpWidget(subject(items: posts(), textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('1 / 3'), findsOneWidget);
  });
}
