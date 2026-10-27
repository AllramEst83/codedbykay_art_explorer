import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies one artwork across sources.
typedef ArtworkRef = ({String source, String id});

final artworkDetailProvider =
    FutureProvider.family<Result<ArtworkDetail>, ArtworkRef>(
      (ref, key) => ref.watch(artSourceProvider(key.source)).getArtwork(key.id),
    );

final creatorProvider = FutureProvider.family<Result<CreatorProfile>, String>(
  (ref, name) => ref.watch(primarySourceProvider).getCreator(name),
);
