import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/core/text_utils.dart';
import 'package:codedbykay_art_explorer/core/widgets/art_image.dart';
import 'package:codedbykay_art_explorer/core/widgets/artwork_card.dart';
import 'package:codedbykay_art_explorer/core/widgets/state_views.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_providers.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_sequence.dart';
import 'package:codedbykay_art_explorer/features/bookmarks/bookmarks_controller.dart';
import 'package:codedbykay_art_explorer/features/history/history_controller.dart';
import 'package:codedbykay_art_explorer/features/search/paged_search.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternal(BuildContext context, String? url) async {
  final uri = url == null ? null : Uri.tryParse(url);
  // Only ever open https links from remote data.
  if (uri == null || uri.scheme != 'https') return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenLink)));
  }
}

String shareText(Artwork a) => [
  a.title,
  if (a.creators.isNotEmpty) 'by ${a.creators.join(', ')}',
  if (a.provider != null) 'Provided by ${a.provider} via Europeana',
  rightsLabel(a.rightsUrl),
  if (a.landingUrl != null) a.landingUrl!,
].join('\n');

class ArtworkScreen extends ConsumerStatefulWidget {
  const ArtworkScreen({
    required this.source,
    required this.id,
    this.preview,
    this.sequence,
    super.key,
  });

  final String source;
  final String id;

  /// Metadata already known from the list, shown while the record loads.
  final Artwork? preview;

  /// The list this artwork was opened from; null hides stepping.
  final ArtworkSequence? sequence;

  @override
  ConsumerState<ArtworkScreen> createState() => _ArtworkScreenState();
}

class _ArtworkScreenState extends ConsumerState<ArtworkScreen> {
  @override
  void initState() {
    super.initState();
    final preview = widget.preview;
    if (preview != null) {
      Future.microtask(() => ref.read(historyProvider.notifier).add(preview));
    }
    // Keep paged results a few steps ahead of the reader.
    Future.microtask(() {
      final query = widget.sequence?.query;
      if (!mounted || query == null) return;
      final state = ref.read(pagedSearchProvider(query));
      final i = _indexIn(state.items);
      if (i >= 0 && i >= state.items.length - 3 && state.hasMore) {
        ref.read(pagedSearchProvider(query).notifier).loadMore();
      }
    });
  }

  /// Swipes faster than this (logical px/s) step to the neighbour.
  static const _swipeVelocity = 300.0;

  int _indexIn(List<Artwork> items) =>
      items.indexWhere((a) => a.sourceId == widget.source && a.id == widget.id);

  List<Artwork> _siblings() {
    final sequence = widget.sequence;
    if (sequence == null) return const [];
    final query = sequence.query;
    return query == null
        ? sequence.items
        : ref.watch(pagedSearchProvider(query)).items;
  }

  /// Replaces this screen with the neighbour so Back still returns to the list.
  void _step(List<Artwork> siblings, int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= siblings.length) return;
    final next = siblings[target];
    context.pushReplacement(
      artworkLocation(next),
      extra: ArtworkOpenArgs(next, sequence: widget.sequence, direction: delta),
    );
  }

  void _onSwipe(DragEndDetails d, List<Artwork> siblings, int index) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < _swipeVelocity) return;
    // Swiping left (negative velocity) reveals the next artwork.
    _step(siblings, index, v < 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      artworkDetailProvider((source: widget.source, id: widget.id)),
    );
    final detail = detailAsync.value?.valueOrNull;
    final artwork = detail?.artwork ?? widget.preview;

    if (artwork == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detailAsync.when(
          data: (r) => r.when(
            ok: (_) => const SizedBox.shrink(),
            err: (f) => ErrorView(
              failure: f,
              onRetry: () => ref.invalidate(
                artworkDetailProvider((source: widget.source, id: widget.id)),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const ErrorView(failure: UnknownFailure()),
        ),
      );
    }

    // Prefer richer record data but keep the list thumbnail for the hero.
    final shown = Artwork(
      id: artwork.id,
      sourceId: artwork.sourceId,
      title: artwork.title,
      creators: artwork.creators.isNotEmpty
          ? artwork.creators
          : widget.preview?.creators ?? const [],
      date: artwork.date ?? widget.preview?.date,
      thumbnailUrl: widget.preview?.thumbnailUrl ?? artwork.thumbnailUrl,
      imageUrl: artwork.imageUrl ?? widget.preview?.imageUrl,
      provider: artwork.provider ?? widget.preview?.provider,
      rightsUrl: artwork.rightsUrl ?? widget.preview?.rightsUrl,
      landingUrl: artwork.landingUrl ?? widget.preview?.landingUrl,
      type: artwork.type,
    );
    final saved = ref.watch(isBookmarkedProvider(shown.key));
    final theme = Theme.of(context);
    final siblings = _siblings();
    final index = _indexIn(siblings);
    final hasPrevious = index > 0;
    final hasNext = index >= 0 && index < siblings.length - 1;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: index < 0
            ? null
            : (d) => _onSwipe(d, siblings, index),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              // The image can be any colour, so the bar and its icons stay
              // dark/light regardless of the app theme.
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              expandedHeight: MediaQuery.sizeOf(context).height * 0.45,
              actions: [
                IconButton(
                  tooltip: saved
                      ? context.l10n.removeBookmark
                      : context.l10n.bookmark,
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () {
                    final added = ref
                        .read(bookmarksProvider.notifier)
                        .toggle(shown);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            added
                                ? context.l10n.savedToBookmarks
                                : context.l10n.removedBookmark,
                          ),
                        ),
                      );
                  },
                ),
                IconButton(
                  tooltip: context.l10n.share,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: shareText(shown)),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: () => context.push('/viewer', extra: shown),
                  child: Semantics(
                    button: true,
                    label: context.l10n.openFullScreen(shown.title),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'art-${shown.key}',
                          child: ArtImage(
                            url: shown.thumbnailUrl ?? shown.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Scrim so the status bar and app bar icons stay legible.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        if (hasPrevious)
                          _StepButton(
                            alignment: Alignment.centerLeft,
                            icon: Icons.chevron_left,
                            tooltip: context.l10n.previousArtwork,
                            onPressed: () => _step(siblings, index, -1),
                          ),
                        if (hasNext)
                          _StepButton(
                            alignment: Alignment.centerRight,
                            icon: Icons.chevron_right,
                            tooltip: context.l10n.nextArtwork,
                            onPressed: () => _step(siblings, index, 1),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  Text(shown.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  for (final creator in shown.creators)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        icon: const Icon(Icons.person_outline),
                        label: Text(creator),
                        onPressed: () => context.push(
                          Uri(
                            path: '/creator',
                            queryParameters: {'name': creator},
                          ).toString(),
                        ),
                      ),
                    ),
                  if (shown.date != null)
                    Text(shown.date!, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.push(
                          '/reader',
                          extra: (artwork: shown, detail: detail),
                        ),
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: Text(context.l10n.read),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/viewer', extra: shown),
                        icon: const Icon(Icons.zoom_out_map),
                        label: Text(context.l10n.view),
                      ),
                      if (shown.landingUrl != null)
                        OutlinedButton.icon(
                          onPressed: () =>
                              openExternal(context, shown.landingUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(context.l10n.source),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (detailAsync.isLoading && detail == null)
                    const LinearProgressIndicator()
                  else if (detail != null)
                    _DetailBody(detail: detail)
                  else
                    _DetailError(
                      onRetry: () => ref.invalidate(
                        artworkDetailProvider((
                          source: widget.source,
                          id: widget.id,
                        )),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _Attribution(artwork: shown),
                  const SizedBox(height: 24),
                  _Related(artwork: shown),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round chevron on the edge of the hero image that steps to a neighbour.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black45,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
      ),
    ),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(context.l10n.couldNotLoadDetails)),
      TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
    ],
  );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final ArtworkDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String)>[
      if (detail.mediums.isNotEmpty)
        (context.l10n.medium, detail.mediums.join(', ')),
      if (detail.dimensions.isNotEmpty)
        (context.l10n.dimensions, detail.dimensions.join(', ')),
      if (detail.places.isNotEmpty)
        (context.l10n.place, detail.places.join(', ')),
      if (detail.country != null) (context.l10n.country, detail.country!),
    ];
    final description = detail.descriptions.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          _Description(description: description),
          const SizedBox(height: 16),
        ],
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        if (detail.subjects.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in detail.subjects.take(12))
                ActionChip(
                  label: Text(s),
                  onPressed: () => context.push(
                    Uri(
                      path: '/collection',
                      queryParameters: {'title': s, 'query': s},
                    ).toString(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The main description, with an on-tap machine translation when it is not in
/// the app language.
class _Description extends ConsumerStatefulWidget {
  const _Description({required this.description});

  final LocalizedText description;

  @override
  ConsumerState<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends ConsumerState<_Description> {
  String? _translated;
  bool _showTranslation = false;
  bool _loading = false;

  Future<void> _translate(String from, String to) async {
    if (_translated != null) {
      setState(() => _showTranslation = true);
      return;
    }
    setState(() => _loading = true);
    try {
      final text = await ref
          .read(translatorProvider)
          .translate(widget.description.text, from: from, to: to);
      if (!mounted) return;
      setState(() {
        _translated = text;
        _showTranslation = true;
      });
    } on Object catch (e, st) {
      debugPrint('Translation $from>$to failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.translationFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = ref.watch(dataLanguageProvider);
    final from = widget.description.lang;
    final canTranslate =
        from != null && ref.watch(translatorProvider).supports(from, target);
    final shown = _showTranslation
        ? _translated ?? widget.description.text
        : widget.description.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shown,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge,
        ),
        if (canTranslate)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (_loading)
                  TextButton.icon(
                    onPressed: null,
                    icon: const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text(context.l10n.translating),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _showTranslation
                        ? setState(() => _showTranslation = false)
                        : _translate(from, target),
                    icon: const Icon(Icons.translate),
                    label: Text(
                      _showTranslation
                          ? context.l10n.showOriginal
                          : context.l10n.translate,
                    ),
                  ),
                if (_showTranslation)
                  Text(
                    context.l10n.machineTranslated,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.rightsAttribution,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (artwork.provider != null)
              Text(context.l10n.providedBy(artwork.provider!)),
            InkWell(
              onTap: artwork.rightsUrl == null
                  ? null
                  : () => openExternal(context, artwork.rightsUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  rightsLabel(artwork.rightsUrl),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "More like this": works by the same creator, else by subject.
class _Related extends ConsumerWidget {
  const _Related({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = artwork.creators.firstOrNull;
    final query = SearchQuery(
      text: creator == null ? artwork.title : '',
      filters: SearchFilters(creator: creator),
      rows: 12,
    );
    final state = ref.watch(pagedSearchProvider(query));
    final items = state.items.where((a) => a.key != artwork.key).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.moreLikeThis, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 140,
              child: ArtworkCard(
                artwork: items[i],
                width: 140,
                sequence: ArtworkSequence.items(items),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
