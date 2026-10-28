import 'dart:math';

import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/core/widgets/art_image.dart';
import 'package:codedbykay_art_explorer/core/widgets/artwork_card.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_sequence.dart';
import 'package:codedbykay_art_explorer/features/explore/browse.dart';
import 'package:codedbykay_art_explorer/features/explore/explore_data.dart';
import 'package:codedbykay_art_explorer/features/history/history_controller.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

typedef TopicQuery = ({String? concept, int start, int rows});

/// A single offset page for a subject (offset paging, max 1000 deep).
final topicRowProvider = FutureProvider.family<Result<SearchPage>, TopicQuery>(
  (ref, q) => ref
      .watch(primarySourceProvider)
      .search(
        SearchQuery(
          start: q.start,
          rows: q.rows,
          filters: SearchFilters(openLicenseOnly: true, concept: q.concept),
        ),
      ),
);

void openCollection(
  BuildContext context, {
  required String title,
  String query = '',
  int? yearFrom,
  int? yearTo,
  String? country,
  String? concept,
  String? museum,
  String? colour,
}) => context.push(
  Uri(
    path: '/collection',
    queryParameters: {
      'title': title,
      if (query.isNotEmpty) 'query': query,
      'yearFrom': ?yearFrom?.toString(),
      'yearTo': ?yearTo?.toString(),
      'country': ?country,
      'concept': ?concept,
      'museum': ?museum,
      'colour': ?colour,
    },
  ).toString(),
);

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

/// Subjects the API reports; seeds the daily pick and "surprise me".
final _subjectsProvider = Provider<List<FacetValue>>(
  (ref) =>
      ref.watch(facetProvider(FacetType.concept)).value?.valueOrNull ??
      const [],
);

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _random = Random();
  bool _surprising = false;

  Future<void> _surprise() async {
    if (_surprising) return;
    setState(() => _surprising = true);
    final subjects = ref.read(_subjectsProvider);
    final subject = subjects.isEmpty
        ? null
        : subjects[_random.nextInt(subjects.length)];
    final result = await ref
        .read(primarySourceProvider)
        .search(
          SearchQuery(
            start: pickOffset(
              _random.nextInt(1 << 20),
              subject?.count ?? 1000,
              cap: 400,
            ),
            rows: 1,
            filters: SearchFilters(concept: subject?.value),
          ),
        );
    if (!mounted) return;
    setState(() => _surprising = false);
    final artwork = result.valueOrNull?.items.firstOrNull;
    if (artwork != null) {
      openArtwork(context, artwork);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.surpriseFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final theme = Theme.of(context);
    final subjects = ref.watch(_subjectsProvider);
    final waiting = ref.watch(facetProvider(FacetType.concept)).isLoading;
    final today = subjects.isEmpty
        ? null
        : subjects[dayOfYearSeed(DateTime.now()) % subjects.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.discoverTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.surpriseMe,
            icon: _surprising
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.casino_outlined),
            onPressed: _surprise,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ArtworkOfTheDay(subject: today, waiting: waiting),
          if (history.isNotEmpty)
            _Section(
              title: context.l10n.pickUp,
              child: _ArtRow(artworks: history.take(12).toList()),
            ),
          if (today != null) _TopicRow(subject: today),
          const BrowseSection(type: FacetType.concept),
          const BrowseSection(type: FacetType.period),
          const BrowseSection(type: FacetType.country),
          const BrowseSection(type: FacetType.museum),
          const BrowseSection(type: FacetType.colour),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.exploreFooter,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _ArtRow extends StatelessWidget {
  const _ArtRow({required this.artworks});

  final List<Artwork> artworks;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: artworks.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => SizedBox(
        width: 150,
        child: ArtworkCard(
          artwork: artworks[i],
          width: 150,
          sequence: ArtworkSequence.items(artworks),
        ),
      ),
    ),
  );
}

/// Horizontal row of works for a topic, with loading and retry handling.
class _TopicRow extends ConsumerWidget {
  const _TopicRow({required this.subject});

  final FacetValue subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = (
      concept: subject.value,
      start: pickOffset(dayOfYearSeed(DateTime.now()) * 7 + 1, subject.count),
      rows: 12,
    );
    final async = ref.watch(topicRowProvider(q));
    return _Section(
      title: context.l10n.moreTopic(subject.label),
      child: async.when(
        data: (r) => r.when(
          ok: (page) => page.items.isEmpty
              ? const SizedBox.shrink()
              : _ArtRow(artworks: page.items),
          err: (f) => _RowError(
            message: failureText(context.l10n, f),
            onRetry: () => ref.invalidate(topicRowProvider(q)),
          ),
        ),
        loading: () => const SizedBox(
          height: 190,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _RowError(
          message: 'Could not load',
          onRetry: () => ref.invalidate(topicRowProvider(q)),
        ),
      ),
    );
  }
}

class _RowError extends StatelessWidget {
  const _RowError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(message)),
      TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
    ],
  );
}

/// One featured work, stable for the whole day.
class _ArtworkOfTheDay extends ConsumerWidget {
  const _ArtworkOfTheDay({required this.subject, required this.waiting});

  final FacetValue? subject;
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = (
      concept: subject?.value,
      start: pickOffset(dayOfYearSeed(DateTime.now()), subject?.count ?? 1000),
      rows: 1,
    );
    // Wait for the subject list so the pick does not change after loading.
    final async = waiting
        ? const AsyncLoading<Result<SearchPage>>()
        : ref.watch(topicRowProvider(q));
    final artwork = async.value?.valueOrNull?.items.firstOrNull;
    final theme = Theme.of(context);
    if (artwork == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: async.isLoading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => ref.invalidate(topicRowProvider(q)),
                      child: Text(context.l10n.retryArtworkOfTheDay),
                    ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        button: true,
        label:
            '${context.l10n.artworkOfTheDay}: ${artworkSemanticLabel(artwork)}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: InkWell(
              onTap: () => openArtwork(context, artwork),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'art-${artwork.key}',
                    child: ArtImage(url: artwork.thumbnailUrl),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.artworkOfTheDay.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          artwork.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (artwork.creators.isNotEmpty)
                          Text(
                            artwork.creators.first,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
