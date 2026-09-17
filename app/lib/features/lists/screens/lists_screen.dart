import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/article_list_repository.dart';
import '../providers/article_list_provider.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(myArticleListsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Lists'),
        actions: [
          IconButton(
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create List',
          ),
        ],
      ),
      body: lists.when(
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 42,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Make a list of ideas worth coming back to.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.primaryTextColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => _create(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create List'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppTheme.materialEdgeColor(context)),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            gradient: AppTheme.premiumSurfaceGradient(context),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.list_alt_rounded,
                            color: AppTheme.accentColor(context))),
                    title: Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${item.articleIds.length} ${item.articleIds.length == 1 ? 'story' : 'stories'}${item.description.isEmpty ? '' : ' · ${item.description}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/list/${item.id}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Lists could not be loaded.')),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Create List'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Description (optional)'),
                      maxLines: 2)
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Create'))
                ]));
    if (result != true || titleController.text.trim().isEmpty) return;
    final id = await ref.read(articleListRepositoryProvider).create(
        title: titleController.text, description: descriptionController.text);
    if (context.mounted) context.push('/list/$id');
  }
}
