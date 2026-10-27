import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/core/widgets/state_views.dart';
import 'package:codedbykay_art_explorer/features/explore/browse.dart';
import 'package:codedbykay_art_explorer/features/explore/explore_data.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every value of one category, with counts.
class BrowseAllScreen extends ConsumerStatefulWidget {
  const BrowseAllScreen({required this.type, super.key});

  final FacetType type;

  @override
  ConsumerState<BrowseAllScreen> createState() => _BrowseAllScreenState();
}

class _BrowseAllScreenState extends ConsumerState<BrowseAllScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final async = ref.watch(facetProvider(type));
    return Scaffold(
      appBar: AppBar(title: Text(type.title(context.l10n))),
      body: async.when(
        data: (result) => result.when(
          ok: (values) => _body(context, values),
          err: (f) => ErrorView(
            failure: f,
            onRetry: () => ref.invalidate(facetProvider(type)),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorView(
          failure: const UnknownFailure(),
          onRetry: () => ref.invalidate(facetProvider(type)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<FacetValue> values) {
    switch (widget.type) {
      case FacetType.period:
        return _Periods(periods: groupPeriods(values));
      case FacetType.colour:
        return _Colours(values: sortColours(values));
      case FacetType.concept:
      case FacetType.museum:
      case FacetType.country:
        final q = _filter.toLowerCase();
        final shown = q.isEmpty
            ? values
            : [
                for (final v in values)
                  if (v.label.toLowerCase().contains(q)) v,
              ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                hintText: context.l10n.filterList,
                leading: const Icon(Icons.filter_list),
                onChanged: (v) => setState(() => _filter = v.trim()),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? EmptyView(
                      icon: Icons.search_off,
                      title: context.l10n.noMatches,
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(shown[i].label),
                        trailing: Text(
                          context.l10n.worksCount(shown[i].count),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () =>
                            openFacetValue(context, widget.type, shown[i]),
                      ),
                    ),
            ),
          ],
        );
    }
  }
}

class _Periods extends StatelessWidget {
  const _Periods({required this.periods});

  final List<Period> periods;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      children: [
        for (final century in periods)
          ExpansionTile(
            title: Text(l10n.decadeLabel('${century.from}')),
            subtitle: Text(l10n.worksCount(century.count)),
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(
                  l10n.allOfPeriod(l10n.decadeLabel('${century.from}')),
                ),
                onTap: () => openPeriod(context, century),
              ),
              for (final decade in century.decades)
                ListTile(
                  title: Text(l10n.decadeLabel('${decade.from}')),
                  trailing: Text(
                    l10n.worksCount(decade.count),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => openPeriod(context, decade),
                ),
            ],
          ),
      ],
    );
  }
}

class _Colours extends StatelessWidget {
  const _Colours({required this.values});

  final List<FacetValue> values;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 72,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
    ),
    itemCount: values.length,
    itemBuilder: (_, i) => ColourSwatch(
      value: values[i],
      size: 64,
      onTap: () => openFacetValue(context, FacetType.colour, values[i]),
    ),
  );
}
