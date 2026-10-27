import 'package:codedbykay_art_explorer/app/app.dart';
import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        artSourcesProvider.overrideWithValue([FakeArtSource()]),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: const ArtExplorerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

bool _searchFieldFocused(WidgetTester tester) {
  final field = tester.widget<EditableText>(find.byType(EditableText));
  return field.focusNode.hasFocus;
}

void main() {
  testWidgets('a single tap on Search only switches tab', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(_searchFieldFocused(tester), isFalse);
  });

  testWidgets('a double tap on Search switches and focuses the field', (
    tester,
  ) async {
    await _pumpApp(tester);
    final tab = find.text('Search').last;

    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(tab);
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(_searchFieldFocused(tester), isTrue);
  });

  testWidgets('two slow taps do not count as a double tap', (tester) async {
    await _pumpApp(tester);
    final tab = find.text('Search').last;

    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(tab);
    await tester.pumpAndSettle();

    expect(_searchFieldFocused(tester), isFalse);
  });
}
