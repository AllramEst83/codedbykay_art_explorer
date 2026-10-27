import 'package:codedbykay_art_explorer/core/widgets/artwork_card.dart';
import 'package:codedbykay_art_explorer/core/widgets/state_views.dart';
import 'package:codedbykay_art_explorer/features/search/paged_search.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';

int gridColumns(double width) => width >= 900
    ? 4
    : width >= 600
    ? 3
    : 2;

/// Infinite-scrolling artwork grid with loading, empty and error states.
class PagedArtworkView extends StatefulWidget {
  const PagedArtworkView({
    required this.state,
    required this.onLoadMore,
    required this.onRetry,
    this.headerSlivers = const [],
    this.emptyTitle,
    this.emptySubtitle,
    super.key,
  });

  final PagedState state;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final List<Widget> headerSlivers;
  final String? emptyTitle;
  final String? emptySubtitle;

  @override
  State<PagedArtworkView> createState() => _PagedArtworkViewState();
}

class _PagedArtworkViewState extends State<PagedArtworkView> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final s = widget.state;
    if (!_controller.hasClients || s.isLoading || !s.hasMore) return;
    final pos = _controller.position;
    if (pos.pixels > pos.maxScrollExtent - 600) widget.onLoadMore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final width = MediaQuery.sizeOf(context).width;
    final columns = gridColumns(width);
    final tileWidth = (width - 16 * 2 - 12 * (columns - 1)) / columns;

    final Widget body;
    if (s.items.isEmpty && s.error != null) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(failure: s.error!, onRetry: widget.onRetry),
      );
    } else if (s.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          icon: Icons.image_search,
          title: widget.emptyTitle ?? context.l10n.noArtworkFound,
          subtitle: widget.emptySubtitle ?? context.l10n.noArtworkFoundHint,
        ),
      );
    } else if (s.items.isEmpty) {
      body = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.builder(
          gridDelegate: _delegate(columns),
          itemCount: columns * 4,
          itemBuilder: (_, _) => const _SkeletonTile(),
        ),
      );
    } else {
      body = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.builder(
          gridDelegate: _delegate(columns),
          itemCount: s.items.length,
          itemBuilder: (_, i) =>
              ArtworkCard(artwork: s.items[i], width: tileWidth),
        ),
      );
    }

    return CustomScrollView(
      controller: _controller,
      slivers: [
        ...widget.headerSlivers,
        body,
        if (s.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: s.isLoading
                    ? const CircularProgressIndicator()
                    : s.error != null
                    ? FilledButton.tonalIcon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh),
                        label: Text(failureText(context.l10n, s.error!)),
                      )
                    : s.hasMore
                    ? const SizedBox.shrink()
                    : Text(
                        context.l10n.endOfResults,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  SliverGridDelegate _delegate(int columns) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      );
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
