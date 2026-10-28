import 'package:codedbykay_art_explorer/sources/art_source.dart';

/// The list an artwork was opened from, so the detail screen can step to its
/// neighbours. Paged results are read live (and keep loading) via [query].
class ArtworkSequence {
  const ArtworkSequence.items(this.items) : query = null;
  const ArtworkSequence.paged(SearchQuery this.query) : items = const [];

  final List<Artwork> items;
  final SearchQuery? query;
}

/// Route extra for the artwork screen. [direction] is 1 or -1 when arriving
/// by stepping to the next or previous artwork, 0 otherwise.
class ArtworkOpenArgs {
  const ArtworkOpenArgs(this.artwork, {this.sequence, this.direction = 0});

  final Artwork artwork;
  final ArtworkSequence? sequence;
  final int direction;
}
