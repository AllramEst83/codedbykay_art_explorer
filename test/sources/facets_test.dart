import 'dart:convert';
import 'dart:typed_data';

import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/features/explore/browse.dart';
import 'package:codedbykay_art_explorer/features/explore/collection_screen.dart';
import 'package:codedbykay_art_explorer/features/explore/explore_data.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:codedbykay_art_explorer/sources/europeana/europeana_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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

Map<String, Object> _facetBody(String name, List<(String, int)> fields) => {
  'success': true,
  'facets': [
    {
      'name': name,
      'fields': [
        for (final (label, count) in fields) {'label': label, 'count': count},
      ],
    },
  ],
};

EuropeanaSource _source(_Adapter a, {String lang = 'en'}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.europeana.eu'))
    ..httpClientAdapter = a;
  return EuropeanaSource(dio, lang: lang);
}

void main() {
  group('facet loading', () {
    test('requests the right facet with art filters', () async {
      final a = _Adapter(
        (_) => _json(_facetBody('COUNTRY', [('France', 10), ('Sweden', 5)])),
      );
      final result = await _source(a).facet(FacetType.country);
      final values = (result as Ok<List<FacetValue>>).value;

      expect(values.map((v) => (v.label, v.count)), [
        ('France', 10),
        ('Sweden', 5),
      ]);
      final q = a.requests.single.queryParameters;
      expect(q['facet'], 'COUNTRY');
      expect(q['theme'], 'art');
      expect(q['rows'], 0);
      expect(q['f.COUNTRY.facet.limit'], 100);
    });

    test('museums and colours use their facet names', () async {
      final a = _Adapter((_) => _json(_facetBody('x', [('a', 1)])));
      final src = _source(a);
      await src.facet(FacetType.museum);
      await src.facet(FacetType.colour);
      await src.facet(FacetType.period);
      expect(a.requests.map((r) => r.queryParameters['facet']), [
        'DATA_PROVIDER',
        'COLOURPALETTE',
        'YEAR',
      ]);
    });

    test(
      'concept URIs become names, others are dropped, duplicates merged',
      () async {
        final a = _Adapter((o) {
          if (o.path.startsWith('/entity/concept/base/')) {
            final id = o.path.split('/').last.replaceAll('.json', '');
            final labels = {
              '106': {'en': 'Portrait', 'sv': 'Porträtt'},
              '107': {'sv': 'Porträtt'}, // same name as 106
              '35': {'en': 'Drawing', 'sv': 'Teckning'},
            };
            return labels.containsKey(id)
                ? _json({'prefLabel': labels[id]})
                : _json({}, 404);
          }
          return _json(
            _facetBody('skos_concept', [
              ('http://data.europeana.eu/concept/106', 300),
              ('http://vocab.getty.edu/aat/300041273', 200),
              ('http://data.europeana.eu/concept/107', 150),
              ('http://data.europeana.eu/concept/35', 100),
              ('http://data.europeana.eu/concept/999', 50), // unresolvable
            ]),
          );
        });
        final result = await _source(a, lang: 'sv').facet(FacetType.concept);
        final values = (result as Ok<List<FacetValue>>).value;

        expect(values.map((v) => v.label), ['Porträtt', 'Teckning']);
        expect(values.first.value, 'http://data.europeana.eu/concept/106');
        expect(values.first.count, 300);
      },
    );

    test('labels are cached per language', () async {
      final a = _Adapter((o) {
        if (o.path.startsWith('/entity/')) {
          return _json({
            'prefLabel': {'en': 'Print'},
          });
        }
        return _json(
          _facetBody('skos_concept', [
            ('http://data.europeana.eu/concept/1', 5),
          ]),
        );
      });
      final src = _source(a);
      await src.facet(FacetType.concept);
      await src.facet(FacetType.concept);
      final entityCalls = a.requests.where(
        (r) => r.path.startsWith('/entity/'),
      );
      expect(entityCalls, hasLength(1));
    });

    test(
      'a malformed response is a ParseFailure, an outage a failure',
      () async {
        final bad = await _source(_Adapter((_) => _json({'success': true})))
            .facet(FacetType.country);
        expect((bad as Err<List<FacetValue>>).failure, isA<ParseFailure>());

        final down = await _source(_Adapter((_) => _json({}, 404)))
            .facet(FacetType.country);
        expect(down, isA<Err<List<FacetValue>>>());
      },
    );
  });

  group('search params for category filters', () {
    test('concept, museum and colour become qf filters', () {
      final p = EuropeanaSource.buildSearchParams(
        const SearchQuery(
          filters: SearchFilters(
            concept: 'http://data.europeana.eu/concept/106',
            museum: 'Rijksmuseum',
            colour: '#696969',
          ),
        ),
      );
      expect(
        p['qf'],
        contains('skos_concept:"http://data.europeana.eu/concept/106"'),
      );
      expect(p['qf'], contains('DATA_PROVIDER:"Rijksmuseum"'));
      expect(p['qf'], contains('COLOURPALETTE:#696969'));
    });

    test('quotes in names are escaped', () {
      final p = EuropeanaSource.buildSearchParams(
        const SearchQuery(filters: SearchFilters(museum: 'The "Best" Museum')),
      );
      expect(p['qf'], contains(r'DATA_PROVIDER:"The \"Best\" Museum"'));
    });

    test('category filters survive combining with typed text', () {
      final q = combineQuery(
        const SearchQuery(
          filters: SearchFilters(concept: 'c', museum: 'm', colour: '#000000'),
        ),
        text: 'monet 1800s',
        filters: const SearchFilters(),
      );
      expect(
        (q.filters.concept, q.filters.museum, q.filters.colour),
        ('c', 'm', '#000000'),
      );
      expect(q.filters.yearFrom, 1800);
      expect(q.text, 'monet');
    });
  });

  group('groupPeriods', () {
    List<FacetValue> years(Map<int, int> m) => [
      for (final e in m.entries)
        FacetValue(value: '${e.key}', label: '${e.key}', count: e.value),
    ];

    test('rolls years into decades and centuries, oldest first', () {
      final p = groupPeriods(
        years({1855: 10, 1851: 5, 1899: 1, 1900: 7, 1801: 2}),
        maxYear: 2026,
      );
      expect(p.map((c) => (c.from, c.to, c.count)), [
        (1800, 1899, 18),
        (1900, 1999, 7),
      ]);
      expect(p.first.decades.map((d) => (d.from, d.count)), [
        (1800, 2),
        (1850, 15),
        (1890, 1),
      ]);
    });

    test('ignores impossible years and junk', () {
      final p = groupPeriods([
        ...years({999: 5, 3000: 5, 1500: 1}),
        const FacetValue(value: 'unknown', label: 'unknown', count: 9),
      ], maxYear: 2026);
      expect(p.map((c) => (c.from, c.count)), [(1500, 1)]);
    });
  });

  group('colours', () {
    test('parseHexColor', () {
      expect(parseHexColor('#FF0000')?.toARGB32(), 0xFFFF0000);
      expect(parseHexColor('red'), isNull);
      expect(parseHexColor('#FFF'), isNull);
    });

    test('sortColours puts greys first and skips malformed values', () {
      FacetValue v(String hex) => FacetValue(value: hex, label: hex, count: 1);
      final sorted = sortColours([
        v('#0000FF'),
        v('#FF0000'),
        v('#C0C0C0'),
        v('nonsense'),
        v('#808080'),
      ]);
      expect(sorted.map((e) => e.value), [
        '#808080',
        '#C0C0C0',
        '#FF0000',
        '#0000FF',
      ]);
    });
  });
}
