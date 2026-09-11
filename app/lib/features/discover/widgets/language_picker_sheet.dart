import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/supported_languages.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LanguagePickerButton extends ConsumerWidget {
  final List<String> availableLanguageIds;
  final bool compact;

  const LanguagePickerButton({
    super.key,
    required this.availableLanguageIds,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (availableLanguageIds.length <= 1) {
      return const SizedBox.shrink();
    }

    final selectedLang = ref.watch(contentLanguageProvider);
    // If the selected language is not available for this article, display English label
    final effectiveLang = availableLanguageIds.contains(selectedLang) ? selectedLang : 'en';
    final label = SupportedLanguages.getNativeLabel(effectiveLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLanguagePickerSheet(context, ref, availableLanguageIds),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.translate_rounded,
                size: compact ? 12 : 14,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: compact ? 14 : 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showLanguagePickerSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> availableLanguageIds,
) {
  final currentLang = ref.read(contentLanguageProvider);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final textPrimary = isDark ? Colors.white : Colors.black87;
  final textSecondary = isDark ? Colors.white60 : Colors.black54;

  showModalBottomSheet(
    context: context,
    backgroundColor: bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableLanguageIds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    final langId = availableLanguageIds[index];
                    final isSelected = (currentLang == langId) ||
                        (!availableLanguageIds.contains(currentLang) && langId == 'en');
                    final nativeLabel = SupportedLanguages.getNativeLabel(langId);
                    final englishName = SupportedLanguages.getName(langId);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      title: Text(
                        nativeLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryOrange : textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        englishName,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryOrange,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        ref.read(contentLanguageProvider.notifier).setLanguage(langId);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
