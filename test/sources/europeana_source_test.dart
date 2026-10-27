import 'dart:convert';
import 'dart:typed_data';

import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:codedbykay_art_explorer/sources/europeana/europeana_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final ResponseBody Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

EuropeanaSource _source(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.europeana.eu'))
    ..httpClientAdapter = adapter;
  return EuropeanaSource(dio);
}

void main() {
  group('buildSearchParams', () {
    test('defaults to art images with media, first cursor page', () {
      final p = EuropeanaSource.buildSearchParams(const SearchQuery());
      expect(p['query'], '*');
      expect(p['theme'], 'art');
      expect(p['cursor'], '*');
      expect(
        p['qf'],
        containsAll(['TYPE:IMAGE', 'MEDIA:true', 'THUMBNAIL:true']),
      );
      expect(p.containsKey('reusability'), isFalse);
    });

    test('applies filters', () {
      final p = EuropeanaSource.buildSearchParams(
        const SearchQuery(
          text: 'monet',
          filters: SearchFilters(
            yearFrom: 1800,
            yearTo: 1900,
            country: 'France',
            openLicenseOnly: true,
            creator: 'Claude Monet',
          ),
          cursor: 'abc',
        ),
      );
      expect(p['query'], 'monet');
      expect(p['cursor'], 'abc');
      expect(p['reusability'], 'open');
      expect(p['qf'], contains('YEAR:[1800 TO 1900]'));
      expect(p['qf'], contains('COUNTRY:"France"'));
      expect(p['qf'], contains('who:"Claude Monet"'));
    });

    test('offset paging replaces the cursor', () {
      final p = EuropeanaSource.buildSearchParams(
        const SearchQuery(start: 40, rows: 1),
      );
      expect(p['start'], 40);
      expect(p.containsKey('cursor'), isFalse);
    });
  });

  group('EuropeanaSource', () {
    test('search maps the fixture response', () async {
      final adapter = _Adapter((_) => _json(fixture('search.json')));
      final result = await _source(adapter)
          .search(const SearchQuery(text: 'monet'));
      final page = (result as Ok<SearchPage>).value;
      expect(page.items, hasLength(3));
      expect(adapter.requests.single.path, '/record/v2/search.json');
    });

    test('getArtwork requests the record path from the id', () async {
      final adapter = _Adapter((_) => _json(fixture('record.json')));
      final result = await _source(adapter).getArtwork('/626/item_X');
      expect(result, isA<Ok<ArtworkDetail>>());
      expect(adapter.requests.single.path, '/record/v2/626/item_X.json');
    });

    test('404 becomes NotFoundFailure', () async {
      final adapter = _Adapter((_) => _json({'success': false}, 404));
      final result = await _source(adapter).getArtwork('/x/y');
      expect((result as Err<ArtworkDetail>).failure, isA<NotFoundFailure>());
    });

    test('getCreator combines entity data and skips anonymous', () async {
      final adapter = _Adapter((o) {
        if (o.uri.host.contains('wikipedia')) return _json({}, 404);
        return _json(fixture('entity_search.json'));
      });
      final src = _source(adapter);
      final ok = await src.getCreator('Monet, Claude (1840-1926)');
      final profile = (ok as Ok<CreatorProfile>).value;
      expect(profile.name, 'Claude Monet');
      expect(profile.born, '1840');
      expect(profile.died, '1926');
      expect(profile.shortDescription, startsWith('French painter'));

      final anon = await src.getCreator('Unknown');
      expect((anon as Err<CreatorProfile>).failure, isA<NotFoundFailure>());
    });
  });
}
