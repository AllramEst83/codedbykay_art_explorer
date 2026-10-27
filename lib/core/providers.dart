import 'dart:ui';

import 'package:codedbykay_art_explorer/core/env.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:codedbykay_art_explorer/sources/europeana/europeana_source.dart';
import 'package:codedbykay_art_explorer/sources/wikipedia/wikipedia_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must be overridden at startup with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Language for remote content: the chosen app language, else the device's.
final dataLanguageProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale?.languageCode ??
      PlatformDispatcher.instance.locale.languageCode;
});

/// All registered art sources. Add new provider modules here.
final artSourcesProvider = Provider<List<ArtSource>>((ref) {
  final lang = ref.watch(dataLanguageProvider);
  final wikipediaDio = Dio(
    BaseOptions(headers: {'User-Agent': 'ArtExplorer/1.0 (private use)'}),
  );
  return [
    EuropeanaSource(
      buildEuropeanaDio(Env.europeanaKey),
      wikipedia: WikipediaClient(wikipediaDio, lang: lang),
      lang: lang,
    ),
  ];
});

final artSourceProvider = Provider.family<ArtSource, String>((ref, id) {
  final sources = ref.watch(artSourcesProvider);
  return sources.firstWhere((s) => s.id == id, orElse: () => sources.first);
});

/// The source used for search/explore. Single source for now.
final primarySourceProvider = Provider<ArtSource>(
  (ref) => ref.watch(artSourcesProvider).first,
);

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield !(await connectivity.checkConnectivity()).contains(
    ConnectivityResult.none,
  );
  yield* connectivity.onConnectivityChanged.map(
    (r) => !r.contains(ConnectivityResult.none),
  );
});
