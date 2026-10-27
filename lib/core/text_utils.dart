/// Picks the best-language values from an API language map such as
/// `{"en": ["Title"], "def": ["Titel"]}`.
List<String> pickLocalized(Object? map, {String lang = 'en'}) {
  if (map is! Map<String, dynamic>) return const [];
  for (final key in [lang, 'en', 'def']) {
    final values = _strings(map[key]);
    if (values.isNotEmpty) return values;
  }
  for (final value in map.values) {
    final values = _strings(value);
    if (values.isNotEmpty) return values;
  }
  return const [];
}

List<String> _strings(Object? value) => switch (value) {
  final String s when s.trim().isNotEmpty => [s.trim()],
  final List<dynamic> list => [
    for (final e in list)
      if (e is String && e.trim().isNotEmpty) e.trim(),
  ],
  _ => const [],
};

/// Converts "Monet, Claude (1840-1926) (Künstler)" to "Claude Monet".
String cleanCreatorName(String raw) {
  var name = raw.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  final parts = name.split(',');
  if (parts.length == 2 && parts.every((p) => p.trim().isNotEmpty)) {
    name = '${parts[1].trim()} ${parts[0].trim()}';
  }
  return name;
}

bool isAnonymousCreator(String name) {
  final n = name.toLowerCase();
  return n.isEmpty ||
      n.contains('unknown') ||
      n.contains('anonym') ||
      n.contains('onbekend') ||
      n.contains('unbekannt');
}

/// Removes HTML tags and collapses whitespace.
String stripHtml(String input) => input
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Turns a rights URI into a short human label.
String rightsLabel(String? uri) {
  if (uri == null || uri.isEmpty) return 'Rights not stated';
  if (uri.contains('publicdomain/mark')) return 'Public Domain';
  if (uri.contains('publicdomain/zero')) return 'CC0';
  final cc = RegExp(r'licenses/([a-z\-]+)/([\d.]+)').firstMatch(uri);
  if (cc != null) return 'CC ${cc.group(1)!.toUpperCase()} ${cc.group(2)}';
  if (uri.contains('rightsstatements.org/vocab/InC')) return 'In copyright';
  if (uri.contains('rightsstatements.org/vocab/NoC')) return 'No copyright';
  if (uri.contains('rightsstatements.org/vocab/CNE')) {
    return 'Copyright not evaluated';
  }
  if (uri.contains('rightsstatements.org/vocab/UND')) {
    return 'Rights undetermined';
  }
  return 'See source';
}
