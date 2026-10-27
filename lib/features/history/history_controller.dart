import 'dart:convert';

import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recently viewed artworks (most recent first).
class HistoryController extends Notifier<List<Artwork>> {
  static const _key = 'history.v1';
  static const maxItems = 30;

  @override
  List<Artwork> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List<dynamic>) return const [];
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) Artwork.fromJson(e),
      ];
    } on Object {
      return const [];
    }
  }

  void add(Artwork artwork) {
    final list = [
      artwork,
      ...state.where((a) => a.key != artwork.key),
    ].take(maxItems).toList();
    state = list;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode([for (final a in list) a.toJson()]));
  }

  void clear() {
    state = const [];
    ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final historyProvider = NotifierProvider<HistoryController, List<Artwork>>(
  HistoryController.new,
);

/// Recent search strings (most recent first).
class RecentSearchesController extends Notifier<List<String>> {
  static const _key = 'searches.v1';

  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = [
      q,
      ...state.where((s) => s.toLowerCase() != q.toLowerCase()),
    ].take(10).toList();
    state = list;
    ref.read(sharedPreferencesProvider).setStringList(_key, list);
  }

  void clear() {
    state = const [];
    ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesController, List<String>>(
      RecentSearchesController.new,
    );
