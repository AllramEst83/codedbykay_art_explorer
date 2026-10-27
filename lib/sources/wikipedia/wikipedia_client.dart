import 'package:dio/dio.dart';

class WikipediaSummary {
  const WikipediaSummary({
    required this.extract,
    this.description,
    this.imageUrl,
    this.pageUrl,
  });

  final String extract;
  final String? description;
  final String? imageUrl;
  final String? pageUrl;
}

/// Looks up a short biography on English Wikipedia (no key required).
class WikipediaClient {
  WikipediaClient(this._dio, {this.lang = 'en'});

  final Dio _dio;
  final String lang;

  Future<WikipediaSummary?> summary(String name) async {
    try {
      final search = await _dio.get<Map<String, dynamic>>(
        'https://$lang.wikipedia.org/w/rest.php/v1/search/title',
        queryParameters: {'q': name, 'limit': 1},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final pages = search.data?['pages'];
      if (pages is! List<dynamic> || pages.isEmpty) return null;
      final first = pages.first;
      final key = first is Map<String, dynamic> ? first['key'] : null;
      if (key is! String) return null;

      final response = await _dio.get<Map<String, dynamic>>(
        'https://$lang.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(key)}',
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final data = response.data;
      if (data == null || data['type'] != 'standard') return null;
      final extract = data['extract'];
      if (extract is! String || extract.isEmpty) return null;
      final thumb = data['thumbnail'];
      final urls = data['content_urls'];
      final mobile = urls is Map<String, dynamic> ? urls['mobile'] : null;
      return WikipediaSummary(
        extract: extract,
        description: data['description'] as String?,
        imageUrl: thumb is Map<String, dynamic>
            ? thumb['source'] as String?
            : null,
        pageUrl: mobile is Map<String, dynamic>
            ? mobile['page'] as String?
            : null,
      );
    } on Object {
      return null;
    }
  }
}
