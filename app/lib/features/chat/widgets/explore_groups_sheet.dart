import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/group_chat_repository.dart';
import '../models/group_chat_model.dart';
import '../providers/group_chat_providers.dart';

class ExploreGroupsSheet extends ConsumerStatefulWidget {
  const ExploreGroupsSheet({super.key});

  @override
  ConsumerState<ExploreGroupsSheet> createState() => _ExploreGroupsSheetState();
}

class _ExploreGroupsSheetState extends ConsumerState<ExploreGroupsSheet> {
  String _selectedCategoryFilter = 'All';

  final List<String> _categories = [
    'All',
    'Tech',
    'Coding',
    'AI & ML',
    'Gaming',
    'Music',
    'Sports',
    'Events',
    'Entrepreneurship',
  ];

  @override
  Widget build(BuildContext context) {
    final discoverableAsync = ref.watch(discoverableGroupsProvider);
    final user = FirebaseAuth.instance.currentUser;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + safeBottom + 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            'Discover Campus Communities',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryText,
                fontFamily: 'Outfit'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Find and join student groups matching your interests.',
            style: TextStyle(
                fontSize: 13, color: secondaryText, fontFamily: 'Inter'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Category Filter Pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final cat = _categories[index];
                final isSel = _selectedCategoryFilter == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: AppTheme.primaryOrange,
                  backgroundColor: inputFill,
                  labelStyle: TextStyle(
                      color: isSel ? Colors.white : secondaryText,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategoryFilter = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Groups List
          Expanded(
            child: discoverableAsync.when(
              data: (allGroups) {
                final filtered = _selectedCategoryFilter == 'All'
                    ? allGroups
                    : allGroups
                        .where((g) =>
                            g.category.toLowerCase() ==
                            _selectedCategoryFilter.toLowerCase())
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined,
                            color: secondaryText.withValues(alpha: 0.4),
                            size: 56),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCategoryFilter == 'All'
                              ? 'No communities created yet'
                              : 'No communities under "$_selectedCategoryFilter"',
                          style: TextStyle(
                              color: primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Be the first to create one for your peers!',
                          style: TextStyle(color: secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final group = filtered[index];
                    final isMember =
                        user != null && group.members.contains(user.uid);

                    return _buildGroupCard(ctx, group, isMember);
                  },
                );
              },
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryOrange)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "We couldn't load communities.",
                      style: TextStyle(color: secondaryText),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(discoverableGroupsProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, GroupChatModel group, bool isMember) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Outfit'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        group.category,
                        style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    style: TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                        fontFamily: 'Inter'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${group.members.length} members',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isMember
              ? OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/group_chat/${group.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                    side: const BorderSide(color: AppTheme.primaryOrange),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Open',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )
              : ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(groupChatRepositoryProvider)
                          .joinGroup(group.id);
                      if (mounted && context.mounted) {
                        Navigator.pop(context);
                        context.push('/group_chat/${group.id}');
                      }
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "We couldn't join this community. Please try again."),
                              backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Join',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }
}
