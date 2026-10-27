import 'package:codedbykay_art_explorer/app/app_theme.dart';
import 'package:codedbykay_art_explorer/app/router.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ArtExplorerApp extends ConsumerStatefulWidget {
  const ArtExplorerApp({super.key});

  @override
  ConsumerState<ArtExplorerApp> createState() => _ArtExplorerAppState();
}

class _ArtExplorerAppState extends ConsumerState<ArtExplorerApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        locale: locale,
        theme: buildTheme(
          Brightness.light,
          dynamicScheme: fromDynamic(lightDynamic, Brightness.light),
        ),
        darkTheme: buildTheme(
          Brightness.dark,
          dynamicScheme: fromDynamic(darkDynamic, Brightness.dark),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      ),
    );
  }
}
