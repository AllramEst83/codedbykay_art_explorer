import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:codedbykay_art_explorer/sources/europeana/europeana_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sort params', () {
    test('relevance sends no sort', () {
      final p = EuropeanaSource.buildSearchParams(const SearchQuery());
      expect(p.containsKey('sort'), isFalse);
    });

    test('each sort maps to a Europeana field with a stable tiebreaker', () {
      String? sortOf(SearchSort s) =>
          EuropeanaSource.buildSearchParams(SearchQuery(sort: s))['sort']
              as String?;
      expect(
        sortOf(SearchSort.mostComplete),
        'COMPLETENESS desc,europeana_id asc',
      );
      expect(
        sortOf(SearchSort.recentlyAdded),
        'timestamp_created desc,europeana_id asc',
      );
    });

    test('the sort survives paging', () {
      final q = const SearchQuery(sort: SearchSort.recentlyAdded)
          .withCursor('c');
      expect(q.sort, SearchSort.recentlyAdded);
    });

    test('different sorts are different queries', () {
      expect(
        const SearchQuery(sort: SearchSort.recentlyAdded),
        isNot(const SearchQuery()),
      );
    });
  });
}
