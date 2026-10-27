import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/features/history/history_controller.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_settings_sheet.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final sources = ref.watch(artSourcesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        children: [
          _Header(context.l10n.appearance),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (m) {
              if (m != null) ref.read(themeModeProvider.notifier).set(m);
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(context.l10n.systemDefault),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(context.l10n.light),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(context.l10n.dark),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          _Header(context.l10n.language),
          RadioGroup<String>(
            groupValue: ref.watch(localeProvider)?.languageCode ?? 'system',
            onChanged: (code) {
              if (code == null) return;
              ref
                  .read(localeProvider.notifier)
                  .set(code == 'system' ? null : Locale(code));
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(context.l10n.languageSystem),
                  value: 'system',
                ),
                const RadioListTile<String>(
                  title: Text('English'),
                  value: 'en',
                ),
                const RadioListTile<String>(
                  title: Text('Svenska'),
                  value: 'sv',
                ),
              ],
            ),
          ),
          _Header(context.l10n.readerSection),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(context.l10n.defaultReadingStyle),
            subtitle: Text(context.l10n.defaultReadingStyleHint),
            onTap: () => showReaderSettings(context),
          ),
          _Header(context.l10n.sources),
          for (final s in sources)
            ListTile(
              leading: const Icon(Icons.museum_outlined),
              title: Text(s.displayName),
              subtitle: Text(context.l10n.enabled),
            ),
          _Header(context.l10n.data),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(context.l10n.clearHistory),
            onTap: () {
              ref.read(historyProvider.notifier).clear();
              ref.read(recentSearchesProvider.notifier).clear();
              _toast(context, context.l10n.historyCleared);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: Text(context.l10n.clearImageCache),
            onTap: () async {
              await DefaultCacheManager().emptyCache();
              PaintingBinding.instance.imageCache.clear();
              if (context.mounted) {
                _toast(context, context.l10n.imageCacheCleared);
              }
            },
          ),
          _Header(context.l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Art Explorer'),
            subtitle: const Text(
              'Artwork metadata and images come from Europeana and its data '
              'providers. Each item shows its own rights statement. '
              'Biographies come from Wikipedia (CC BY-SA).',
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Art Explorer',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.licensesHint,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
