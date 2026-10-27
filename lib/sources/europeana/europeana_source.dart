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
      if (filters.creator != null) 'who:"${filters.creator}"',
    ];
    return {
      'query': text.isEmpty ? '*' : text,
      'theme': 'art',
      'qf': qf,
      'rows': q.rows,
      'profile': 'standard',
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
