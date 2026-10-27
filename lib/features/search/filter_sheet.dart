import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';

const filterCountries = [
  'Austria',
  'Belgium',
  'Denmark',
  'Finland',
  'France',
  'Germany',
  'Greece',
  'Hungary',
  'Ireland',
  'Italy',
  'Netherlands',
  'Norway',
  'Poland',
  'Portugal',
  'Spain',
  'Sweden',
  'United Kingdom',
];

const _minYear = 1200.0;
final _maxYear = DateTime.now().year.toDouble();

Future<void> showFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
  required ValueChanged<SearchFilters> onApply,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => FilterSheet(initial: initial, onApply: onApply),
);

class FilterSheet extends StatefulWidget {
  const FilterSheet({required this.initial, required this.onApply, super.key});

  final SearchFilters initial;
  final ValueChanged<SearchFilters> onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late SearchFilters _filters = widget.initial;

  RangeValues get _range => RangeValues(
    (_filters.yearFrom ?? _minYear.toInt()).toDouble().clamp(
      _minYear,
      _maxYear,
    ),
    (_filters.yearTo ?? _maxYear.toInt()).toDouble().clamp(_minYear, _maxYear),
  );

  void _setRange(RangeValues v) {
    final from = v.start.round();
    final to = v.end.round();
    setState(
      () => _filters = _filters.copyWith(
        yearFrom: () => from <= _minYear ? null : from,
        yearTo: () => to >= _maxYear ? null : to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = _range;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.filters, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              context.l10n.filterYear(range.start.round(), range.end.round()),
              style: theme.textTheme.titleSmall,
            ),
            RangeSlider(
              values: range,
              min: _minYear,
              max: _maxYear,
              divisions: ((_maxYear - _minYear) / 5).round(),
              labels: RangeLabels(
                '${range.start.round()}',
                '${range.end.round()}',
              ),
              onChanged: _setRange,
            ),
            const SizedBox(height: 8),
            DropdownMenu<String?>(
              initialSelection: _filters.country,
              label: Text(context.l10n.country),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: [
                DropdownMenuEntry(value: null, label: context.l10n.anyCountry),
                for (final c in filterCountries)
                  DropdownMenuEntry(value: c, label: c),
              ],
              onSelected: (c) => setState(
                () => _filters = _filters.copyWith(country: () => c),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.openLicenseOnly),
              subtitle: Text(context.l10n.openLicenseHint),
              value: _filters.openLicenseOnly,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(openLicenseOnly: v),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(
                    () => _filters = SearchFilters(creator: _filters.creator),
                  ),
                  child: Text(context.l10n.reset),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.of(context).pop();
                  },
                  child: Text(context.l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
