import '../../feed/models/post_model.dart';

int compareArticlesNewestFirst(PostModel left, PostModel right) {
  final byDate = right.chronologicalDate.compareTo(left.chronologicalDate);
  if (byDate != 0) return byDate;
  return left.id.compareTo(right.id);
}

List<PostModel> sortArticlesNewestFirst(Iterable<PostModel> articles) {
  return articles.toList()..sort(compareArticlesNewestFirst);
}
