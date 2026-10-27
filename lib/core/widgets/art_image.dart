import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with a placeholder and an error fallback.
class ArtImage extends StatelessWidget {
  const ArtImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: scheme.surfaceContainerHighest);
    final broken = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: scheme.outline),
      ),
    );
    final u = url;
    if (u == null || u.isEmpty) return broken;
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => broken,
    );
  }
}
