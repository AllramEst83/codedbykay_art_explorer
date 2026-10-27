import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PagedState {
  const PagedState({
    this.items = const [],
    this.total = 0,
    this.nextCursor,
    this.isLoading = false,
    this.error,
    this.loadedOnce = false,
  });

  final List<Artwork> items;
  final int total;
  final String? nextCursor;
  final bool isLoading;
  final Failure? error;
  final bool loadedOnce;

  bool get hasMore => nextCursor != null;
  bool get isEmpty => loadedOnce && items.isEmpty && error == null;

  PagedState copyWith({
    List<Artwork>? items,
    int? total,
    String? Function()? nextCursor,
    bool? isLoading,
    Failure? Function()? error,
    bool? loadedOnce,
  }) => PagedState(
    items: items ?? this.items,
    total: total ?? this.total,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    isLoading: isLoading ?? this.isLoading,
    error: error != null ? error() : this.error,
    loadedOnce: loadedOnce ?? this.loadedOnce,
  );
}

/// Cursor-paged results for one [SearchQuery]. Used by search, category and
/// creator pages. Stale responses are dropped via a generation counter.
class PagedSearchController extends Notifier<PagedState> {
  PagedSearchController(this.query);

  final SearchQuery query;
  int _generation = 0;

  @override
  PagedState build() {
    ref.onDispose(() => _generation++);
    Future.microtask(loadMore);
    return const PagedState(isLoading: true);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.loadedOnce && !current.hasMore && current.error == null) return;
    if (current.loadedOnce && current.isLoading) return;
    final generation = ++_generation;
    final base = current.copyWith(isLoading: true, error: () => null);
    state = base;

    final source = ref.read(primarySourceProvider);
    final result = await source.search(query.withCursor(current.nextCursor));
    if (generation != _generation) return;

    state = result.when(
      ok: (page) {
        final seen = {for (final a in base.items) a.key};
        return base.copyWith(
          items: [
            ...base.items,
            for (final a in page.items)
              if (seen.add(a.key)) a,
          ],
          total: page.total,
          nextCursor: () => page.items.isEmpty ? null : page.nextCursor,
          isLoading: false,
          loadedOnce: true,
        );
      },
      err: (failure) => base.copyWith(
        isLoading: false,
        error: () => failure,
        loadedOnce: true,
      ),
    );
  }

  Future<void> retry() => loadMore();
}

final pagedSearchProvider =
    NotifierProvider.family<PagedSearchController, PagedState, SearchQuery>(
      PagedSearchController.new,
    );
