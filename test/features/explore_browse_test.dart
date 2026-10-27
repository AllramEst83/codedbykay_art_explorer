import 'package:codedbykay_art_explorer/app/app.dart';
import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

FacetValue _v(String value, String label, int count) =>
    FacetValue(value: value, label: label, count: count);

FakeArtSource _source() => FakeArtSource(
  facets: {
    FacetType.concept: [
      _v('http://data.europeana.eu/concept/106', 'Portrait', 120),
      _v('http://data.europeana.eu/concept/35', 'Drawing', 90),
    ],
    FacetType.country: [
      _v('France', 'France', 500),
      _v('Sweden', 'Sweden', 300),
    ],
    FacetType.museum: [_v('Rijksmuseum', 'Rijksmuseum', 340000)],
    FacetType.colour: [
      _v('#FF0000', '#FF0000', 10),
      _v('#0000FF', '#0000FF', 9),
    ],
    FacetType.period: [
      _v('1850', '1850', 100),
      _v('1860', '1860', 50),
      _v('1910', '1910', 70),
    ],
  },
);

Future<FakeArtSource> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final source = _source();
  // Tall enough that the lazy Explore list builds every section.
  tester.view.physicalSize = const Size(1080, 9000);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        artSourcesProvider.overrideWithValue([source]),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: const ArtExplorerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return source;
}

void main() {
  testWidgets('Explore shows live categories from the API', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Subjects & techniques'), findsOneWidget);
    expect(find.text('Portrait'), findsOneWidget);
    expect(find.text('Drawing'), findsOneWidget);
    expect(find.text('Time periods'), findsOneWidget);
    // Years roll up into centuries.
    expect(find.text('1800s'), findsOneWidget);
    expect(find.text('1900s'), findsOneWidget);
    expect(find.text('France'), findsOneWidget);
    expect(find.text('Rijksmuseum'), findsOneWidget);
    expect(find.text('Colours'), findsOneWidget);
  });

  testWidgets('tapping a subject opens results filtered by that concept', (
    tester,
  ) async {
    final source = await _pumpApp(tester);

    await tester.tap(find.text('Portrait'));
    await tester.pumpAndSettle();

    expect(find.text('Search in Portrait'), findsOneWidget);
    expect(
      source.queries.last.filters.concept,
      'http://data.europeana.eu/concept/106',
    );
  });

  testWidgets('a century chip opens its year range', (tester) async {
    final source = await _pumpApp(tester);

    await tester.tap(find.text('1800s'));
    await tester.pumpAndSettle();

    final f = source.queries.last.filters;
    expect((f.yearFrom, f.yearTo), (1800, 1899));
  });

  testWidgets('See all lists every value and can be filtered', (tester) async {
    final source = await _pumpApp(tester);

    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();

    expect(find.text('Subjects & techniques'), findsOneWidget);
    expect(find.text('120 works'), findsOneWidget);
    expect(find.text('90 works'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'draw');
    await tester.pumpAndSettle();
    expect(find.text('Portrait'), findsNothing);
    expect(find.text('Drawing'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'draw');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drawing'));
    await tester.pumpAndSettle();
    expect(
      source.queries.last.filters.concept,
      'http://data.europeana.eu/concept/35',
    );
  });

  testWidgets('a museum and a colour filter results', (tester) async {
    final source = await _pumpApp(tester);

    await tester.tap(find.text('Rijksmuseum'));
    await tester.pumpAndSettle();
    expect(source.queries.last.filters.museum, 'Rijksmuseum');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Colour #FF0000').first);
    await tester.pumpAndSettle();
    expect(source.queries.last.filters.colour, '#FF0000');
  });

  testWidgets('section titles follow the app language', (tester) async {
    await _pumpApp(tester, prefs: {'app.locale': 'sv'});
    expect(find.text('Motiv och tekniker'), findsOneWidget);
    expect(find.text('Museer och samlingar'), findsOneWidget);
    expect(find.text('1800-talet'), findsOneWidget);
  });
}
