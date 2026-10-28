import 'package:codedbykay_art_explorer/core/widgets/art_image.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_sequence.dart';
import 'package:codedbykay_art_explorer/features/bookmarks/bookmarks_controller.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the artwork detail screen. Pass the [sequence] the artwork was
/// picked from to let the screen step to its neighbours.
void openArtwork(
  BuildContext context,
  Artwork artwork, {
  ArtworkSequence? sequence,
}) => context.push(
  artworkLocation(artwork),
  extra: ArtworkOpenArgs(artwork, sequence: sequence),
);

String artworkLocation(Artwork artwork) => Uri(
  path: '/artwork',
  queryParameters: {'source': artwork.sourceId, 'id': artwork.id},
).toString();

String artworkSemanticLabel(Artwork a) =>
    a.creators.isEmpty ? a.title : '${a.title}, by ${a.creators.first}';

class ArtworkCard extends ConsumerWidget {
  const ArtworkCard({
    required this.artwork,
    this.width,
    this.sequence,
    super.key,
  });

  final Artwork artwork;

  /// Used to size the decoded image; null for grid tiles.
  final double? width;

  /// The list this card is shown in, for stepping on the detail screen.
  final ArtworkSequence? sequence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saved = ref.watch(isBookmarkedProvider(artwork.key));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      button: true,
      label: artworkSemanticLabel(artwork),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => openArtwork(context, artwork, sequence: sequence),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'art-${artwork.key}',
                child: ArtImage(
                  url: artwork.thumbnailUrl,
                  memCacheWidth: ((width ?? 220) * dpr).round(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          artwork.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (artwork.creators.isNotEmpty)
                          Text(
                            artwork.creators.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (saved)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    shadows: [const Shadow(blurRadius: 6)],
                    semanticLabel: context.l10n.bookmarked,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
