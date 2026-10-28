import 'package:codedbykay_art_explorer/core/widgets/art_image.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_providers.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_screen.dart';
import 'package:codedbykay_art_explorer/features/search/paged_artwork_view.dart';
import 'package:codedbykay_art_explorer/features/search/paged_search.dart';
import 'package:codedbykay_art_explorer/features/search/sort_button.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creator page: biography on top, their works below.
class CreatorScreen extends ConsumerWidget {
  const CreatorScreen({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(sortProvider('creator:$name'));
    final query = SearchQuery(
      filters: SearchFilters(creator: name),
      sort: sort,
    );
    final works = ref.watch(pagedSearchProvider(query));
    final worksController = ref.read(pagedSearchProvider(query).notifier);
    final profile = ref.watch(creatorProvider(name));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          SortButton(
            value: sort,
            onSelected: ref.read(sortProvider('creator:$name').notifier).choose,
          ),
        ],
      ),
      body: PagedArtworkView(
        state: works,
        onLoadMore: worksController.loadMore,
        onRetry: worksController.retry,
        query: query,
        emptyTitle: context.l10n.noWorksFound,
        emptySubtitle: context.l10n.noWorksFoundHint,
        headerSlivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: profile.when(
                data: (r) => r.when(
                  ok: (p) => _Bio(profile: p),
                  err: (_) => Text(
                    context.l10n.noBiography,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (works.loadedOnce && works.total > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  context.l10n.worksCount(works.total),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bio extends StatelessWidget {
  const _Bio({required this.profile});

  final CreatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: ArtImage(url: profile.imageUrl, memCacheWidth: 264),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: theme.textTheme.titleLarge),
                  if (profile.lifespan != null)
                    Text(profile.lifespan!, style: theme.textTheme.bodyMedium),
                  if (profile.shortDescription != null)
                    Text(
                      profile.shortDescription!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (profile.biography != null) ...[
          const SizedBox(height: 12),
          Text(profile.biography!, style: theme.textTheme.bodyMedium),
        ],
        if (profile.sourceUrl != null)
          TextButton(
            onPressed: () => openExternal(context, profile.sourceUrl),
            child: Text(context.l10n.readMoreWikipedia),
          ),
      ],
    );
  }
}
