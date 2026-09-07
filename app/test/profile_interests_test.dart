import 'package:cie_connect/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> parseInterests(Map<String, dynamic>? profileData) {
  const defaults = <String>[
    'Campus',
    'Events',
    'Sports',
    'Art',
    'Tech',
  ];
  if (profileData == null) return defaults;

  if (profileData.containsKey('interests')) {
    final raw = profileData['interests'];
    if (raw is Iterable) {
      final result = <String>[];
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) {
          final val = item.trim();
          if (!result.contains(val)) result.add(val);
        }
      }
      return result;
    }
  }

  if (profileData.containsKey('highlights')) {
    final raw = profileData['highlights'];
    if (raw is Iterable) {
      final result = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final label = item['label'];
          if (label is String && label.trim().isNotEmpty) {
            final val = label.trim();
            if (!result.contains(val)) result.add(val);
          }
        } else if (item is String && item.trim().isNotEmpty) {
          final val = item.trim();
          if (!result.contains(val)) result.add(val);
        }
      }
      if (result.isNotEmpty) return result;
    }
  }

  return defaults;
}

Widget _buildTestInterestsCard({
  required List<String> interests,
  required bool isSelf,
  required VoidCallback onEditTap,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          final primaryText = AppTheme.primaryTextColor(context);
          final cardColor = AppTheme.cardColor(context);
          final borderColor = AppTheme.cardBorderColor(context);

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Interests & Focus Areas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                    ),
                    if (isSelf)
                      InkWell(
                        onTap: onEditTap,
                        child: Text(
                          interests.isEmpty ? '+ Add interests' : 'Edit',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (interests.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((label) {
                      return Chip(
                        label: Text(label),
                        backgroundColor: AppTheme.surfaceMutedColor(context),
                      );
                    }).toList(),
                  )
                else if (isSelf)
                  InkWell(
                    onTap: onEditTap,
                    child: const Text(
                      'Add interests',
                      style: TextStyle(color: AppTheme.primaryOrange),
                    ),
                  )
                else
                  const Text('No interests added yet'),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildTestEditSheet({
  required List<String> currentInterests,
  required void Function(List<String>) onSave,
}) {
  const defaultTopics = <String>[
    'Tech',
    'AI & ML',
    'Startups',
    'Coding',
    'Engineering',
    'Design',
    'Campus',
  ];

  final selectedInterests = Set<String>.from(currentInterests);

  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Interests & Focus Areas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: defaultTopics.map((topic) {
                    final isSelected = selectedInterests.contains(topic);
                    return ChoiceChip(
                      label: Text(topic),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryOrange,
                      onSelected: (selected) {
                        setSheetState(() {
                          if (selected) {
                            selectedInterests.add(topic);
                          } else {
                            selectedInterests.remove(topic);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                        ),
                        onPressed: () => onSave(selectedInterests.toList()),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  group('Interests Parser Unit Tests', () {
    test('returns default topics when profile data is null or empty', () {
      final fromNull = parseInterests(null);
      expect(fromNull, ['Campus', 'Events', 'Sports', 'Art', 'Tech']);

      final fromEmpty = parseInterests({});
      expect(fromEmpty, ['Campus', 'Events', 'Sports', 'Art', 'Tech']);
    });

    test('extracts direct interests list correctly', () {
      final result = parseInterests({
        'interests': ['AI & ML', 'Startups', 'Coding'],
      });
      expect(result, ['AI & ML', 'Startups', 'Coding']);
    });

    test('preserves explicitly empty interests list', () {
      final result = parseInterests({
        'interests': <String>[],
      });
      expect(result, isEmpty);
    });

    test('extracts from legacy highlights format if interests missing', () {
      final result = parseInterests({
        'highlights': [
          {'label': 'Robotics', 'color': '0xFFFF5A1F'},
          {'label': 'Web3', 'color': '0xFF007AFF'},
        ],
      });
      expect(result, ['Robotics', 'Web3']);
    });

    test('deduplicates and trims whitespace in interests', () {
      final result = parseInterests({
        'interests': ['  Tech  ', 'Tech', 'Design '],
      });
      expect(result, ['Tech', 'Design']);
    });
  });

  group('Interests UI Widget Tests', () {
    testWidgets('renders interests card with populated items', (tester) async {
      await tester.pumpWidget(
        _buildTestInterestsCard(
          interests: ['Tech', 'AI & ML', 'Coding'],
          isSelf: true,
          onEditTap: () {},
        ),
      );

      expect(find.text('Interests & Focus Areas'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Tech'), findsOneWidget);
      expect(find.text('AI & ML'), findsOneWidget);
      expect(find.text('Coding'), findsOneWidget);
      expect(find.text('New Highlight'), findsNothing);
    });

    testWidgets('renders empty state for self profile with + Add interests',
        (tester) async {
      await tester.pumpWidget(
        _buildTestInterestsCard(
          interests: const [],
          isSelf: true,
          onEditTap: () {},
        ),
      );

      expect(find.text('Interests & Focus Areas'), findsOneWidget);
      expect(find.text('+ Add interests'), findsOneWidget);
      expect(find.text('Add interests'), findsOneWidget);
    });

    testWidgets('renders edit sheet and allows chip selection and saving',
        (tester) async {
      List<String>? savedInterests;

      await tester.pumpWidget(
        _buildTestEditSheet(
          currentInterests: ['Tech'],
          onSave: (list) {
            savedInterests = list;
          },
        ),
      );

      expect(find.text('Edit Interests & Focus Areas'), findsOneWidget);
      expect(find.text('New Highlight'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Select 'AI & ML'
      await tester.tap(find.text('AI & ML'));
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedInterests, isNotNull);
      expect(savedInterests, contains('Tech'));
      expect(savedInterests, contains('AI & ML'));
    });
  });
}
