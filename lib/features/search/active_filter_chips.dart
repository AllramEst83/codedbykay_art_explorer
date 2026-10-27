import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';

/// Removable chips for the active year, country and licence filters.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    required this.filters,
    required this.onChanged,
    super.key,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;

  static String yearLabel(int? from, int? to) {
    if (from != null && to != null) return from == to ? '$from' : '$from–$to';
    if (from != null) return '$from–';
    return '–$to';
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (filters.yearFrom != null || filters.yearTo != null)
        InputChip(
          avatar: const Icon(Icons.event, size: 18),
          label: Text(yearLabel(filters.yearFrom, filters.yearTo)),
          onDeleted: () => onChanged(
            filters.copyWith(yearFrom: () => null, yearTo: () => null),
          ),
        ),
      if (filters.country != null)
        InputChip(
          avatar: const Icon(Icons.public, size: 18),
          label: Text(filters.country!),
          onDeleted: () => onChanged(filters.copyWith(country: () => null)),
        ),
      if (filters.openLicenseOnly)
        InputChip(
          avatar: const Icon(Icons.lock_open, size: 18),
          label: Text(context.l10n.openLicenseOnly),
          onDeleted: () => onChanged(filters.copyWith(openLicenseOnly: false)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(spacing: 8, runSpacing: 4, children: chips),
      ),
    );
  }
}
