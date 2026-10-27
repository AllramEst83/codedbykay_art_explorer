import 'package:codedbykay_art_explorer/app/shell_scaffold.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_screen.dart';
import 'package:codedbykay_art_explorer/features/artwork/creator_screen.dart';
import 'package:codedbykay_art_explorer/features/artwork/viewer_screen.dart';
import 'package:codedbykay_art_explorer/features/bookmarks/bookmarks_screen.dart';
import 'package:codedbykay_art_explorer/features/explore/collection_screen.dart';
import 'package:codedbykay_art_explorer/features/explore/explore_screen.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_screen.dart';
import 'package:codedbykay_art_explorer/features/search/search_screen.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_screen.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app router. Detail routes sit above the tab shell so the
/// bottom bar is hidden on them.
GoRouter buildRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ExploreScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookmarks',
              builder: (_, _) => const BookmarksScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/artwork',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        return ArtworkScreen(
          // A new key per artwork so pushing another artwork resets state.
          key: ValueKey(state.uri.toString()),
          source: state.uri.queryParameters['source'] ?? 'europeana',
          id: state.uri.queryParameters['id'] ?? '',
          preview: extra is Artwork ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/viewer',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (_, state) => state.extra is Artwork ? null : '/',
      builder: (_, state) => ViewerScreen(artwork: state.extra! as Artwork),
    ),
    GoRoute(
      path: '/reader',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (_, state) => state.extra is ReaderArgs ? null : '/',
      builder: (_, state) => ReaderScreen(args: state.extra! as ReaderArgs),
    ),
    GoRoute(
      path: '/creator',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, state) =>
          CreatorScreen(name: state.uri.queryParameters['name'] ?? ''),
    ),
    GoRoute(
      path: '/collection',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, state) {
        final q = state.uri.queryParameters;
        return CollectionScreen(
          title: q['title'] ?? 'Collection',
          query: SearchQuery(
            text: q['query'] ?? '',
            filters: SearchFilters(
              yearFrom: int.tryParse(q['yearFrom'] ?? ''),
              yearTo: int.tryParse(q['yearTo'] ?? ''),
              country: q['country'],
            ),
          ),
        );
      },
    ),
  ],
);
