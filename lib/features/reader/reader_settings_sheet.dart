import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension ReaderThemeName on ReaderTheme {
  String localizedName(AppLocalizations l) => switch (this) {
    ReaderTheme.paper => l.themePaper,
    ReaderTheme.sepia => l.themeSepia,
    ReaderTheme.night => l.themeNight,
  };
}

Future<void> showReaderSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const ReaderSettingsSheet(),
    );

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readerPrefsProvider);
    final controller = ref.read(readerPrefsProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.background, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final t in ReaderTheme.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ThemeSwatch(
                      theme: t,
                      selected: t == prefs.theme,
                      onTap: () => controller.update(prefs.copyWith(theme: t)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.fontSize(prefs.fontSize.round()),
              style: theme.textTheme.titleSmall,
            ),
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Slider(
                    value: prefs.fontSize,
                    min: ReaderPrefs.minFontSize,
                    max: ReaderPrefs.maxFontSize,
                    divisions:
                        (ReaderPrefs.maxFontSize - ReaderPrefs.minFontSize)
                            .round(),
                    label: '${prefs.fontSize.round()}',
                    semanticFormatterCallback: (v) => '${v.round()} points',
                    onChanged: (v) =>
                        controller.update(prefs.copyWith(fontSize: v)),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 26)),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.l10n.font, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in ReaderFont.values)
                  ChoiceChip(
                    label: Text(f.label, style: f.style()),
                    selected: f == prefs.font,
                    onSelected: (_) =>
                        controller.update(prefs.copyWith(font: f)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.lineSpacing(prefs.lineHeight.toStringAsFixed(1)),
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: prefs.lineHeight,
              min: 1.2,
              max: 2.2,
              divisions: 10,
              onChanged: (v) =>
                  controller.update(prefs.copyWith(lineHeight: v)),
            ),
            Text(
              context.l10n.margins(prefs.margin.round()),
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: prefs.margin,
              min: 8,
              max: 48,
              divisions: 10,
              onChanged: (v) => controller.update(prefs.copyWith(margin: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.backgroundLabel(theme.localizedName(context.l10n)),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? primary : Colors.grey,
              width: selected ? 3 : 1,
            ),
          ),
          child: Text(
            'Aa',
            style: TextStyle(
              color: theme.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
