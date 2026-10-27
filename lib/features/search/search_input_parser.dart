import 'package:codedbykay_art_explorer/features/search/filter_sheet.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';

/// What a typed query turned out to contain.
typedef ParsedSearch = ({
  String text,
  int? yearFrom,
  int? yearTo,
  String? country,
});

const _countryAliases = {
  'uk': 'United Kingdom',
  'britain': 'United Kingdom',
  'england': 'United Kingdom',
  'holland': 'Netherlands',
};

const _minYear = 1000;

/// Splits free text such as `cubism 1900s france` into the search words
/// (`cubism`) and structured filters (1900-1999, France).
///
/// Recognised: `1888`, `1850-1900`, `1800s` (century), `1850s` (decade),
/// `1800-talet`, `19th century`, and country names from [filterCountries].
ParsedSearch parseSearchInput(String raw, {int? maxYear}) {
  final latest = maxYear ?? DateTime.now().year;
  var text = ' ${raw.trim()} ';
  int? from;
  int? to;
  String? country;

  bool validYear(int y) => y >= _minYear && y <= latest;

  String strip(RegExpMatch m) =>
      '${text.substring(0, m.start)} ${text.substring(m.end)}';

  // Country first so "Netherlands 1600s" works in either order.
  final countryNames = {
    for (final c in filterCountries) c.toLowerCase(): c,
    ..._countryAliases,
  };
  for (final entry in countryNames.entries) {
    final m = RegExp(
      '(?<![\\p{L}\\d])${RegExp.escape(entry.key)}(?![\\p{L}\\d])',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    if (m != null) {
      country = entry.value;
      text = strip(m);
      break;
    }
  }

  // 1850-1900 or 1850–1900
  final range = RegExp(r'(?<!\d)(\d{4})\s*[-–]\s*(\d{4})(?!\d)')
      .firstMatch(text);
  if (range != null) {
    final a = int.parse(range.group(1)!);
    final b = int.parse(range.group(2)!);
    if (validYear(a) && validYear(b)) {
      from = a < b ? a : b;
      to = a < b ? b : a;
      text = strip(range);
    }
  }

  // 19th century
  if (from == null) {
    final m = RegExp(
      r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)\s+century',
      caseSensitive: false,
    ).firstMatch(text);
    if (m != null) {
      final n = int.parse(m.group(1)!);
      if (n >= 11 && n <= (latest ~/ 100) + 1) {
        from = (n - 1) * 100;
        to = n * 100 - 1;
        text = strip(m);
      }
    }
  }

  // 1800s / 1850s / 1800-talet
  if (from == null) {
    final m = RegExp(
      r'(?<!\d)(\d{4})(?:s|-?talet)(?![\p{L}\d])',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      if (validYear(y) && y % 10 == 0) {
        from = y;
        to = y % 100 == 0 ? y + 99 : y + 9;
        text = strip(m);
      }
    }
  }

  // A single year
  if (from == null) {
    final m = RegExp(
      r'(?<![\p{L}\d-])(\d{4})(?![\p{L}\d-])',
      unicode: true,
    ).firstMatch(text);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      if (validYear(y)) {
        from = y;
        to = y;
        text = strip(m);
      }
    }
  }

  return (
    text: text.replaceAll(RegExp(r'\s+'), ' ').trim(),
    yearFrom: from,
    yearTo: to,
    country: country,
  );
}

/// Applies parsed values on top of [base]; parsed values win when present.
SearchFilters mergeParsed(SearchFilters base, ParsedSearch parsed) {
  final hasYear = parsed.yearFrom != null;
  return base.copyWith(
    yearFrom: hasYear ? () => parsed.yearFrom : null,
    yearTo: hasYear ? () => parsed.yearTo : null,
    country: parsed.country != null ? () => parsed.country : null,
  );
}
