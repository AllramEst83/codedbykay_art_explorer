import 'dart:async';

import 'package:codedbykay_art_explorer/features/history/history_controller.dart';
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

typedef SearchInput = ({String text, SearchFilters filters});

/// The submitted (debounced) search text and filters.
class SearchInputController extends Notifier<SearchInput> {
  @override
  SearchInput build() => (text: '', filters: const SearchFilters());

  void setText(String text) => state = (text: text, filters: state.filters);

  void setFilters(SearchFilters filters) =>
      state = (text: state.text, filters: filters);

  void commit(String text, SearchFilters filters) =>
      state = (text: text, filters: filters);
}

/// Incremented when something (e.g. double-tapping the Search tab) asks the
/// search field to take focus.
class SearchFocusRequest extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final searchFocusRequestProvider = NotifierProvider<SearchFocusRequest, int>(
  SearchFocusRequest.new,
);

final searchInputProvider =
    NotifierProvider<SearchInputController, SearchInput>(
      SearchInputController.new,
    );

const searchSuggestions = [
  'Impressionism',
  'Rembrandt',
  'Landscape',
  'Portrait',
  'Still life',
  'Ukiyo-e',
  'Art Nouveau',
  'Baroque',
  'Sculpture',
  'Van Gogh',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchInputProvider).text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => ref.read(searchInputProvider.notifier).setText(value.trim()),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    final raw = value.trim();
    // Years and countries typed into the box become filter chips.
    final parsed = parseSearchInput(raw);
    final input = ref.read(searchInputProvider);
    ref
        .read(searchInputProvider.notifier)
        .commit(parsed.text, mergeParsed(input.filters, parsed));
    _controller.text = parsed.text;
    ref.read(recentSearchesProvider.notifier).add(raw);
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _useSuggestion(String text) {
    _controller.text = text;
    _submit(text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchFocusRequestProvider, (_, _) => _focusNode.requestFocus());
    final input = ref.watch(searchInputProvider);
    // While typing (before submit) the raw text is interpreted the same way.
    final parsed = parseSearchInput(input.text);
    final filters = mergeParsed(input.filters, parsed);
    final sort = ref.watch(sortProvider('search'));
    final hasQuery = parsed.text.isNotEmpty || filters.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.searchTitle),
        actions: [
          SortButton(
            value: sort,
            onSelected: ref.read(sortProvider('search').notifier).choose,
          ),
          Badge(
            isLabelVisible: filters.isActive,
            label: Text('${filters.activeCount}'),
            child: IconButton(
              tooltip: context.l10n.filters,
              icon: const Icon(Icons.tune),
              onPressed: () => showFilterSheet(
                context,
                initial: filters,
                onApply: ref.read(searchInputProvider.notifier).setFilters,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              hintText: context.l10n.searchHint,
              leading: const Icon(Icons.search),
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _submit,
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: context.l10n.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _submit('');
                      _focusNode.requestFocus();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          ActiveFilterChips(
            filters: input.filters,
            onChanged: ref.read(searchInputProvider.notifier).setFilters,
          ),
          Expanded(
            child: hasQuery
                ? _Results(
                    query: SearchQuery(
                      text: parsed.text,
                      filters: filters,
                      sort: sort,
                    ),
                  )
                : _Suggestions(onPick: _useSuggestion),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final SearchQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pagedSearchProvider(query));
    final controller = ref.read(pagedSearchProvider(query).notifier);
    return PagedArtworkView(
      state: state,
      onLoadMore: controller.loadMore,
      onRetry: controller.retry,
      headerSlivers: [
        if (state.loadedOnce && state.total > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                context.l10n.resultsCount(state.total),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.recent,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: ref.read(recentSearchesProvider.notifier).clear,
                child: Text(context.l10n.clear),
              ),
            ],
          ),
          for (final r in recent)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(r),
              onTap: () => onPick(r),
            ),
          const SizedBox(height: 16),
        ],
        Text(context.l10n.trySearching, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in searchSuggestions)
              ActionChip(label: Text(s), onPressed: () => onPick(s)),
          ],
        ),
      ],
    );
  }
}
