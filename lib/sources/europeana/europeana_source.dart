import 'dart:async';

import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/core/text_utils.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:codedbykay_art_explorer/sources/europeana/europeana_mapper.dart';
import 'package:codedbykay_art_explorer/sources/wikipedia/wikipedia_client.dart';
import 'package:dio/dio.dart';

/// Builds a Dio client for Europeana with the API key header and retries.
Dio buildEuropeanaDio(String apiKey) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.europeana.eu',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'X-Api-Key': apiKey},
    ),
  );
  dio.interceptors.add(RetryInterceptor(dio));
  return dio;
}

/// Retries transient failures (timeouts, 429, 5xx) with exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2});

  final Dio _dio;
  final int maxRetries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['attempt'] as int?) ?? 0;
    final status = err.response?.statusCode;
    final transient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        status == 429 ||
        (status != null && status >= 500);
    if (!transient || attempt >= maxRetries) return handler.next(err);

    await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
    try {
      final options = err.requestOptions..extra['attempt'] = attempt + 1;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

Failure mapDioError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 429) return const RateLimitFailure();
    if (status == 404 || status == 410) return const NotFoundFailure();
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure();
    }
  }
  return const UnknownFailure();
}

class EuropeanaSource implements ArtSource {
  EuropeanaSource(this._dio, {WikipediaClient? wikipedia, this.lang = 'en'})
    : _wikipedia = wikipedia ?? WikipediaClient(Dio());

  final Dio _dio;
  final WikipediaClient _wikipedia;
  final String lang;

  @override
  String get id => europeanaSourceId;

  @override
  String get displayName => 'Europeana';

  @override
  Future<Result<SearchPage>> search(SearchQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/record/v2/search.json',
        queryParameters: buildSearchParams(query),
      );
      final data = response.data;
      if (data == null || data['success'] == false) {
        return const Err(UnknownFailure());
      }
      return Ok(EuropeanaMapper.searchPage(data, lang: lang));
    } on Object catch (e) {
      return Err(mapDioError(e));
    }
  }

  /// Query parameters for the Search API. Public for unit testing.
  static Map<String, dynamic> buildSearchParams(SearchQuery q) {
    final text = q.text.trim();
    final filters = q.filters;
    final qf = <String>[
      'TYPE:IMAGE',
      'MEDIA:true',
      'THUMBNAIL:true',
      if (filters.country != null) 'COUNTRY:"${filters.country}"',
      if (filters.yearFrom != null || filters.yearTo != null)
        'YEAR:[${filters.yearFrom ?? '*'} TO ${filters.yearTo ?? '*'}]',
      if (filters.creator != null) 'who:"${_quote(filters.creator!)}"',
      if (filters.concept != null) 'skos_concept:"${_quote(filters.concept!)}"',
      if (filters.museum != null) 'DATA_PROVIDER:"${_quote(filters.museum!)}"',
      if (filters.colour != null) 'COLOURPALETTE:${filters.colour}',
    ];
    final sort = switch (q.sort) {
      SearchSort.relevance => null,
      SearchSort.mostComplete => 'COMPLETENESS desc',
      SearchSort.recentlyAdded => 'timestamp_created desc',
    };
    return {
      'query': text.isEmpty ? '*' : text,
      'theme': 'art',
      'qf': qf,
      'rows': q.rows,
      'profile': 'standard',
      // europeana_id makes the order stable for cursor paging.
      'sort': ?(sort == null ? null : '$sort,europeana_id asc'),
      if (filters.openLicenseOnly) 'reusability': 'open',
      if (q.start != null) 'start': q.start else 'cursor': q.cursor ?? '*',
    };
  }

  @override
  Future<Result<ArtworkDetail>> getArtwork(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/record/v2$id.json',
      );
      final data = response.data;
      final detail = data == null
          ? null
          : EuropeanaMapper.record(data, lang: lang);
      return detail == null ? const Err(ParseFailure()) : Ok(detail);
    } on Object catch (e) {
      return Err(mapDioError(e));
    }
  }

  static String _quote(String s) => s.replaceAll('"', r'\"');

  static const _facetNames = {
    FacetType.concept: ('skos_concept', 100),
    FacetType.country: ('COUNTRY', 100),
    FacetType.period: ('YEAR', 1000),
    FacetType.museum: ('DATA_PROVIDER', 300),
    FacetType.colour: ('COLOURPALETTE', 100),
  };

  static final _conceptId = RegExp(
    r'^http://data\.europeana\.eu/concept/(\d+)$',
  );

  final Map<String, String> _conceptLabels = {};

  @override
  Future<Result<List<FacetValue>>> facet(FacetType type) async {
    final (name, limit) = _facetNames[type]!;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/record/v2/search.json',
        queryParameters: {
          'query': '*',
          'theme': 'art',
          'qf': ['TYPE:IMAGE', 'MEDIA:true', 'THUMBNAIL:true'],
          'rows': 0,
          'profile': 'facets',
          'facet': name,
          'f.$name.facet.limit': limit,
        },
      );
      final values = parseFacet(response.data);
      if (values == null) return const Err(ParseFailure());
      if (type != FacetType.concept) return Ok(values);
      return await _labelConcepts(values);
    } on Object catch (e) {
      return Err(mapDioError(e));
    }
  }

  /// Reads the first facet of a Search API response. Public for testing.
  static List<FacetValue>? parseFacet(Map<String, dynamic>? json) {
    final facets = json?['facets'];
    if (facets is! List<dynamic> || facets.isEmpty) return null;
    final first = facets.first;
    final fields = first is Map<String, dynamic> ? first['fields'] : null;
    if (fields is! List<dynamic>) return null;
    return [
      for (final f in fields)
        if (f is Map<String, dynamic> &&
            f['label'] is String &&
            f['count'] is num &&
            (f['label'] as String).isNotEmpty)
          FacetValue(
            value: f['label'] as String,
            label: f['label'] as String,
            count: (f['count'] as num).toInt(),
          ),
    ];
  }

  /// Facet values for concepts are URIs; resolve them to names in the app
  /// language. Concepts hosted elsewhere (e.g. Getty) cannot be named here
  /// and are left out.
  Future<Result<List<FacetValue>>> _labelConcepts(
    List<FacetValue> values,
  ) async {
    final candidates = [
      for (final v in values)
        if (_conceptId.hasMatch(v.value)) v,
    ];
    const batch = 8;
    for (var i = 0; i < candidates.length; i += batch) {
      await Future.wait([
        for (final v in candidates.skip(i).take(batch))
          _resolveConcept(v.value),
      ]);
    }
    final seen = <String>{};
    final labelled = [
      for (final v in candidates)
        if (_conceptLabels[_labelKey(v.value)] case final label?)
          if (seen.add(label.toLowerCase()))
            FacetValue(value: v.value, label: label, count: v.count),
    ];
    if (candidates.isNotEmpty && labelled.isEmpty) {
      return const Err(UnknownFailure());
    }
    return Ok(labelled);
  }

  String _labelKey(String uri) => '$lang:$uri';

  Future<void> _resolveConcept(String uri) async {
    final key = _labelKey(uri);
    if (_conceptLabels.containsKey(key)) return;
    final id = _conceptId.firstMatch(uri)?.group(1);
    if (id == null) return;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/entity/concept/base/$id.json',
      );
      final label = pickLocalized(
        response.data?['prefLabel'],
        lang: lang,
      ).firstOrNull;
      if (label != null) _conceptLabels[key] = label;
    } on Object {
      // Leave unlabelled; the value is simply not shown.
    }
  }

  @override
  Future<Result<CreatorProfile>> getCreator(String name) async {
    final clean = cleanCreatorName(name);
    if (isAnonymousCreator(clean)) return const Err(NotFoundFailure());

    final results = await Future.wait([
      _entity(clean),
      _wikipedia.summary(clean),
    ]);
    final entity = results[0] as _Entity?;
    final wiki = results[1] as WikipediaSummary?;
    if (entity == null && wiki == null) return const Err(NotFoundFailure());

    return Ok(
      CreatorProfile(
        name: clean,
        shortDescription: entity?.note ?? wiki?.description,
        born: entity?.born,
        died: entity?.died,
        biography: wiki?.extract,
        imageUrl: wiki?.imageUrl ?? entity?.imageUrl,
        sourceUrl: wiki?.pageUrl,
      ),
    );
  }

  Future<_Entity?> _entity(String name) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/entity/search',
        queryParameters: {
          'query': name,
          'type': 'agent',
          'pageSize': 3,
          'language': lang,
        },
      );
      final items = response.data?['items'];
      if (items is! List<dynamic>) return null;
      final wanted = _norm(name);
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final labels = [
          ...pickLocalized(item['prefLabel'], lang: lang),
          ...pickLocalized(item['altLabel'], lang: lang),
        ].map(_norm);
        if (!labels.contains(wanted)) continue;
        final shownBy = item['isShownBy'];
        return _Entity(
          note: pickLocalized(item['note'], lang: lang).firstOrNull,
          born: _year(item['dateOfBirth']),
          died: _year(item['dateOfDeath']),
          imageUrl: shownBy is Map<String, dynamic>
              ? shownBy['thumbnail'] as String?
              : null,
        );
      }
    } on Object {
      return null;
    }
    return null;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9À-￿]'), '');

  static String? _year(Object? value) {
    final first = value is List<dynamic> && value.isNotEmpty
        ? value.first
        : value;
    if (first is! String) return null;
    return RegExp(r'^-?\d{1,4}').firstMatch(first)?.group(0);
  }
}

class _Entity {
  const _Entity({this.note, this.born, this.died, this.imageUrl});
  final String? note;
  final String? born;
  final String? died;
  final String? imageUrl;
}
