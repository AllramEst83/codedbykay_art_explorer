import 'dart:convert';

import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Bookmark {
  const Bookmark({
    required this.artwork,
    required this.savedAt,
    this.collection,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    artwork: Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
    savedAt:
        DateTime.tryParse(json['savedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    collection: json['collection'] as String?,
  );

  final Artwork artwork;
  final DateTime savedAt;
  final String? collection;

  Bookmark withCollection(String? collection) =>
      Bookmark(artwork: artwork, savedAt: savedAt, collection: collection);

  Map<String, dynamic> toJson() => {
    'artwork': artwork.toJson(),
    'savedAt': savedAt.toIso8601String(),
    'collection': collection,
  };
}

/// Bookmarks stored as a metadata snapshot so they open without a network.
class BookmarksController extends Notifier<List<Bookmark>> {
  static const _key = 'bookmarks.v1';

  @override
  List<Bookmark> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List<dynamic>) return const [];
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) Bookmark.fromJson(e),
      ];
    } on Object {
      return const [];
    }
  }

  bool contains(String key) => state.any((b) => b.artwork.key == key);

  /// Adds or removes the artwork. Returns true if it is now bookmarked.
  bool toggle(Artwork artwork) {
    if (contains(artwork.key)) {
      _save(state.where((b) => b.artwork.key != artwork.key).toList());
      return false;
    }
    _save([Bookmark(artwork: artwork, savedAt: DateTime.now()), ...state]);
    return true;
  }

  void restore(Bookmark bookmark) {
    if (contains(bookmark.artwork.key)) return;
    final list = [...state, bookmark]
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _save(list);
  }

  void setCollection(String key, String? collection) => _save([
    for (final b in state)
      if (b.artwork.key == key) b.withCollection(collection) else b,
  ]);

  void _save(List<Bookmark> list) {
    state = list;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode([for (final b in list) b.toJson()]));
  }
}

final bookmarksProvider = NotifierProvider<BookmarksController, List<Bookmark>>(
  BookmarksController.new,
);

final isBookmarkedProvider = Provider.family<bool, String>(
  (ref, key) => ref.watch(bookmarksProvider).any((b) => b.artwork.key == key),
);
