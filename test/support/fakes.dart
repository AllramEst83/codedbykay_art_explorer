import 'dart:convert';
import 'dart:io';

import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/europeana/$name').readAsStringSync())
        as Map<String, dynamic>;

Artwork sampleArtwork([int n = 1]) => Artwork(
  id: '/test/item_$n',
  sourceId: 'europeana',
  title: 'Water Lilies $n',
  creators: const ['Claude Monet'],
  provider: 'Test Museum',
  rightsUrl: 'http://creativecommons.org/licenses/by-sa/4.0/',
);

class FakeArtSource implements ArtSource {
  FakeArtSource({
    this.pages = const [],
    this.detail,
    this.creator,
    this.facets = const {},
  });

  final List<Result<SearchPage>> pages;
  final ArtworkDetail? detail;
  final CreatorProfile? creator;
  final Map<FacetType, List<FacetValue>> facets;
  final List<SearchQuery> queries = [];
  int _call = 0;

  @override
  String get id => 'europeana';

  @override
  String get displayName => 'Fake';

  @override
  Future<Result<SearchPage>> search(SearchQuery query) async {
    queries.add(query);
    if (pages.isEmpty) return const Err(UnknownFailure());
    final i = _call < pages.length ? _call : pages.length - 1;
    _call++;
    return pages[i];
  }

  @override
  Future<Result<ArtworkDetail>> getArtwork(String id) async =>
      detail == null ? const Err(NotFoundFailure()) : Ok(detail!);

  @override
  Future<Result<List<FacetValue>>> facet(FacetType type) async =>
      facets.containsKey(type)
      ? Ok(facets[type]!)
      : const Err(NetworkFailure());

  @override
  Future<Result<CreatorProfile>> getCreator(String name) async =>
      creator == null ? const Err(NotFoundFailure()) : Ok(creator!);
}

Future<ProviderContainer> makeContainer({
  FakeArtSource? source,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      if (source != null) artSourcesProvider.overrideWithValue([source]),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
