import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension SearchSortText on SearchSort {
  String label(AppLocalizations l) => switch (this) {
    SearchSort.relevance => l.sortRelevance,
    SearchSort.mostComplete => l.sortMostComplete,
    SearchSort.recentlyAdded => l.sortRecentlyAdded,
  };
}

/// The chosen sort order for one results page, keyed by a scope string.
class SortController extends Notifier<SearchSort> {
  SortController(this.scope);

  final String scope;

  @override
  SearchSort build() => SearchSort.relevance;

  void choose(SearchSort sort) => state = sort;
}

final sortProvider =
    NotifierProvider.family<SortController, SearchSort, String>(
      SortController.new,
    );

/// App bar action that lets the user pick a [SearchSort].
class SortButton extends StatelessWidget {
  const SortButton({required this.value, required this.onSelected, super.key});

  final SearchSort value;
  final ValueChanged<SearchSort> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<SearchSort>(
    tooltip: context.l10n.sort,
    icon: Badge(
      isLabelVisible: value != SearchSort.relevance,
      smallSize: 8,
      child: const Icon(Icons.sort),
    ),
    initialValue: value,
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final s in SearchSort.values)
        CheckedPopupMenuItem(
          value: s,
          checked: s == value,
          child: Text(s.label(context.l10n)),
        ),
    ],
  );
}
