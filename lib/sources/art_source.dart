import 'package:codedbykay_art_explorer/core/result.dart';

/// An art provider (Europeana first). UI only depends on this interface.
abstract interface class ArtSource {
  String get id;
  String get displayName;

  Future<Result<SearchPage>> search(SearchQuery query);
  Future<Result<ArtworkDetail>> getArtwork(String id);
  Future<Result<CreatorProfile>> getCreator(String name);

  /// Live category values (with counts) for browsing, e.g. all countries.
  Future<Result<List<FacetValue>>> facet(FacetType type);
}

/// The ways artwork can be grouped for browsing.
enum FacetType { concept, country, period, museum, colour }

/// One category value. [value] is what a filter needs (a URI, name, year or
/// hex colour); [label] is what people read.
class FacetValue {
  const FacetValue({
    required this.value,
    required this.label,
    required this.count,
  });

  final String value;
  final String label;
  final int count;
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
    this.concept,
    this.museum,
    this.colour,
  });

  final int? yearFrom;
  final int? yearTo;
  final String? country;
  final bool openLicenseOnly;
  final String? creator;

  /// Category filters chosen from Explore. They are fixed by the page that
  /// opened the results, so they are not counted as user-set filters.
  final String? concept;
  final String? museum;
  final String? colour;

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
    String? Function()? concept,
    String? Function()? museum,
    String? Function()? colour,
  }) => SearchFilters(
    yearFrom: yearFrom != null ? yearFrom() : this.yearFrom,
    yearTo: yearTo != null ? yearTo() : this.yearTo,
    country: country != null ? country() : this.country,
    openLicenseOnly: openLicenseOnly ?? this.openLicenseOnly,
    creator: creator != null ? creator() : this.creator,
    concept: concept != null ? concept() : this.concept,
    museum: museum != null ? museum() : this.museum,
    colour: colour != null ? colour() : this.colour,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.yearFrom == yearFrom &&
      other.yearTo == yearTo &&
      other.country == country &&
      other.openLicenseOnly == openLicenseOnly &&
      other.creator == creator &&
      other.concept == concept &&
      other.museum == museum &&
      other.colour == colour;

  @override
  int get hashCode => Object.hash(
    yearFrom,
    yearTo,
    country,
    openLicenseOnly,
    creator,
    concept,
    museum,
    colour,
  );
}

/// How results are ordered. Sources map these to what their API supports.
enum SearchSort { relevance, mostComplete, recentlyAdded }

class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.filters = const SearchFilters(),
    this.sort = SearchSort.relevance,
    this.cursor,
    this.start,
    this.rows = 24,
  });

  final String text;
  final SearchFilters filters;
  final SearchSort sort;

  /// Cursor from the previous [SearchPage]; null for the first page.
  final String? cursor;

  /// Offset paging, used for random picks (cursor ignored when set).
  final int? start;
  final int rows;

  SearchQuery withCursor(String? cursor) => SearchQuery(
    text: text,
    filters: filters,
    sort: sort,
    cursor: cursor,
    rows: rows,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.filters == filters &&
      other.sort == sort &&
      other.cursor == cursor &&
      other.start == start &&
      other.rows == rows;

  @override
  int get hashCode => Object.hash(text, filters, sort, cursor, start, rows);
}

class SearchPage {
  const SearchPage({required this.items, required this.total, this.nextCursor});

  final List<Artwork> items;
  final int total;
  final String? nextCursor;
}
