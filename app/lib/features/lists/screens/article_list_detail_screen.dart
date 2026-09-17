import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sharing/breakpoint_links.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/breakpoint_share_sheet.dart';
import '../data/article_list_repository.dart';
import '../models/article_list.dart';
import '../providers/article_list_provider.dart';

class ArticleListDetailScreen extends ConsumerWidget {
  const ArticleListDetailScreen({super.key, required this.listId});
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(articleListProvider(listId));
    return listAsync.when(
      data: (list) {
        if (list == null)
          return const Scaffold(
              body: Center(child: Text('This List is unavailable.')));
        final owner = FirebaseAuth.instance.currentUser?.uid == list.ownerUid;
        final posts = ref.watch(articleListPostsProvider(list));
        return Scaffold(
          appBar: AppBar(
            title: const Text('List'),
            actions: [
              IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Share List',
                  onPressed: () => _share(context, list)),
              if (owner)
                PopupMenuButton<String>(
                    onSelected: (value) =>
                        _ownerAction(context, ref, list, value),
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Edit List')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete List'))
                        ]),
            ],
          ),
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(list.title,
                              style: TextStyle(
                                  color: AppTheme.primaryTextColor(context),
                                  fontFamily: 'Sora',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                              'By ${list.ownerName} · ${list.articleIds.length} ${list.articleIds.length == 1 ? 'story' : 'stories'}',
                              style: TextStyle(
                                  color: AppTheme.secondaryTextColor(context))),
                          if (list.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(list.description,
                                style: TextStyle(
                                    color: AppTheme.primaryTextColor(context),
                                    height: 1.45))
                          ],
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                              onPressed: () => _share(context, list),
                              icon: const Icon(Icons.qr_code_2_rounded),
                              label: const Text('Share or show QR'))
                        ]))),
            posts.when(
              data: (items) => items.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child:
                          Center(child: Text('No stories in this List yet.')))
                  : SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                          indent: 20,
                          endIndent: 20,
                          color: AppTheme.materialEdgeColor(context)),
                      itemBuilder: (_, index) {
                        final post = items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          leading: post.imageUrl == null
                              ? null
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(post.imageUrl!,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover)),
                          title: Text(post.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${post.category} · ${post.estimatedReadTime} min read'),
                          trailing: owner
                              ? IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline_rounded),
                                  tooltip: 'Remove from List',
                                  onPressed: () => ref
                                      .read(articleListRepositoryProvider)
                                      .removeArticle(list.id, post.id))
                              : null,
                          onTap: () =>
                              context.push('/article/${post.id}', extra: post),
                        );
                      },
                    ),
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverFillRemaining(
                  child: Center(child: Text('Stories could not be loaded.'))),
            ),
          ]),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(
          body: Center(child: Text('This List could not be loaded.'))),
    );
  }

  void _share(BuildContext context, ArticleList list) =>
      BreakpointShareSheet.show(context,
          title: list.title,
          url: BreakpointLinks.list(list.id),
          shareText:
              '${list.ownerName} shared a Breakpoint list with you: ${list.title}',
          qrInstruction: 'Scan to open this List in Breakpoint');

  Future<void> _ownerAction(BuildContext context, WidgetRef ref,
      ArticleList list, String action) async {
    if (action == 'delete') {
      await ref.read(articleListRepositoryProvider).delete(list.id);
      if (context.mounted) context.pop();
      return;
    }
    final title = TextEditingController(text: list.title);
    final description = TextEditingController(text: list.description);
    final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Edit List'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: description,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'Description'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Save'))
                ]));
    if (save == true && title.text.trim().isNotEmpty)
      await ref
          .read(articleListRepositoryProvider)
          .update(list.id, title: title.text, description: description.text);
  }
}
