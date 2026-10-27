import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/features/bookmarks/bookmarks_controller.dart';
import 'package:codedbykay_art_explorer/features/history/history_controller.dart';
import 'package:codedbykay_art_explorer/features/search/paged_search.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Future<void> _settle(ProviderContainer c, SearchQuery q) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
    final s = c.read(pagedSearchProvider(q));
    if (!s.isLoading) return;
  }
}

void main() {
  group('PagedSearchController', () {
    const query = SearchQuery(text: 'monet');

    test('loads first page then appends the next by cursor', () async {
      final source = FakeArtSource(
        pages: [
          Ok(
            SearchPage(
              items: [sampleArtwork(1), sampleArtwork(2)],
              total: 3,
              nextCursor: 'c2',
            ),
          ),
          Ok(SearchPage(items: [sampleArtwork(2), sampleArtwork(3)], total: 3)),
        ],
      );
      final c = await makeContainer(source: source);
      c.listen(pagedSearchProvider(query), (_, _) {});
      await _settle(c, query);

      var s = c.read(pagedSearchProvider(query));
      expect(s.items, hasLength(2));
      expect(s.hasMore, isTrue);

      await c.read(pagedSearchProvider(query).notifier).loadMore();
      s = c.read(pagedSearchProvider(query));
      expect(s.items.map((a) => a.id), [
        '/test/item_1',
        '/test/item_2',
        '/test/item_3',
      ]);
      expect(s.hasMore, isFalse);
      expect(source.queries.last.cursor, 'c2');
    });

    test('reports an error and retries successfully', () async {
      final source = FakeArtSource(
        pages: [
          const Err(NetworkFailure()),
          Ok(SearchPage(items: [sampleArtwork()], total: 1)),
        ],
      );
      final c = await makeContainer(source: source);
      c.listen(pagedSearchProvider(query), (_, _) {});
      await _settle(c, query);
      expect(c.read(pagedSearchProvider(query)).error, isA<NetworkFailure>());

      await c.read(pagedSearchProvider(query).notifier).retry();
      final s = c.read(pagedSearchProvider(query));
      expect(s.error, isNull);
      expect(s.items, hasLength(1));
    });

    test('empty result is flagged', () async {
      final source = FakeArtSource(
        pages: [const Ok(SearchPage(items: [], total: 0))],
      );
      final c = await makeContainer(source: source);
      c.listen(pagedSearchProvider(query), (_, _) {});
      await _settle(c, query);
      expect(c.read(pagedSearchProvider(query)).isEmpty, isTrue);
    });
  });

  group('BookmarksController', () {
    test('toggle adds, removes and persists', () async {
      final c = await makeContainer();
      final ctrl = c.read(bookmarksProvider.notifier);
      final a = sampleArtwork();

      expect(ctrl.toggle(a), isTrue);
      expect(c.read(isBookmarkedProvider(a.key)), isTrue);

      // A fresh container reading the same prefs sees the bookmark.
      final prefs = c.read(bookmarksProvider);
      expect(prefs.single.artwork.title, a.title);

      expect(ctrl.toggle(a), isFalse);
      expect(c.read(bookmarksProvider), isEmpty);
    });

    test(
      'restore puts a removed bookmark back and collections stick',
      () async {
        final c = await makeContainer();
        final ctrl = c.read(bookmarksProvider.notifier)
          ..toggle(sampleArtwork());
        ctrl.setCollection(sampleArtwork().key, 'Favourites');
        final saved = c.read(bookmarksProvider).single;
        expect(saved.collection, 'Favourites');

        ctrl.toggle(sampleArtwork());
        expect(c.read(bookmarksProvider), isEmpty);
        ctrl.restore(saved);
        expect(c.read(bookmarksProvider).single.collection, 'Favourites');
      },
    );

    test('survives corrupt stored data', () async {
      final c = await makeContainer(prefs: {'bookmarks.v1': 'not json'});
      expect(c.read(bookmarksProvider), isEmpty);
    });
  });

  group('History', () {
    test('keeps most recent first without duplicates', () async {
      final c = await makeContainer();
      final h = c.read(historyProvider.notifier)
        ..add(sampleArtwork(1))
        ..add(sampleArtwork(2))
        ..add(sampleArtwork(1));
      expect(c.read(historyProvider).map((a) => a.id), [
        '/test/item_1',
        '/test/item_2',
      ]);
      h.clear();
      expect(c.read(historyProvider), isEmpty);
    });

    test('recent searches dedupe case-insensitively', () async {
      final c = await makeContainer();
      c.read(recentSearchesProvider.notifier)
        ..add('Monet')
        ..add('monet')
        ..add('  ');
      expect(c.read(recentSearchesProvider), ['monet']);
    });
  });

  group('Reader preferences', () {
    test('defaults, update and persistence', () async {
      final c = await makeContainer();
      expect(c.read(readerPrefsProvider).theme, ReaderTheme.paper);

      c
          .read(readerPrefsProvider.notifier)
          .update(
            c
                .read(readerPrefsProvider)
                .copyWith(theme: ReaderTheme.night, fontSize: 24),
          );
      final p = c.read(readerPrefsProvider);
      expect(p.theme, ReaderTheme.night);
      expect(p.fontSize, 24);

      final restored = await makeContainer(
        prefs: {'reader.theme': 'sepia', 'reader.size': 99.0},
      );
      expect(restored.read(readerPrefsProvider).theme, ReaderTheme.sepia);
      expect(
        restored.read(readerPrefsProvider).fontSize,
        ReaderPrefs.maxFontSize,
      );
    });

    test('language persists and null follows the system', () async {
      final c = await makeContainer();
      expect(c.read(localeProvider), isNull);
      c.read(localeProvider.notifier).set(const Locale('sv'));
      expect(c.read(localeProvider), const Locale('sv'));
      expect(c.read(dataLanguageProvider), 'sv');
      c.read(localeProvider.notifier).set(null);
      expect(c.read(localeProvider), isNull);
    });

    test('theme mode persists', () async {
      final c = await makeContainer();
      c.read(themeModeProvider.notifier).set(ThemeMode.dark);
      expect(c.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
