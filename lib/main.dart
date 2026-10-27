import 'package:codedbykay_art_explorer/app/app.dart';
import 'package:codedbykay_art_explorer/core/env.dart';
import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ArtExplorerApp(),
    ),
  );
}
