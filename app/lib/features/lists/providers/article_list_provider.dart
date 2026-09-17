import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/post_model.dart';
import '../data/article_list_repository.dart';
import '../models/article_list.dart';

final myArticleListsProvider = StreamProvider.autoDispose<List<ArticleList>>(
    (ref) => ref.watch(articleListRepositoryProvider).watchMine());
final articleListProvider = StreamProvider.autoDispose
    .family<ArticleList?, String>(
        (ref, id) => ref.watch(articleListRepositoryProvider).watchOne(id));
final articleListPostsProvider = FutureProvider.autoDispose
    .family<List<PostModel>, ArticleList>((ref, list) => ref
        .watch(articleListRepositoryProvider)
        .fetchArticles(list.articleIds));
