import 'package:codedbykay_art_explorer/features/search/paged_artwork_view.dart';
import 'package:codedbykay_art_explorer/features/search/paged_search.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paged results for a topic, century, country or creator.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({required this.title, required this.query, super.key});

  final String title;
  final SearchQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pagedSearchProvider(query));
    final controller = ref.read(pagedSearchProvider(query).notifier);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PagedArtworkView(
        state: state,
        onLoadMore: controller.loadMore,
        onRetry: controller.retry,
        headerSlivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                state.loadedOnce && state.total > 0
                    ? context.l10n.worksCount(state.total)
                    : '',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
