import 'package:codedbykay_art_explorer/core/result.dart';

/// An art provider (Europeana first). UI only depends on this interface.
abstract interface class ArtSource {
  String get id;
  String get displayName;

  Future<Result<SearchPage>> search(SearchQuery query);
  Future<Result<ArtworkDetail>> getArtwork(String id);
  Future<Result<CreatorProfile>> getCreator(String name);
}

class Artwork {
  const Artwork({
    required this.id,
    required this.sourceId,
    required this.title,
    this.creators = const [],
    this.date,
    this.thumbnailUrl,
    this.imageUrl,
    this.provider,
    this.rightsUrl,
    this.landingUrl,
    this.type = 'IMAGE',
  });

  factory Artwork.fromJson(Map<String, dynamic> json) => Artwork(
    id: json['id'] as String,
    sourceId: json['sourceId'] as String,
    title: json['title'] as String,
    creators: [
      for (final c in (json['creators'] as List<dynamic>? ?? const []))
        if (c is String) c,
    ],
    date: json['date'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    imageUrl: json['imageUrl'] as String?,
    provider: json['provider'] as String?,
    rightsUrl: json['rightsUrl'] as String?,
    landingUrl: json['landingUrl'] as String?,
    type: json['type'] as String? ?? 'IMAGE',
  );

  final String id;
  final String sourceId;
  final String title;
  final List<String> creators;
  final String? date;
  final String? thumbnailUrl;
  final String? imageUrl;
  final String? provider;
  final String? rightsUrl;
  final String? landingUrl;
  final String type;

  /// Stable key across sources, used for bookmarks and hero tags.
  String get key => '$sourceId:$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'title': title,
    'creators': creators,
    'date': date,
    'thumbnailUrl': thumbnailUrl,
    'imageUrl': imageUrl,
    'provider': provider,
    'rightsUrl': rightsUrl,
    'landingUrl': landingUrl,
    'type': type,
  };
}

class LocalizedText {
  const LocalizedText(this.text, {this.lang});
  final String text;
  final String? lang;
}

class ArtworkDetail {
  const ArtworkDetail({
    required this.artwork,
    this.descriptions = const [],
    this.subjects = const [],
    this.mediums = const [],
    this.places = const [],
    this.dimensions = const [],
    this.country,
  });

  final Artwork artwork;
  final List<LocalizedText> descriptions;
  final List<String> subjects;
  final List<String> mediums;
  final List<String> places;
  final List<String> dimensions;
  final String? country;
}

class CreatorProfile {
  const CreatorProfile({
    required this.name,
    this.shortDescription,
    this.born,
    this.died,
    this.biography,
    this.imageUrl,
    this.sourceUrl,
  });

  final String name;
  final String? shortDescription;
  final String? born;
  final String? died;
  final String? biography;
  final String? imageUrl;
  final String? sourceUrl;

  String? get lifespan {
    if (born == null && died == null) return null;
    return '${born ?? '?'} – ${died ?? ''}'.trim();
  }
}

class SearchFilters {
  const SearchFilters({
    this.yearFrom,
    this.yearTo,
    this.country,
    this.openLicenseOnly = false,
    this.creator,
  });

  final int? yearFrom;
  final int? yearTo;
  final String? country;
  final bool openLicenseOnly;
  final String? creator;

  bool get isActive => activeCount > 0;

  int get activeCount =>
      (yearFrom != null || yearTo != null ? 1 : 0) +
      (country != null ? 1 : 0) +
      (openLicenseOnly ? 1 : 0) +
      (creator != null ? 1 : 0);

  SearchFilters copyWith({
    int? Function()? yearFrom,
    int? Function()? yearTo,
    String? Function()? country,
    bool? openLicenseOnly,
    String? Function()? creator,
  }) => SearchFilters(
    yearFrom: yearFrom != null ? yearFrom() : this.yearFrom,
    yearTo: yearTo != null ? yearTo() : this.yearTo,
    country: country != null ? country() : this.country,
    openLicenseOnly: openLicenseOnly ?? this.openLicenseOnly,
    creator: creator != null ? creator() : this.creator,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.yearFrom == yearFrom &&
      other.yearTo == yearTo &&
      other.country == country &&
      other.openLicenseOnly == openLicenseOnly &&
      other.creator == creator;

  @override
  int get hashCode =>
      Object.hash(yearFrom, yearTo, country, openLicenseOnly, creator);
}

class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.filters = const SearchFilters(),
    this.cursor,
    this.start,
    this.rows = 24,
  });

  final String text;
  final SearchFilters filters;

  /// Cursor from the previous [SearchPage]; null for the first page.
  final String? cursor;

  /// Offset paging, used for random picks (cursor ignored when set).
  final int? start;
  final int rows;

  SearchQuery withCursor(String? cursor) =>
      SearchQuery(text: text, filters: filters, cursor: cursor, rows: rows);

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.filters == filters &&
      other.cursor == cursor &&
      other.start == start &&
      other.rows == rows;

  @override
  int get hashCode => Object.hash(text, filters, cursor, start, rows);
}

class SearchPage {
  const SearchPage({required this.items, required this.total, this.nextCursor});

  final List<Artwork> items;
  final int total;
  final String? nextCursor;
}
