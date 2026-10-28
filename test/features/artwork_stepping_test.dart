import 'dart:async';

import 'package:codedbykay_art_explorer/app/router.dart';
import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/widgets/artwork_card.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_sequence.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

Future<GoRouter> _open(WidgetTester tester, int start) async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  final items = [for (var i = 1; i <= 3; i++) sampleArtwork(i)];
  final router = buildRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        artSourcesProvider.overrideWithValue([FakeArtSource()]),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final artwork = items[start];
  unawaited(
    router.push(
      artworkLocation(artwork),
      extra: ArtworkOpenArgs(artwork, sequence: ArtworkSequence.items(items)),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('buttons step between artworks and hide at the ends', (
    tester,
  ) async {
    await _open(tester, 0);
    expect(find.text('Water Lilies 1'), findsOneWidget);
    expect(find.byTooltip('Previous artwork'), findsNothing);

    await tester.tap(find.byTooltip('Next artwork'));
    await tester.pumpAndSettle();
    expect(find.text('Water Lilies 2'), findsOneWidget);
    expect(find.byTooltip('Previous artwork'), findsOneWidget);

    await tester.tap(find.byTooltip('Next artwork'));
    await tester.pumpAndSettle();
    expect(find.text('Water Lilies 3'), findsOneWidget);
    expect(find.byTooltip('Next artwork'), findsNothing);
  });

  testWidgets('swiping left goes to the next, right to the previous', (
    tester,
  ) async {
    await _open(tester, 1);
    await tester.fling(
      find.text('Water Lilies 2'),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Water Lilies 3'), findsOneWidget);

    await tester.fling(find.text('Water Lilies 3'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Water Lilies 2'), findsOneWidget);
  });

  testWidgets('Back after stepping returns to the list, not the last step', (
    tester,
  ) async {
    final router = await _open(tester, 0);
    await tester.tap(find.byTooltip('Next artwork'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Water Lilies 2'), findsNothing);
    expect(find.text('Water Lilies 1'), findsNothing);
  });
}
