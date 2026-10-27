import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_document.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_screen.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_settings_sheet.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations_en.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

const _detail = ArtworkDetail(
  artwork: Artwork(
    id: '/test/item_1',
    sourceId: 'europeana',
    title: 'Water Lilies',
    creators: ['Claude Monet'],
    provider: 'Test Museum',
  ),
  descriptions: [LocalizedText('A pond covered in lilies.')],
  subjects: ['pond', 'flowers'],
  mediums: ['oil on canvas'],
);

const _profile = CreatorProfile(
  name: 'Claude Monet',
  born: '1840',
  died: '1926',
  shortDescription: 'French painter',
  biography: 'Monet founded Impressionism.',
);

Future<ProviderContainer> _pumpReader(
  WidgetTester tester, {
  FakeArtSource? source,
  Locale locale = const Locale('en'),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = source ?? FakeArtSource(detail: _detail, creator: _profile);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      artSourcesProvider.overrideWithValue([fake]),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReaderScreen(args: (artwork: _detail.artwork, detail: _detail)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('ReaderDocument', () {
    test('combines facts, description, artist and subjects', () {
      final doc = ReaderDocument.build(
        l10n: AppLocalizationsEn(),
        artwork: _detail.artwork,
        detail: _detail,
        creator: _profile,
      );
      expect(doc.sections.map((s) => s.heading), [
        'About this work',
        'About the artist',
        'Subjects',
      ]);
      expect(doc.hasContent, isTrue);
      expect(doc.spokenText, contains('A pond covered in lilies.'));
      expect(doc.spokenText, contains('Impressionism'));
    });

    test('labels descriptions in other languages', () {
      final doc = ReaderDocument.build(
        l10n: AppLocalizationsEn(),
        artwork: _detail.artwork,
        detail: const ArtworkDetail(
          artwork: Artwork(id: '/1/a', sourceId: 'europeana', title: 'T'),
          descriptions: [LocalizedText('Beschriftung', lang: 'de')],
        ),
      );
      expect(doc.sections.first.paragraphs.last, startsWith('[de] '));
    });

    test('works with no detail at all', () {
      final doc = ReaderDocument.build(
        artwork: _detail.artwork,
        l10n: AppLocalizationsEn(),
      );
      expect(doc.title, 'Water Lilies');
      expect(doc.sections, hasLength(1));
    });
  });

  group('Reader screen', () {
    testWidgets('renders Swedish section headings', (tester) async {
      await _pumpReader(tester, locale: const Locale('sv'));
      expect(find.text('Om verket'), findsOneWidget);
      expect(find.text('Om konstnären'), findsOneWidget);
      expect(find.byTooltip('Läsinställningar'), findsOneWidget);
    });

    testWidgets('shows the assembled text on the paper theme', (tester) async {
      await _pumpReader(tester);
      expect(find.text('Water Lilies'), findsOneWidget);
      expect(find.text('A pond covered in lilies.'), findsOneWidget);
      expect(
        find.textContaining('Monet founded Impressionism'),
        findsOneWidget,
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, ReaderTheme.paper.background);
    });

    testWidgets('settings sheet switches background and font size', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _pumpReader(tester);
      await tester.tap(find.byTooltip('Reading settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderSettingsSheet), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Night background'));
      await tester.pumpAndSettle();
      expect(container.read(readerPrefsProvider).theme, ReaderTheme.night);

      final before = container.read(readerPrefsProvider).fontSize;
      await tester.drag(find.byType(Slider).first, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(container.read(readerPrefsProvider).fontSize, greaterThan(before));

      await tester.tap(find.text(ReaderFont.inter.label));
      await tester.pumpAndSettle();
      expect(container.read(readerPrefsProvider).font, ReaderFont.inter);
      semantics.dispose();
    });
  });
}
