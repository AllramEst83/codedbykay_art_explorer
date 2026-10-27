import 'dart:math';

import 'package:codedbykay_art_explorer/sources/art_source.dart';

/// A span of years with the number of works in it.
class Period {
  const Period({
    required this.from,
    required this.to,
    required this.count,
    this.decades = const [],
  });

  final int from;
  final int to;
  final int count;

  /// Decades inside a century, oldest first (empty for a decade).
  final List<Period> decades;

  /// The first year, e.g. 1800 for "1800s".
  int get startYear => from;
}

/// Groups per-year counts (from the YEAR facet) into centuries and decades.
/// Years outside [minYear]..[maxYear] are ignored as unreliable metadata.
List<Period> groupPeriods(
  Iterable<FacetValue> years, {
  int minYear = 1000,
  int? maxYear,
}) {
  final latest = maxYear ?? DateTime.now().year;
  final decadeCounts = <int, int>{};
  for (final v in years) {
    final y = int.tryParse(v.value);
    if (y == null || y < minYear || y > latest) continue;
    final decade = y - y % 10;
    decadeCounts[decade] = (decadeCounts[decade] ?? 0) + v.count;
  }
  final centuryDecades = <int, List<Period>>{};
  for (final entry in decadeCounts.entries) {
    final century = entry.key - entry.key % 100;
    centuryDecades
        .putIfAbsent(century, () => [])
        .add(Period(from: entry.key, to: entry.key + 9, count: entry.value));
  }
  final centuries = [
    for (final e in centuryDecades.entries)
      Period(
        from: e.key,
        to: e.key + 99,
        count: e.value.fold(0, (sum, d) => sum + d.count),
        decades: e.value..sort((a, b) => a.from.compareTo(b.from)),
      ),
  ]..sort((a, b) => a.from.compareTo(b.from));
  return centuries;
}

/// Deterministic daily index so "Artwork of the day" is stable for a date.
int dayOfYearSeed(DateTime date) =>
    date.year * 1000 + date.difference(DateTime(date.year)).inDays;

/// A start offset for a day-stable (or random) pick, kept inside the number
/// of works a subject actually has.
int pickOffset(int seed, int count, {int cap = 300}) =>
    1 + seed % max(1, min(count - 12, cap));
