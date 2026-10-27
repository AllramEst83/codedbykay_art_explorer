import 'package:cached_network_image/cached_network_image.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen pinch-zoom viewer. Tap toggles the chrome (immersive mode).
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({required this.artwork, super.key});

  final Artwork artwork;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  bool _chrome = true;
  bool _useThumbnail = false;

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    SystemChrome.setEnabledSystemUIMode(
      _chrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artwork;
    final url = _useThumbnail ? a.thumbnailUrl : (a.imageUrl ?? a.thumbnailUrl);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _chrome
          ? AppBar(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              title: Text(
                a.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      body: url == null
          ? const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            )
          : Semantics(
              label: context.l10n.zoomableImage(a.title),
              child: PhotoView(
                key: ValueKey(url),
                imageProvider: CachedNetworkImageProvider(url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 6,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                heroAttributes: PhotoViewHeroAttributes(tag: 'art-${a.key}'),
                onTapUp: (_, _, _) => _toggleChrome(),
                loadingBuilder: (_, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, _, _) {
                  // Full-size file may not be an image; fall back to preview.
                  if (!_useThumbnail && a.thumbnailUrl != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _useThumbnail = true);
                    });
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
