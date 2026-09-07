import 'package:cie_connect/features/discover/models/article_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes legacy and producer labels into Discover filters', () {
    expect(normalizeArticleCategory(rawCategory: 'Article', text: 'IIT campus student innovation'), 'Campus');
    expect(normalizeArticleCategory(rawCategory: 'Technology', text: 'Agricultural AI model'), 'AI & ML');
    expect(normalizeArticleCategory(rawCategory: 'General', text: 'A startup raises a seed round'), 'Startups');
    expect(normalizeArticleCategory(rawCategory: 'News', text: 'Inter-college cricket tournament'), 'Sports');
    expect(normalizeArticleCategory(rawCategory: 'Article', text: 'Annual engineering hackathon'), 'Events');
    expect(normalizeArticleCategory(rawCategory: 'Science', text: 'New satellite launch system'), 'Tech');
  });
}
