import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/medha_models.dart';
import '../providers/medha_preferences_provider.dart';
import 'medha_companion_selector.dart';

class MedhaSettingsSection extends ConsumerWidget {
  const MedhaSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(medhaPreferencesProvider);
    final profile = preferences.companion.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            'MEDHA',
            style: TextStyle(
              color: AppTheme.accentColor(context),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: SizedBox(
            width: 46,
            height: 46,
            child: Image.asset(profile.assetPath, fit: BoxFit.contain),
          ),
          title: Text(
            'MEDHA Companion',
            style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            '${profile.name} · ${profile.title}',
            style: TextStyle(
              color: AppTheme.secondaryTextColor(context),
              fontSize: 12,
            ),
          ),
          trailing: TextButton(
            onPressed: () =>
                _changeCompanion(context, ref, preferences.companion),
            child: const Text('Change'),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.auto_awesome_rounded,
              color: AppTheme.primaryTextColor(context)),
          title: Text(
            'Show MEDHA companion',
            style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Your selected companion appears as a quiet edge presence.',
            style: TextStyle(
                color: AppTheme.secondaryTextColor(context), fontSize: 12),
          ),
          value: preferences.enabled,
          activeThumbColor: AppTheme.primaryOrange,
          onChanged: ref.read(medhaPreferencesProvider.notifier).setEnabled,
        ),
        SwitchListTile(
          secondary: Icon(Icons.record_voice_over_outlined,
              color: AppTheme.primaryTextColor(context)),
          title: Text(
            'Automatically speak answers',
            style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Off by default. You can still tap Listen on any answer.',
            style: TextStyle(
                color: AppTheme.secondaryTextColor(context), fontSize: 12),
          ),
          value: preferences.voiceEnabled,
          activeThumbColor: AppTheme.primaryOrange,
          onChanged:
              ref.read(medhaPreferencesProvider.notifier).setVoiceEnabled,
        ),
        SwitchListTile(
          secondary: Icon(Icons.volume_down_outlined,
              color: AppTheme.primaryTextColor(context)),
          title: Text(
            'Companion sounds',
            style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Off by default. No ambient loops.',
            style: TextStyle(
                color: AppTheme.secondaryTextColor(context), fontSize: 12),
          ),
          value: preferences.soundsEnabled,
          activeThumbColor: AppTheme.primaryOrange,
          onChanged:
              ref.read(medhaPreferencesProvider.notifier).setSoundsEnabled,
        ),
        Divider(color: AppTheme.cardBorderColor(context), height: 1),
      ],
    );
  }

  Future<void> _changeCompanion(
    BuildContext context,
    WidgetRef ref,
    MedhaCompanionType current,
  ) async {
    var selected = current;
    final result = await showModalBottomSheet<MedhaCompanionType>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorderColor(context)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose your MEDHA companion',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Same intelligence. Different spirits.',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                MedhaCompanionSelector(
                  selected: selected,
                  compact: true,
                  onSelected: (value) => setModalState(() => selected = value),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text('Choose ${selected.profile.name}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      await ref.read(medhaPreferencesProvider.notifier).selectCompanion(result);
    }
  }
}
