import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';

class ReaderSection {
  const ReaderSection({
    required this.heading,
    required this.paragraphs,
    this.attribution,
  });

  final String heading;
  final List<String> paragraphs;
  final String? attribution;
}

/// Readable text assembled from the record and the creator profile.
class ReaderDocument {
  const ReaderDocument({required this.title, required this.sections});

  final String title;
  final List<ReaderSection> sections;

  bool get hasContent => sections.any((s) => s.paragraphs.isNotEmpty);

  /// Plain text for text-to-speech.
  String get spokenText => [
    title,
    for (final s in sections) ...[s.heading, ...s.paragraphs],
  ].join('\n\n');

  static ReaderDocument build({
    required Artwork artwork,
    ArtworkDetail? detail,
    CreatorProfile? creator,
    required AppLocalizations l10n,
    String lang = 'en',
  }) {
    final sections = <ReaderSection>[];

    final facts = <String>[
      if (artwork.creators.isNotEmpty) l10n.factBy(artwork.creators.join(', ')),
      if (artwork.date != null) l10n.factDated(artwork.date!),
      if (detail != null && detail.mediums.isNotEmpty)
        l10n.factMedium(detail.mediums.join(', ')),
      if (detail != null && detail.dimensions.isNotEmpty)
        l10n.factDimensions(detail.dimensions.join(', ')),
      if (detail != null && detail.places.isNotEmpty)
        l10n.factPlace(detail.places.join(', ')),
    ];

    final descriptions = detail?.descriptions ?? const [];
    final paragraphs = <String>[
      for (final d in descriptions)
        if (d.lang == null || d.lang == lang || d.lang == 'en')
          d.text
        else
          '[${d.lang}] ${d.text}',
    ];
    sections.add(
      ReaderSection(
        heading: l10n.aboutThisWork,
        paragraphs: [
          ...facts.isEmpty ? [] : [facts.join(' ')],
          ...paragraphs,
        ],
        attribution: artwork.provider == null
            ? null
            : l10n.descriptionFrom(artwork.provider!),
      ),
    );

    if (creator != null) {
      final intro = [
        creator.name,
        if (creator.lifespan != null) '(${creator.lifespan})',
        if (creator.shortDescription != null) '- ${creator.shortDescription}',
      ].join(' ');
      sections.add(
        ReaderSection(
          heading: l10n.aboutTheArtist,
          paragraphs: [
            intro,
            if (creator.biography != null) creator.biography!,
          ],
          attribution: creator.biography == null
              ? 'Europeana Entity API'
              : 'Wikipedia, Europeana Entity API',
        ),
      );
    }

    if (detail != null && detail.subjects.isNotEmpty) {
      sections.add(
        ReaderSection(
          heading: l10n.subjects,
          paragraphs: [detail.subjects.join(', ')],
        ),
      );
    }

    return ReaderDocument(title: artwork.title, sections: sections);
  }
}
