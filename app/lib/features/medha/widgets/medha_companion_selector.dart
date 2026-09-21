import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/medha_models.dart';

class MedhaCompanionSelector extends StatelessWidget {
  const MedhaCompanionSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final MedhaCompanionType selected;
  final ValueChanged<MedhaCompanionType> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 226 : 300,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: MedhaCompanionType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = MedhaCompanionType.values[index];
          return _CompanionCard(
            type: type,
            selected: selected == type,
            compact: compact,
            onTap: () => onSelected(type),
          );
        },
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({
    required this.type,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final MedhaCompanionType type;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = type.profile;
    final width = compact ? 156.0 : 202.0;
    final imageHeight = compact ? 106.0 : 154.0;
    final accent = AppTheme.accentColor(context);
    return Semantics(
      selected: selected,
      button: true,
      label: '${profile.name}, ${profile.title}. ${profile.traits.join(', ')}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : AppTheme.cardBorderColor(context),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Image.asset(profile.assetPath, fit: BoxFit.contain),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 15),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                profile.name.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryTextColor(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
              Text(
                profile.title,
                maxLines: 1,
                style: TextStyle(
                  color: AppTheme.secondaryTextColor(context),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                profile.traits.join(' • '),
                maxLines: 1,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  '“${profile.personalityLine}”',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor(context),
                    height: 1.3,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
