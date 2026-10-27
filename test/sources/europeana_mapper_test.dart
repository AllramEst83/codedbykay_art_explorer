import 'package:codedbykay_art_explorer/sources/europeana/europeana_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  group('search mapping', () {
    final page = EuropeanaMapper.searchPage(fixture('search.json'));

    test('maps items, total and cursor', () {
      expect(page.items, hasLength(3));
      expect(page.total, 1295);
      expect(page.nextCursor, isNotNull);
    });

    test('cleans creators and picks the title', () {
      final a = page.items.first;
      expect(a.creators, ['Claude Monet']);
      expect(a.title, 'Monet, Pappeln (Serie), Monet, vier Pappeln');
      expect(a.id, startsWith('/626/'));
      expect(a.key, startsWith('europeana:/626/'));
    });

    test('requests a sized thumbnail and keeps the full image url', () {
      final a = page.items.first;
      expect(a.thumbnailUrl, endsWith('&size=w400'));
      expect(a.imageUrl, contains('download.php'));
      expect(a.rightsUrl, contains('creativecommons'));
    });

    test('skips items without an id and tolerates junk', () {
      final p = EuropeanaMapper.searchPage({
        'items': [
          {'title': 'no id'},
          'junk',
          {
            'id': '/1/a',
            'title': ['ok'],
            'dcCreator': 5,
          },
        ],
      });
      expect(p.items.map((a) => a.id), ['/1/a']);
      expect(p.items.single.creators, isEmpty);
    });
  });

  group('record mapping', () {
    final detail = EuropeanaMapper.record(fixture('record.json'))!;

    test('maps core fields from the provider proxy', () {
      expect(detail.artwork.title, isNotEmpty);
      expect(detail.artwork.creators, ['Claude Monet']);
      expect(detail.artwork.imageUrl, contains('download.php'));
      expect(detail.artwork.provider, isNotNull);
    });

    test('resolves descriptions with language', () {
      expect(detail.descriptions, isNotEmpty);
      expect(detail.descriptions.first.text, contains('Beschriftung'));
    });

    test('strips the leading # from dates', () {
      expect(detail.artwork.date, isNot(startsWith('#')));
    });

    test('returns null for a malformed record', () {
      expect(EuropeanaMapper.record({'object': 5}), isNull);
      expect(EuropeanaMapper.record({}), isNull);
    });
  });
}
