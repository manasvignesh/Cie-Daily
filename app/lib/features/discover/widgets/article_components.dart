import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/verified_badge.dart';
import '../models/structured_article_model.dart';
import 'premium_audio_player.dart';

// ── 1. HERO SECTION (PROPORTIONAL COMPACT COVER IMAGE) ─────────────────────
class ArticleHeroSection extends StatelessWidget {
  final StructuredArticleData article;
  final bool isSelf;
  final bool isFollowing;
  final VoidCallback onFollow;

  const ArticleHeroSection({
    super.key,
    required this.article,
    required this.isSelf,
    required this.isFollowing,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            article.category.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Headline (3-5 lines max)
        Text(
          article.headline,
          style: TextStyle(
            color: primaryText,
            fontSize: MediaQuery.sizeOf(context).width < 380 ? 24 : 28,
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
            height: 1.18,
            letterSpacing: -0.5,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),

        // 1-line Hook
        Text(
          article.hook,
          style: TextStyle(
            color: secondaryText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Proportional Hero Image (30-40% Viewport Width Height Proportion)
        if (article.heroImage != null && article.heroImage!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 2.1,
              child: Image.network(
                article.heroImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppTheme.inputFillColor(context)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (article.audioUrl != null && article.audioUrl!.isNotEmpty)
          PremiumAudioPlayer(
            audioUrl: article.audioUrl!,
            title: article.headline,
            language: article.contentLanguage,
            audioStatus: article.audioStatus,
            fallbackText: article.narrationFallbackText,
          )
        else
          RemoteNarrationUnavailable(
            language: article.contentLanguage,
            audioStatus: article.audioStatus,
            fallbackText: article.narrationFallbackText,
          ),

        const SizedBox(height: 12),

        // Author Row
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.inputFillColor(context),
              backgroundImage: article.authorAvatar != null
                  ? NetworkImage(article.authorAvatar!)
                  : null,
              child: article.authorAvatar == null
                  ? Text(
                      article.authorName.isNotEmpty
                          ? article.authorName[0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          article.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      if (article.isAuthorVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  Text(
                    '${article.readTime} min read',
                    style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
            if (!isSelf)
              OutlinedButton(
                onPressed: onFollow,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isFollowing ? primaryText : AppTheme.primaryOrange,
                  side: BorderSide(
                      color:
                          isFollowing ? borderColor : AppTheme.primaryOrange),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  isFollowing ? 'Following' : '+ Follow',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── 2. IN 20 SECONDS SUMMARY BLOCK ──────────────────────────────────────────
class In20SecondsCard extends StatelessWidget {
  final String text;

  const In20SecondsCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryOrange.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppTheme.primaryOrange, size: 18),
              SizedBox(width: 6),
              Text(
                'IN 20 SECONDS',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. KEY NUMBERS (HORIZONTAL MINIMAL LAYOUT WITH SEPARATORS) ──────────────
class KeyNumbersRow extends StatelessWidget {
  final List<KeyNumberItem> numbers;

  const KeyNumbersRow({super.key, required this.numbers});

  @override
  Widget build(BuildContext context) {
    if (numbers.isEmpty) return const SizedBox.shrink();

    final limited = numbers.take(3).toList();
    final secondaryText = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(limited.length, (idx) {
          final item = limited[idx];
          final isLast = idx == limited.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 28,
                    color: borderColor,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── 4. WHY THIS MATTERS (EDITORIAL INTEGRATED SECTION) ──────────────────────
class WhyThisMattersSection extends StatelessWidget {
  final String text;

  const WhyThisMattersSection({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: AppTheme.primaryOrange, size: 18),
            SizedBox(width: 8),
            Text(
              'WHY THIS MATTERS',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: TextStyle(
            color: primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.5,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: borderColor, height: 1),
      ],
    );
  }
}

// ── 5. EXPLORE THE STORY (CLEAN EXPANDABLE ACCORDION ROWS) ─────────────────
class ExploreTheStorySection extends StatefulWidget {
  final List<ExploreStoryItem> items;

  const ExploreTheStorySection({super.key, required this.items});

  @override
  State<ExploreTheStorySection> createState() => _ExploreTheStorySectionState();
}

class _ExploreTheStorySectionState extends State<ExploreTheStorySection> {
  final Set<int> _expandedIndices = {0}; // Expand first row by default

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPLORE THE STORY',
          style: TextStyle(
            color: primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 12),
        ...widget.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isExpanded = _expandedIndices.contains(idx);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      _expandedIndices.add(idx);
                    } else {
                      _expandedIndices.remove(idx);
                    }
                  });
                },
                leading:
                    Icon(item.icon, color: AppTheme.primaryOrange, size: 20),
                title: Text(
                  item.title,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Outfit',
                  ),
                ),
                subtitle: Text(
                  item.previewText,
                  style: TextStyle(
                      color: secondaryText, fontSize: 12, fontFamily: 'Inter'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: borderColor, height: 16),
                  item.expandedContent,
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── 6. EDITORIAL QUOTE WIDGET ──────────────────────────────────────────────
class EditorialQuoteWidget extends StatelessWidget {
  final String quote;
  final String speaker;
  final String role;

  const EditorialQuoteWidget({
    super.key,
    required this.quote,
    required this.speaker,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppTheme.primaryOrange, size: 32),
          Text(
            '"$quote"',
            style: TextStyle(
              color: primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.45,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— $speaker, $role',
            style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}

// ── 7. YOU NOW KNOW WIDGET ──────────────────────────────────────────────────
class YouNowKnowWidget extends StatelessWidget {
  final List<String> takeaways;

  const YouNowKnowWidget({super.key, required this.takeaways});

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.primaryOrange, size: 18),
            SizedBox(width: 8),
            Text(
              'YOU NOW KNOW',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...takeaways.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_rounded,
                    color: AppTheme.primaryOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── 8. STICKY BOTTOM ACTION BAR ─────────────────────────────────────────────
class ArticleBottomActionBar extends StatelessWidget {
  final bool isSaved;
  final bool isFollowing;
  final VoidCallback onSave;
  final VoidCallback onDiscuss;
  final VoidCallback onShare;
  final VoidCallback onFollow;

  const ArticleBottomActionBar({
    super.key,
    required this.isSaved,
    required this.isFollowing,
    required this.onSave,
    required this.onDiscuss,
    required this.onShare,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onSave,
            tooltip: 'Save',
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? AppTheme.primaryOrange : primaryText,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: onDiscuss,
            tooltip: 'Discuss',
            icon: Icon(Icons.chat_bubble_outline_rounded,
                color: primaryText, size: 22),
          ),
          IconButton(
            onPressed: onShare,
            tooltip: 'Share',
            icon: Icon(Icons.ios_share_rounded, color: primaryText, size: 22),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? AppTheme.inputFillColor(context)
                  : AppTheme.primaryOrange,
              foregroundColor: isFollowing ? primaryText : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              isFollowing ? 'Following' : '+ Follow',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
