import 'dart:async';

import 'package:codedbykay_art_explorer/features/search/active_filter_chips.dart';
import 'package:codedbykay_art_explorer/features/search/filter_sheet.dart';
import 'package:codedbykay_art_explorer/features/search/paged_artwork_view.dart';
import 'package:codedbykay_art_explorer/features/search/paged_search.dart';
import 'package:codedbykay_art_explorer/features/search/search_input_parser.dart';
import 'package:codedbykay_art_explorer/features/search/sort_button.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Joins a category query (e.g. "cubism") with extra words and filters typed
/// by the user. Filters the user sets override the category's own.
SearchQuery combineQuery(
  SearchQuery base, {
  required String text,
  required SearchFilters filters,
  SearchSort sort = SearchSort.relevance,
}) {
  final parsed = parseSearchInput(text);
  final extra = mergeParsed(filters, parsed);
  final b = base.filters;
  return SearchQuery(
    text: [base.text, parsed.text].where((t) => t.isNotEmpty).join(' '),
    rows: base.rows,
    sort: sort,
    filters: SearchFilters(
      yearFrom: extra.yearFrom ?? b.yearFrom,
      yearTo: extra.yearTo ?? b.yearTo,
      country: extra.country ?? b.country,
      openLicenseOnly: extra.openLicenseOnly || b.openLicenseOnly,
      creator: b.creator,
      concept: b.concept,
      museum: b.museum,
      colour: b.colour,
    ),
  );
}

/// Results for a topic, century or country that can be narrowed further with
/// extra search words and filters.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({required this.title, required this.query, super.key});

  final String title;
  final SearchQuery query;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _text = '';
  SearchFilters _filters = const SearchFilters();
  SearchSort _sort = SearchSort.relevance;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => setState(() => _text = value.trim()),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    final parsed = parseSearchInput(value);
    setState(() {
      _filters = mergeParsed(_filters, parsed);
      _text = parsed.text;
      _controller.text = parsed.text;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = combineQuery(
      widget.query,
      text: _text,
      filters: _filters,
      sort: _sort,
    );
    final state = ref.watch(pagedSearchProvider(query));
    final controller = ref.read(pagedSearchProvider(query).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          SortButton(
            value: _sort,
            onSelected: (s) => setState(() => _sort = s),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _controller,
                    hintText: context.l10n.searchWithin(widget.title),
                    leading: const Icon(Icons.search),
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: _filters.isActive,
                  label: Text('${_filters.activeCount}'),
                  child: IconButton.filledTonal(
                    tooltip: context.l10n.filters,
                    icon: const Icon(Icons.tune),
                    onPressed: () => showFilterSheet(
                      context,
                      initial: _filters,
                      onApply: (f) => setState(() => _filters = f),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ActiveFilterChips(
            filters: _filters,
            onChanged: (f) => setState(() => _filters = f),
          ),
          Expanded(
            child: PagedArtworkView(
              state: state,
              onLoadMore: controller.loadMore,
              onRetry: controller.retry,
              query: query,
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
          ),
        ],
      ),
    );
  }
}
