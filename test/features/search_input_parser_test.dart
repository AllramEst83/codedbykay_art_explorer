import 'package:codedbykay_art_explorer/features/explore/collection_screen.dart';
import 'package:codedbykay_art_explorer/features/search/search_input_parser.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedSearch _p(String s) => parseSearchInput(s, maxYear: 2026);

void main() {
  group('parseSearchInput', () {
    test('plain text is left alone', () {
      final r = _p('van gogh sunflowers');
      expect(r.text, 'van gogh sunflowers');
      expect(r.yearFrom, isNull);
      expect(r.country, isNull);
    });

    test('century like 1800s', () {
      final r = _p('cubism 1900s');
      expect((r.text, r.yearFrom, r.yearTo), ('cubism', 1900, 1999));
    });

    test('decade like 1850s', () {
      final r = _p('1850s landscape');
      expect((r.text, r.yearFrom, r.yearTo), ('landscape', 1850, 1859));
    });

    test('range, in either direction and with an en dash', () {
      expect(_p('portrait 1850-1900').yearFrom, 1850);
      expect(_p('portrait 1850-1900').yearTo, 1900);
      final r = _p('portrait 1900–1850');
      expect((r.yearFrom, r.yearTo), (1850, 1900));
      expect(r.text, 'portrait');
    });

    test('single year', () {
      final r = _p('monet 1888');
      expect((r.text, r.yearFrom, r.yearTo), ('monet', 1888, 1888));
    });

    test('ordinal century and Swedish -talet', () {
      final a = _p('19th century portrait');
      expect((a.text, a.yearFrom, a.yearTo), ('portrait', 1800, 1899));
      final b = _p('1700-talet');
      expect((b.yearFrom, b.yearTo), (1700, 1799));
    });

    test('country, in any position and case', () {
      final r = _p('cubism FRANCE 1900s');
      expect(r.country, 'France');
      expect(r.text, 'cubism');
      expect(_p('Netherlands landscape').country, 'Netherlands');
      expect(_p('uk portrait').country, 'United Kingdom');
    });

    test('does not match inside other words or invalid years', () {
      expect(_p('Spaniard').country, isNull);
      expect(_p('Sweden').text, '');
      expect(_p('3000').yearFrom, isNull);
      expect(_p('1855x').yearFrom, isNull);
    });
  });

  group('mergeParsed', () {
    test('parsed values override, others are kept', () {
      const base = SearchFilters(country: 'Italy', openLicenseOnly: true);
      final merged = mergeParsed(base, _p('1800s'));
      expect(merged.country, 'Italy');
      expect(merged.openLicenseOnly, isTrue);
      expect((merged.yearFrom, merged.yearTo), (1800, 1899));
      expect(mergeParsed(base, _p('france')).country, 'France');
    });
  });

  group('combineQuery', () {
    const cubism = SearchQuery(text: 'cubism');

    test('adds typed words to the category query', () {
      final q = combineQuery(
        cubism,
        text: 'picasso',
        filters: const SearchFilters(),
      );
      expect(q.text, 'cubism picasso');
    });

    test('typed year and country become filters', () {
      final q = combineQuery(
        cubism,
        text: 'paris 1900s france',
        filters: const SearchFilters(),
      );
      expect(q.text, 'cubism paris');
      expect(q.filters.country, 'France');
      expect((q.filters.yearFrom, q.filters.yearTo), (1900, 1999));
    });

    test('keeps the category filters unless the user overrides them', () {
      const century = SearchQuery(
        filters: SearchFilters(yearFrom: 1800, yearTo: 1899),
      );
      final kept = combineQuery(
        century,
        text: 'landscape',
        filters: const SearchFilters(country: 'France'),
      );
      expect((kept.filters.yearFrom, kept.filters.country), (1800, 'France'));

      final overridden = combineQuery(
        century,
        text: '1850-1870',
        filters: const SearchFilters(),
      );
      expect(
        (overridden.filters.yearFrom, overridden.filters.yearTo),
        (1850, 1870),
      );
    });
  });
}
