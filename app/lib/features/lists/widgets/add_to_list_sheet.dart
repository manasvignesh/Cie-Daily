import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/article_list_repository.dart';
import '../providers/article_list_provider.dart';

Future<void> showAddToListSheet(BuildContext context, String articleId) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddToListSheet(articleId: articleId),
  );
}

class _AddToListSheet extends ConsumerWidget {
  const _AddToListSheet({required this.articleId});
  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(myArticleListsProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.raisedSurfaceGradient(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Add to List',
                        style: TextStyle(
                            color: AppTheme.primaryTextColor(context),
                            fontFamily: 'Sora',
                            fontSize: 20,
                            fontWeight: FontWeight.w700))),
                IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Create List',
                    onPressed: () => _create(context, ref)),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: lists.when(
                data: (items) => items.isEmpty
                    ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.add_circle_outline_rounded),
                        title: const Text('Create your first List'),
                        subtitle: const Text(
                            'Make a list of ideas worth coming back to.'),
                        onTap: () => _create(context, ref),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final added = item.articleIds.contains(articleId);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                                added
                                    ? Icons.check_circle_rounded
                                    : Icons.list_alt_rounded,
                                color: added
                                    ? AppTheme.accentColor(context)
                                    : AppTheme.secondaryTextColor(context)),
                            title: Text(item.title),
                            subtitle: Text('${item.articleIds.length} stories'),
                            onTap: added
                                ? null
                                : () async {
                                    await ref
                                        .read(articleListRepositoryProvider)
                                        .addArticle(item.id, articleId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Added to ${item.title}')));
                                    }
                                  },
                          );
                        },
                      ),
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator())),
                error: (_, __) => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Lists could not be loaded.')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'AI rabbit holes')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    await ref
        .read(articleListRepositoryProvider)
        .create(title: title, articleId: articleId);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Added to $title')));
    }
  }
}
