import 'package:codedbykay_art_explorer/core/text_utils.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';

const europeanaSourceId = 'europeana';

/// Maps Europeana JSON to domain models. Every field is optional and may be
/// a string, a list or a language map, so all access is defensive.
abstract final class EuropeanaMapper {
  /// Thumbnail API URL with a requested width (w200 or w400).
  static String? sizedThumbnail(String? url, {int width = 400}) {
    if (url == null || url.isEmpty) return null;
    final w = width <= 200 ? 'w200' : 'w400';
    return url.contains('size=') ? url : '$url&size=$w';
  }

  static SearchPage searchPage(
    Map<String, dynamic> json, {
    String lang = 'en',
  }) {
    final items = <Artwork>[];
    final raw = json['items'];
    if (raw is List<dynamic>) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final artwork = searchItem(item, lang: lang);
          if (artwork != null) items.add(artwork);
        }
      }
    }
    return SearchPage(
      items: items,
      total: (json['totalResults'] as num?)?.toInt() ?? items.length,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  static Artwork? searchItem(Map<String, dynamic> item, {String lang = 'en'}) {
    final id = item['id'];
    if (id is! String) return null;
    final title =
        _first(pickLocalized(item['dcTitleLangAware'], lang: lang)) ??
        _first(_list(item['title'])) ??
        'Untitled';
    final shownBy = _first(_list(item['edmIsShownBy']));
    final preview = _first(_list(item['edmPreview']));
    return Artwork(
      id: id,
      sourceId: europeanaSourceId,
      title: stripHtml(title),
      creators: {
        for (final c in _list(item['dcCreator']))
          if (!c.startsWith('http')) cleanCreatorName(c),
      }.toList(),
      date: _first(_list(item['year'])),
      thumbnailUrl: sizedThumbnail(preview),
      imageUrl: shownBy,
      provider: _first(_list(item['dataProvider'])),
      rightsUrl: _first(_list(item['rights'])),
      landingUrl:
          _first(_list(item['edmIsShownAt'])) ?? item['guid'] as String?,
      type: item['type'] as String? ?? 'IMAGE',
    );
  }

  static ArtworkDetail? record(
    Map<String, dynamic> json, {
    String lang = 'en',
  }) {
    final object = json['object'];
    if (object is! Map<String, dynamic>) return null;

    final lookup = _EntityLookup(object, lang);
    final proxies = [
      for (final p in _maps(object['proxies']))
        if (p['europeanaProxy'] != true) p,
    ];
    final aggregation = _maps(object['aggregations']).firstOrNull ?? const {};
    final europeanaAgg = object['europeanaAggregation'];

    List<String> field(String key) =>
        _dedupe([for (final p in proxies) ...lookup.resolve(p[key])]);

    final aboutId = object['about'];
    final id = aboutId is String ? aboutId : null;
    if (id == null) return null;

    final shownBy = aggregation['edmIsShownBy'];
    final shownAt = aggregation['edmIsShownAt'];
    final rights = pickLocalized(aggregation['edmRights']).firstOrNull;
    final preview = europeanaAgg is Map<String, dynamic>
        ? europeanaAgg['edmPreview']
        : null;

    final title = field('dcTitle').firstOrNull ?? 'Untitled';
    final dates = [
      ...field('dctermsCreated'),
      ...field('dcDate'),
    ].map((d) => d.replaceFirst('#', '')).toList();
    final dataProvider = lookup.resolve(aggregation['edmDataProvider']);

    final descriptions = <LocalizedText>[];
    for (final p in proxies) {
      final d = p['dcDescription'];
      if (d is Map<String, dynamic>) {
        for (final entry in d.entries) {
          for (final v in _list(entry.value)) {
            if (v.startsWith('http')) continue;
            descriptions.add(
              LocalizedText(
                stripHtml(v),
                lang: entry.key == 'def' ? null : entry.key,
              ),
            );
          }
        }
      }
    }

    final artwork = Artwork(
      id: id,
      sourceId: europeanaSourceId,
      title: stripHtml(title),
      creators: field('dcCreator').map(cleanCreatorName).toSet().toList(),
      date: dates.firstOrNull,
      thumbnailUrl: sizedThumbnail(preview is String ? preview : null),
      imageUrl: shownBy is String ? shownBy : null,
      provider: dataProvider.firstOrNull,
      rightsUrl: rights,
      landingUrl: shownAt is String ? shownAt : null,
      type:
          _first(_list(object['type'])) ??
          (proxies.isNotEmpty ? proxies.first['edmType'] as String? : null) ??
          'IMAGE',
    );

    return ArtworkDetail(
      artwork: artwork,
      descriptions: _dedupeTexts(descriptions, lang),
      subjects: field('dcSubject'),
      mediums: _dedupe([...field('dctermsMedium'), ...field('dcFormat')]),
      places: _dedupe([
        ...field('dctermsSpatial'),
        ...field('edmCurrentLocation'),
      ]),
      dimensions: field('dctermsExtent'),
      country: _first(
        _list(
          europeanaAgg is Map<String, dynamic>
              ? europeanaAgg['edmCountry']
              : null,
        ),
      ),
    );
  }

  /// Orders descriptions: device language first, then undeclared, then others.
  static List<LocalizedText> _dedupeTexts(
    List<LocalizedText> all,
    String lang,
  ) {
    final seen = <String>{};
    final unique = [
      for (final t in all)
        if (t.text.isNotEmpty && seen.add(t.text)) t,
    ];
    int rank(LocalizedText t) => t.lang == lang
        ? 0
        : t.lang == null
        ? 1
        : t.lang == 'en'
        ? 2
        : 3;
    return unique.toList()..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  static List<String> _dedupe(Iterable<String> values) {
    final seen = <String>{};
    return [
      for (final v in values)
        if (v.isNotEmpty && seen.add(v.toLowerCase())) stripHtml(v),
    ];
  }

  static String? _first(List<String> values) => values.firstOrNull;

  static List<String> _list(Object? value) => switch (value) {
    final String s when s.isNotEmpty => [s],
    final List<dynamic> l => [
      for (final e in l)
        if (e is String && e.isNotEmpty) e,
    ],
    _ => const [],
  };

  static List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? [
          for (final e in value)
            if (e is Map<String, dynamic>) e,
        ]
      : const [];
}

/// Resolves values that are URIs to contextual entities (agents, concepts,
/// places, timespans, organizations) into their preferred labels.
class _EntityLookup {
  _EntityLookup(Map<String, dynamic> object, this.lang) {
    for (final key in const [
      'agents',
      'concepts',
      'places',
      'timespans',
      'organizations',
    ]) {
      final list = object[key];
      if (list is! List<dynamic>) continue;
      for (final e in list) {
        if (e is Map<String, dynamic> && e['about'] is String) {
          _labels[e['about'] as String] = pickLocalized(
            e['prefLabel'],
            lang: lang,
          );
        }
      }
    }
  }

  final String lang;
  final Map<String, List<String>> _labels = {};

  /// Flattens a language map / list / string into plain labels.
  List<String> resolve(Object? value) {
    final out = <String>[];
    void add(String v) {
      if (v.startsWith('http')) {
        out.addAll(_labels[v]?.take(1) ?? const []);
      } else if (v.trim().isNotEmpty) {
        out.add(v.trim());
      }
    }

    switch (value) {
      case final String s:
        add(s);
      case final List<dynamic> l:
        for (final e in l) {
          if (e is String) add(e);
        }
      case final Map<String, dynamic> m:
        final preferred = pickLocalized(m, lang: lang);
        // Collect every language so untranslated values are not lost.
        final all = preferred.isNotEmpty
            ? preferred
            : [
                for (final v in m.values)
                  if (v is List<dynamic>)
                    for (final e in v)
                      if (e is String) e,
              ];
        all.forEach(add);
      default:
        break;
    }
    return out;
  }
}
