import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/features/explore/explore_data.dart';
import 'package:codedbykay_art_explorer/features/explore/explore_screen.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

extension FacetTypeText on FacetType {
  String title(AppLocalizations l) => switch (this) {
    FacetType.concept => l.browseSubjects,
    FacetType.museum => l.browseMuseums,
    FacetType.period => l.browsePeriods,
    FacetType.country => l.browseCountries,
    FacetType.colour => l.browseColours,
  };
}

/// Parses `#RRGGBB`; null when malformed.
Color? parseHexColor(String hex) {
  final m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
  return m == null
      ? null
      : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

/// Greys first (dark to light), then colours around the colour wheel.
List<FacetValue> sortColours(Iterable<FacetValue> values) {
  final keyed = <(FacetValue, double)>[];
  for (final v in values) {
    final c = parseHexColor(v.value);
    if (c == null) continue;
    final hsv = HSVColor.fromColor(c);
    final key = hsv.saturation < 0.12 ? hsv.value : 10 + hsv.hue;
    keyed.add((v, key));
  }
  keyed.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final (v, _) in keyed) v];
}

String formatCount(BuildContext context, int count) {
  final s = count.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

void openFacetValue(BuildContext context, FacetType type, FacetValue v) {
  switch (type) {
    case FacetType.concept:
      openCollection(context, title: v.label, concept: v.value);
    case FacetType.museum:
      openCollection(context, title: v.label, museum: v.value);
    case FacetType.country:
      openCollection(context, title: v.label, country: v.value);
    case FacetType.colour:
      openCollection(
        context,
        title: context.l10n.colourTitle(v.value),
        colour: v.value,
      );
    case FacetType.period:
      break;
  }
}

void openPeriod(BuildContext context, Period p) => openCollection(
  context,
  title: context.l10n.decadeLabel('${p.from}'),
  yearFrom: p.from,
  yearTo: p.to,
);

/// A live "browse by" section on the Explore tab.
class BrowseSection extends ConsumerWidget {
  const BrowseSection({required this.type, super.key});

  final FacetType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(facetProvider(type));
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    type.title(context.l10n),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/browse?type=${type.name}'),
                  child: Text(context.l10n.seeAll),
                ),
              ],
            ),
          ),
          SizedBox(
            height: type == FacetType.colour ? 52 : 44,
            child: async.when(
              data: (result) => result.when(
                ok: (values) => _Row(type: type, values: values),
                err: (f) => _Retry(
                  message: failureText(context.l10n, f),
                  onRetry: () => ref.invalidate(facetProvider(type)),
                ),
              ),
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 120, child: LinearProgressIndicator()),
                ),
              ),
              error: (_, _) => _Retry(
                message: context.l10n.errUnknown,
                onRetry: () => ref.invalidate(facetProvider(type)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.type, required this.values});

  final FacetType type;
  final List<FacetValue> values;

  @override
  Widget build(BuildContext context) {
    if (type == FacetType.colour) {
      final colours = sortColours(values.take(30));
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: colours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ColourSwatch(
          value: colours[i],
          onTap: () => openFacetValue(context, type, colours[i]),
        ),
      );
    }

    if (type == FacetType.period) {
      final periods = groupPeriods(values)
          .where((p) => p.from >= 1200)
          .toList();
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(context.l10n.decadeLabel('${periods[i].from}')),
          onPressed: () => openPeriod(context, periods[i]),
        ),
      );
    }

    final top = values.take(14).toList();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: top.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ActionChip(
        label: Text(top[i].label),
        onPressed: () => openFacetValue(context, type, top[i]),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}

class ColourSwatch extends StatelessWidget {
  const ColourSwatch({
    required this.value,
    required this.onTap,
    this.size = 44,
    super.key,
  });

  final FacetValue value;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(value.value) ?? Colors.grey;
    return Semantics(
      button: true,
      label: context.l10n.colourTitle(value.value),
      excludeSemantics: true,
      child: Tooltip(
        message: value.value,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
